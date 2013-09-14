#include <math.h>
#include "lmath.h"

signed  long    cosi[1256];                    /* cosine & sine look-up table */
signed  long    sini[1256];

void    csinlookup(signed long multiplier, signed long divisor) {
long    i;
    /* sines and cosines */
    for (i=0; i<1256; i++)
    {
      sini[i]=(signed long)(sin((double)i/divisor*PI)*multiplier);
      cosi[i]=(signed long)(cos((double)i/divisor*PI)*multiplier);
    }
}

void    matrix_make(matrix dest, matrix source) {
int x;
    for (x=0;x<16; x++)
      dest[x]=source[x];
}


/*
    Calculates dest=a*b, in which dest, a and b are 4x4 matrices as
    defined at start. Note that the result depends on the order of
    a and b.
*/

void    matrixmul(matrix dest, matrix a, matrix b) {
int x,y,z,tm;
    for(y=0;y<4;y++)
        for(x=0;x<4;x++)
            {
            tm=x+y*4;
            dest[tm]=0;
            for(z=0;z<4;z++)
                dest[tm]=dest[tm]+a[y*4+z]*b[z*4+x];
            dest[tm]=dest[tm] >> 8;
            }

}

/*
    Used to create the rotation matrix. Matrix could be taken from for
    example .DXF files directly (3D Studio animations include matrix
    for each frame!
*/
void creatematrix(matrix    dest, matrix    imatrix, signed long frame) {
matrix  tmatrix;
        // create xy-axis rotation matrix
        matrix_make(tmatrix,imatrix);

        tmatrix[0]=cosi[frame];        // y-angle
        tmatrix[2]=-sini[frame];       // ya
        tmatrix[4]=sini[frame]*sini[frame] >> 8;   // ya*xa
        tmatrix[5]=cosi[frame];    // xa
        tmatrix[6]=sini[frame]*cosi[frame] >> 8;   //sx*cy
        tmatrix[8]=cosi[frame]*sini[frame] >> 8; // cx*sy
        tmatrix[9]=-sini[frame];   // -sx
        tmatrix[10]=cosi[frame]*cosi[frame] >> 8;  //cx*cy

        matrixmul(dest,imatrix,tmatrix);
        dest[14]=140;
}

