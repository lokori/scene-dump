#include <conio.h>
#include "lvideo.h"

void    imode(int mode);
void    ppixel(long y, long x, long c, long v);

void    putpixel(long xx, long yy, long color, long virtual)
{
    ppixel(xx,yy,color,virtual);
}

/* pragmoissa tulee joskus ennen parm -lausetta kentt„ modify[xxx], johon
laitetaan kaikki rekisterit, joiden arvo muuttuu rutiinissa, ja joita ei
mainita parm-kent„ss„ */

#pragma aux ppixel =          /* eax == y, ebx == x, edx == color, edi== virtual screen offset */ \
"shl eax,6"                     /* eax = y * 64                  */        \
"lea eax,[eax*4+eax]"           /* eax = y * 64 + y * 256 =y*320 */        \
"add edi,eax"                   \
"mov BYTE PTR [edi + ebx], dl"  \
parm [ebx] [eax] [edx] [edi];

void    initmode(int    mode) {
    imode(mode);
}

#pragma aux imode =  /* ax == mode */                \
"int 0x10"  /* set mode */                              \
parm [ax];

void setcolor(int color, int red, int green, int blue)
{
  outp(0x3c8,color);
  outp(0x3c9,red);
  outp(0x3c9,green);
  outp(0x3c9,blue);
}

// Wait for vertical retrace signal, from VGA
void waitretrace(void)
{
int h;
  h=1;
  while((h & 8)==8)
    h=inp(0x3da);
  h=1;
  while((h & 8)!=8)
    h=inp(0x3da);
}
