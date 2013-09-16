cseg    segment
        assume cs:cseg, ds:cseg
        org 100h

start:
   push cs
   push cs
   pop  ds
   pop  es
   mov  si,offset packed_data
   mov  di,0f000h-0ff0h
   mov  cx,packed_size
   cld
   rep  movsb 
   mov  di,0f000h
   mov  cx,30
   rep  movsb
   db   0e9h,0e4h,0eeh  ;jmp f000

packed_data label byte
include shadeb.raw
packed_end  label byte
packed_size equ offset packed_end-offset packed_data

include unpack.cod      ;include unpacking code - it can't be assembled here

cseg    ends
        end start
        end
