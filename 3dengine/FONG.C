/*
北北北北北北北北北北北北北北北北北北北北北北北北北北北北
北北                                                北北
北北          3D Engine source code                 北北
北北                                                北北
北北          for Watcom C 10.6                     北北
北北                                                北北
北北          (c) Antti Virtanen                    北北
北北          Last modified 7.3.1998                北北
膊膊          all rights reserved                   膊膊
北北                                                北北
北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*/

/*
    Known bugs:
        -Timing is taken from 18.2/sec clock -> not accurate
        
    Features to add:
        -support for texture mapping, flatshading, and gouraud shading
        -zbuffering, instead of face sort routine
        -real loading for 3ds files
        -camera movement
        -polygon clipping
        -16bit/24bit modes - VESA support
*/

#include <stdlib.h>
#include <conio.h>
#include <stdio.h>
#include <dos.h>
#include <math.h>
#include <string.h>
#include "ppoly.h"          // Includes phong polygon drawing routines
#include "lmath.h"          // Matrix / vector operations
#include "lvideo.h"
#include <time.h>

void ppolygon(int x1,int y1,int u1,int v1,int x2,int y2,int u2,int v2,
              int x3, int y3, int u3, int v3);

void putpixel(long x, long y, long color, long offset);
void setcolor(int color, int red, int green, int blue);
void waitretrace(void);
void initall(void);
void rotate3d(void);
void sortfaces(void);
void drawfaces(void);
void putpolygon(int x1, int y1, int x2, int y2, int x3, int y3, int col);
int  random(int range);
void copyvirtual(void);
void clearvirtual(void);
void copy(long source, long dest, long amount);
void initobject(long object, char *objectfile, long divisor, long n_vertices, long n_faces);
void calcnormals(long object);

typedef struct  objectstructure {
        long    nro_vertices;
        long    nro_faces;
        long    startingface;
        long    startingvertex;
        char    *fongmap;                 /* (da legendary) material (-morph) */
} objectstruct;

#define nro_objects 1
#define cliplimit 0
#define total_vertices 168                      /* define stuff */
#define total_faces 336      // arvot toorus.asc -tiedostolle
#define ambient 100                            /* 0-127 */

objectstruct    objects[nro_objects];     /* array for all objects */
matrix   origmatrix;                      /* original object matrix */
matrix   tempmatrix;                      /* temp_matrix */
matrix   rmatrix;                         /* rotation matrix for object */
matrix   omatrix;                         /* final object matrix */

char    *virtual;
char    *phongmap;
matrix        vmatrix;             /* final matrix   */
matrix        cmatrix;             /* camera matrix */

signed  long    vertices[total_vertices][3];    /* 3d coordinates of polygon corners */
signed  long    vnormals[total_vertices][3];    /* vertex normals for phong shading */
signed  long    fnormals[total_faces][3];       /* face normals */
signed  long    faces[total_faces][4];          /* which points belong to which polygon */
                                                /* 4th number is distance for sortloop */
signed  long    vpnormals[total_vertices][3];   /* rotated vertex normals */
signed  long    sortf[total_faces];             /* order in which to draw polygons */
signed  long    sorting[65536*2];               /* used by sort routine */
signed  long    activefaces;                    /* number of faces to draw in current frame */
signed  long    afaces[total_faces];            /* which faces are active in current frame */
signed  long    drawf[total_vertices][3];       /* projected vertices for drawloop */

signed  long    frames;                         /* frame counter */
clock_t     starttime, endtime, sorttime, drawtime, copytime, rotatetime,
            ts,te;                              /* used to calculate the performance */
double  pasko,porsenti;                         // also for timing calculations

