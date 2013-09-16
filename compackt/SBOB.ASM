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
   jmp  unpack

packed_data label byte
include shadeb.raw
packed_end  label byte
packed_size equ offset packed_end-offset packed_data


org 0f000h
unpack:
  mov   si,0f000h-0ff0h
  mov   di,0100h
  @do_unpack:
  lodsb
  cmp   al,024h ;packed block
  jne   @not_packed
  lodsb                 ;take length
  mov cl,al             ;to cl
  lodsb                 ;and the value to al
  rep stosb             ;write block
  jmp  @over
  @not_packed:
  stosb
  @over:
  cmp   si,offset 0f000h   ;everything uncrunched ?
  jb    @do_unpack
  jmp   start              ;run the original shit...


cseg    ends
        end start
        end
