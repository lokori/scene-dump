#ifndef _LVIDEO_H_
#define _LVIDEO_H_

#ifdef __cplusplus
extern "C" {
#endif

void    putpixel(long xx, long yy, long color, long virtual);
void    initmode(int mode);
void    setcolor(int color, int red, int green, int blue);
void    waitretrace(void);

#ifdef __cplusplus
}                                                            
#endif                                                       
#endif