void main(void)
{
int     i;
        for (i=0; i<65536; i++)
                sorting[i]=0;

    initmode(0x13);
    initall();
    for (i=0; i<16; i++)
        origmatrix[i]=0;
    origmatrix[0]=256;         /* identity matrix */
    origmatrix[5]=256;
    origmatrix[10]=256;
    origmatrix[15]=256;
    matrix_make(rmatrix,origmatrix);

    frames=0;

    sorttime=0;
    copytime=0;
    drawtime=0;
    rotatetime=0;
    clearvirtual();
    starttime=clock();

    /* main loop */
    while ((!kbhit()) && (frames<511))  // Max. 512 frames
    {
        ts=clock();
        creatematrix(omatrix, origmatrix, frames*3);  // Make the matrix for rotations
        rotate3d();                      // Rotate and transform vertices and vertice normals
        backfaceculling();               // Check which vertices are necessary to draw
        te=clock();
        rotatetime=rotatetime+(te-ts);
        ts=te;
        sortfaces();                     // Sort the faces
        te=clock();
        sorttime=sorttime+(te-ts);
        ts=te;
        drawfaces();                     // Draw the polygons (faces)
        te=clock();
        drawtime=drawtime+(te-ts);
        ts=te;
        copyvirtual();                   // Copy virtual screen to vga memory
        clearvirtual();                  // Clear virtual screen buffer for next frame
        te=clock();
        copytime=copytime+(te-ts);
        ts=te;
        frames++;
    }
    endtime=clock();

   initmode(3);                          // 80x25 text mode, normal dos mode

// 膊膊 show the timing information to user

   porsenti=(double)(endtime-starttime)/100;
   printf("Frames drawn:    %i\n\n",frames);
   printf("time taken by the rendering engine:\n");
   printf("drawing polygons                 : %f",drawtime/porsenti);
   printf("\ncopying/clearing virtual screen  : %f",copytime/porsenti);
   printf("\nrotating/projecting vertices     : %f",rotatetime/porsenti);
   printf("\nsorting faces                    : %f",sorttime/porsenti);
   pasko=(double)(endtime-starttime) / (double)(CLOCKS_PER_SEC);
   pasko=(double)(frames)/pasko;
   printf("\naverage fps %f",pasko);
}

/*
   Does the backfaceculling.
   If the face is out of cliplimit - ie. not visible, or it's facing
   away from the wather, it does not need to be drawn.
   One bug still remains: If ANY of the z-coordinates is smaller than the
   cliplimit, the face should be drawn
*/
void backfaceculling(void) {
int i,j;
    activefaces=0;
    for (i=0; i<total_faces; i++)
           if ((drawf[faces[i][0]][2]>cliplimit) && (drawf[faces[i][1]][2]>cliplimit)
           && (drawf[faces[i][2]][2]>cliplimit) && ((vpnormals[faces[i][0]][2]>0)
           || (vpnormals[faces[i][1]][2]>0) || (vpnormals[faces[i][2]][2]>0)))
           {
                afaces[activefaces]=i;
                activefaces++;
           }
}


/*
    this rotates vertices (rmatrix), and vertex normals (vmatrix),
    and projects them
*/
void rotate3d(void) {
signed long x1,y1,z1,x2,y2,z2,k,kk,a;
    for (a=0; a<nro_objects; a++) {
        for (kk=0; kk<objects[a].nro_vertices; kk++)
        {
            k=kk+objects[a].startingvertex;
          /* matrix way. kewl way. 9 muls. rulz. */
            x1=vertices[k][0]; y1=vertices[k][1]; z1=vertices[k][2];
            x2=omatrix[12]+((x1*omatrix[0]+y1*omatrix[4]+z1*omatrix[8]) >> 8);
            y2=omatrix[13]+((x1*omatrix[1]+y1*omatrix[5]+z1*omatrix[9]) >> 8);
            z2=omatrix[14]+((x1*omatrix[2]+y1*omatrix[6]+z1*omatrix[10]) >> 8);
            if (z2==0) z2++;    // avoid division by zero
          /* projise */
            drawf[k][0]=160+((x2 << 8) / (-z2+256));
            drawf[k][1]=100-((y2 << 8) / (-z2+256));
            drawf[k][2]=z2;

          /* rotate vertex normals */

            x1=vnormals[k][0]; y1=vnormals[k][1]; z1=vnormals[k][2];
            vpnormals[k][0]=(x1*omatrix[0]+y1*omatrix[4]+z1*omatrix[8]) >> 8;
            vpnormals[k][1]=(x1*omatrix[1]+y1*omatrix[5]+z1*omatrix[9]) >> 8;
            vpnormals[k][2]=(x1*omatrix[2]+y1*omatrix[6]+z1*omatrix[10]) >> 8;

      }
    }
}


