#ifndef _LMATH_H_
#define _LMATH_H_

#ifdef __cplusplus
extern "C" {
#endif

#define PI 3.1415926535897932385
typedef signed long matrix[16]; /* type define 4x4 matrix, as 16 continuos numbers */

void            matrix_make(matrix dest, matrix source);
void            matrixmul(matrix dest, matrix a, matrix b);
void            creatematrix(matrix dest, matrix imatrix, signed long frame);
void            csinlookup(signed long multiplier, signed long divisor);

c                                             
#endif