/*
    Sorts the faces. Very fast algorithm.
    Adopted from Imphobia disk magazine.
*/
void sortfaces(void)
{
signed  long    k,x,min,max,i;
    x=0;
    min=0xffff;
    max=0;
    for (k=0; k<activefaces; k++) {
      /* calculate (fake-)distance from viewpoint */
        i=32000+drawf[faces[afaces[k]][0]][2]+
                 drawf[faces[afaces[k]][1]][2]+
                 drawf[faces[afaces[k]][2]][2];
        faces[afaces[k]][3] = i;
        if (i>max) max=i;
        else if (i<min) min=i;
        sorting[i]++;
    }
    for (k=min; k<max+1; k++)
        if (sorting[k]>0) {
            for (i=0; i<activefaces; i++)
                if (faces[afaces[i]][3]==k) {
                    sortf[x]=afaces[i];
                    x++;
                }
            sorting[k]=0;
        }
}


/*
Draw the faces to virtual screen buffer
*/
void drawfaces(void)
{
signed  long    k,l;
    for (k=0; k<activefaces; k++) {
        l = sortf[k];
        ppolygon(drawf[faces[l][0]][0],drawf[faces[l][0]][1],
                vpnormals[faces[l][0]][0],vpnormals[faces[l][0]][1],
                drawf[faces[l][1]][0],drawf[faces[l][1]][1],
                vpnormals[faces[l][1]][0],vpnormals[faces[l][1]][1],
                drawf[faces[l][2]][0],drawf[faces[l][2]][1],
                vpnormals[faces[l][2]][0],vpnormals[faces[l][2]][1]);
    }
}

/*
    Loads 3D Studio .ASC file from the disk.
    Assumes it to be little "formatted" however.
*/
void initobject(long object, char *objectfile, long divisor,long n_vertices, long n_faces)
{
FILE    *xfile;
char    rivi[80];
char    temp[80];
double  tempe;
long    ii,kk,ll,i,k,l;
char    plats;

    if (object != 0) {
            objects[object].startingface=objects[object-1].nro_faces;
            objects[object].startingvertex=objects[object-1].nro_vertices;
        }
    if (object == 0) {
            objects[object].startingface=0;
            objects[object].startingvertex=0;
        }
    objects[object].nro_faces=n_faces;
    objects[object].nro_vertices=n_vertices;

    xfile = fopen(objectfile,"rt"); /* read text */
    /* read vertices */
    fgets(rivi,80,xfile);   /* skip first line */
    for (i=0; i<n_vertices; i++) {
        while ((fgets(rivi,80,xfile)==NULL) || (rivi[0]!='V')) {
            /* just a loop for skipping stupid useless lines.. */
        }
            k=10;
            while (rivi[k] != 'X') k++;
            k++;
            k++;
            plats=k;
            for (l=0; l<80; l++) temp[l]=' ';
            while (rivi[k] != 'Y') {
                temp[k-plats] = rivi[k];
                k++;
            }
            tempe=atof(temp);
            ii=i;
            vertices[i][0]=(signed long)(tempe/divisor);
            k++;
            k++;
            plats=k;
            for (l=0; l<80; l++) temp[l]=' ';
            while (rivi[k] != 'Z') {
                temp[k-plats] = rivi[k];
                k++;
            }
            tempe=atof(temp);
            vertices[i][1]=(signed long)(tempe/divisor);
            for (l=0; l<80; l++) temp[l]=' ';
            for (l=k+2; l<80; l++) temp[l-k-2]=rivi[l];
            tempe=atof(temp);
            vertices[i][2]=(signed long)(tempe/divisor);
    }

    /* read faces */
    for (i=0; i<n_faces; i++) {
        while ((fgets(rivi,80,xfile)==NULL) || (rivi[0]!='F')) {
            /* just a loop for skipping stupid useless lines.. */
        }
            k=5;
            while (rivi[k] != 'A') k++;
            k=k+2;
            plats=k;
            for (l=0; l<80; l++) temp[l]=' ';
            while (rivi[k] != 'B') {
                temp[k-plats] = rivi[k];
                k++;
            }
            faces[i][0]=atol(temp);
            k=k+2;
            plats=k;
            for (l=0; l<80; l++) temp[l]=' ';
            while (rivi[k] != 'C') {
                temp[k-plats] = rivi[k];
                k++;
            }
            faces[i][1]=atol(temp);
            for (l=0; l<80; l++) temp[l]=' ';
            k=k+2;
            plats=k;
            while ((rivi[k] > '0'-1) && (rivi[k] < '9'+1)) {
                temp[k-plats] = rivi[k];
                k++;
            }
            faces[i][2]=atol(temp);
    }
}

/*

    calculate vertex "normals" for each face
    vertex "normal"  = average of the face normals touching the vertex

*/

void calcnormals(long object)
{
signed  long    ll,l,i,ii,x,y,z,xx,yy,zz;
double          relx,rely,relz,nf,vl;
    /* calculate face normals */
    for (ll=0; ll<objects[object].nro_faces; ll++) {
        l=ll+objects[object].startingface;
        z = vertices[faces[l][1]][2]-vertices[faces[l][0]][2];
        y = vertices[faces[l][1]][1]-vertices[faces[l][0]][1];
        x = vertices[faces[l][1]][0]-vertices[faces[l][0]][0];
        zz = vertices[faces[l][2]][2]-vertices[faces[l][0]][2];
        yy = vertices[faces[l][2]][1]-vertices[faces[l][0]][1];
        xx = vertices[faces[l][2]][0]-vertices[faces[l][0]][0];
        fnormals[l][0]=y*zz-yy*z;
        fnormals[l][1]=z*xx-zz*x;
        fnormals[l][2]=x*yy-xx*y;
    }
    /* calculate vertex normals */
    for (ll=0; ll<objects[object].nro_vertices; ll++) {
        nf=0;
        relx=0;
        rely=0;
        relz=0;
        l = ll+objects[object].startingvertex;
        for (ii=0; ii<objects[object].nro_faces; ii++) {
            i=ii+objects[object].startingface;
            if ((faces[i][0]==l) || (faces[i][1]==l) || (faces[i][2]==l)) {
                relx=relx+fnormals[i][0];
                rely=rely+fnormals[i][1];
                relz=relz+fnormals[i][2];
                nf++;
            }
        }
        if (nf != 0) {
            relx=relx/nf; /* take average of the face normals of faces */
            rely=rely/nf; /* touching the vertex */
            relz=relz/nf;
            vl=sqrt(relx*relx+rely*rely+relz*relz);
            if (vl!=0) {
              vnormals[l][0]=(signed long)(relx*ambient/vl);
              vnormals[l][1]=(signed long)(rely*ambient/vl);
              vnormals[l][2]=(signed long)(relz*ambient/vl);
            }
            else {
                vnormals[l][0]=0;
                vnormals[l][1]=0;
                vnormals[l][2]=0;
            }
        }
    }
}

void initall(void)
{
  int               i,j;
  char              *homo;
  FILE              *piccyfile;

  /* get some memory */
    virtual=(char *)malloc(64004);
    phongmap=(char *)malloc(65536);

  /* load phongmaps */
    piccyfile=fopen("map.scx","rb");        // .RIX file format
    fread(&phongmap[0],778,1,piccyfile);
    outp(0x3c8,0);
    for (i=10; i<779; i++)
       outp(0x3c9,phongmap[i]);
    fread(&phongmap[0],65535,1,piccyfile);
    fclose(piccyfile);

    homo="toorus.asc";
    initobject(0,homo,2,168,336);

    calcnormals(0);
    objects[0].fongmap=phongmap;    /* select material */

    csinlookup(255,128);
}

void ppolygon(int x1,int y1,int u1,int v1,int x2,int y2,int u2,int v2,
              int x3, int y3, int u3, int v3)
{
signed long  rx1,ry1,ru1,rv1,rx2,ry2,ru2,rv2,rx3,ry3,ru3,rv3;
signed long  i,h,k,ao,bo,ax,bx,cx,au,bu,cu,av,bv,cv,
             a,b,c,aa,bb,cc,aaa,bbb,ccc;
    /* sort coordinates (ry1=smallest y, ry3= biggest) */
    ry3=y3;    rx3=x3;      ru3=u3;     rv3=v3;
    if (y2<y1) {
      ry1=y2;  rx1=x2;      ru1=u2;     rv1=v2;
      ry2=y1;  rx2=x1;      ru2=u1;     rv2=v1;
	}
    else {
        ry1=y1;    rx1=x1;      ru1=u1;     rv1=v1;
        rx2=x2;    ry2=y2;      ru2=u2;     rv2=v2;
    };  
	if (ry3<ry1) {
      ry3=ry1; rx3=rx1;     ru3=ru1;    rv3=rv1;
      ry1=y3;  rx1=x3;      ru1=u3;     rv1=v3;
	}
	if (ry3<ry2) {
      a=ry2;   ry2=ry3;     ry3=a;
      a=rx2;   rx2=rx3;     rx3=a;
      a=ru2;   ru2=ru3;     ru3=a;
      a=rv2;   rv2=rv3;     rv3=a;
    }   
    ru1=ru1+128;    ru2=ru2+128;    ru3=ru3+128;
    rv1=rv1+128;    rv2=rv2+128;    rv3=rv3+128;

    if (ry3==ry1) return; /* it the polygon is only one pixel, then exit ... */
    if (ry1>200) return; /* if the first corner is out */
    if (ry3<0) return;

    /* calculate x and u & v interpolation counters for each edge */
    k=ry3-ry1;
    b  = ((rx3-rx1) << 8 ) / k;
    bb = ((ru3-ru1) << 8 ) / k;
    bbb= ((rv3-rv1) << 8 ) / k;
    ax = rx1 << 8;    au = ru1 << 8;     av = rv1 << 8;
    bx = ax;          bu = au;           bv = av; /* these handle the longest edge */
    cx = rx2 << 8;    cu = ru2 << 8;     cv = rv2 << 8;
    k=ry2-ry1;
    if (k==0) k++;
    a  = ((rx2-rx1) << 8 ) / k;
    aa = ((ru2-ru1) << 8 ) / k;
    aaa= ((rv2-rv1) << 8 ) / k;
    k=ry3-ry2;
    if (k==0) k++;
    c  = ((rx3-rx2) << 8 ) / k;
    cc = ((ru3-ru2) << 8 ) / k;
    ccc= ((rv3-rv2) << 8 ) / k;

    /* now interpolate edges, and draw the polygon */
bo=FP_OFF(virtual);
ao=FP_OFF(phongmap);
    h = ry1*320+bo;
    if (ry2>199) ry2=199;
    if (ry3>199) ry3=199;
    for (i=ry1; i<ry2; i++) {
        if (h>-1+bo) {
            phonginterpola(au,bu,bv,av,bx,ax,ao,h);
        }
        ax=ax+a;        au=au+aa;         av=av+aaa;
        bv=bv+bbb;      bu=bu+bb;         bx=bx+b;
        h=h+320;
    }
    for (i=ry2; i<ry3; i++) {
        if (h>-1+bo)  {
            phonginterpola(bu,cu,cv,bv,cx,bx,ao,h);
        }
        bx=bx+b;        bu=bu+bb;         bv=bv+bbb;
        cu=cu+cc;       cv=cv+ccc;        cx=cx+c;
        h=h+320;
	}
}

void copyvirtual(void) {
long    kop;
    kop=FP_OFF(virtual);
    copy(kop,0xa0000,16000);
}


#pragma aux copy  = \
"cld" \
"rep movsd" \
parm [esi] [edi] [ecx];

void clearvirtual(void) {
    _fmemset(virtual,0,64000);
}

