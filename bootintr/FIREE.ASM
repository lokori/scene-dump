cseg         segment   para public 'CODE'
	     assume    cs:cseg
	     org 100h                           ;Make as COM file
	     .286

;
;*********** GENERAL (INTRO) CODE
;

entry:
	     sti
	     cld
	     ;**
	     ;**  FIRE !!!!
	     ;**
	     mov ax,13h                 ;Init 320x200 256 colors
	     int 10h
	     mov cx,127
	     @palinit:
	     
	     mov al,cl                  ;Colors 0-127
	     mov dx,3c8h
	     out dx,al
	     inc dx
	     shr al,1
	     out dx,al
	     shr al,2
	     out dx,al
	     mov al,cl
	     shr al,2
	     out dx,al

	     mov al,cl                  ;Colors 128-255
	     add al,128
	     mov dx,3c8h
	     out dx,al
	     inc dx
	     mov al,127
	     sub al,cl
	     shr al,1
	     out dx,al
	     shr al,2
	     out dx,al
	     mov al,127
	     sub al,cl
	     shr al,2
	     out dx,al

	     
	     loop @palinit

	     mov ax,0a000h
	     mov es,ax
	     mov ax,4209h               ;Tweak a bit....
	     mov dx,3d4h
	     out dx,ax
	     mainfire:
	     
	     ;** init new row of fire primitives
	     mov di,320*133
	     mov ax,320                 ;320 pixels
	     @initnewfire:
	     mov cx,255
	     call random
	     mov es:[di],dl
	     inc di
	     dec ax
	     jnz @initnewfire
	     
	     ;** update the fire
	     mov cx,320*64
	     mov di,70*320
	     xor ah,ah
	     xor dh,dh
	     @firepixels:
	     mov al,es:[di+640]
	     mov bl,es:[di+321]
	     add ax,bx
	     mov bl,es:[di+319]
	     add ax,bx
	     mov bl,es:[di+320]
	     add ax,bx
	     shr ax,2
	     jz  @guuguu
	     sub al,1
	     jz  @guuguu
	     sub al,1
	     @guuguu:
	     stosb
	     loop @firepixels

	     mov ah,1
	     int 16h
	     jz  mainfire

	     ;**
	     ;**  EXIT THE INTRO
	     ;**
	     mov ax,3
	     int 10h
	     ret

;** WAIT FOR VERTICAL RETRACE
waitretrace  proc near
	     pusha
	     mov dx,3dah
	     @a:
	     in al,dx
	     test al,8
	     jnz @a
	     @b:
	     in al,dx
	     test al,8
	     jz @b
	     popa
	     ret
waitretrace  endp

;RANDOM NUMBER GENERATOR
;IN:
;  CX=random number ranges
;OUT:
;  DX=random number
random          proc    near
		push ax
		push bx
		mov ax,cs:[offset seed]
		mov bx,9821
		imul bx
		inc ax
		ror al,1
		add ax,8191
		rol ah,1
		mov cs:[offset seed],ax
		xor dx,dx
		div cx
		pop bx
		pop ax
		ret
		endp

seed         dw 9821                           ;Random number seed
counter1     db 0
counter2     db 0


cseg         ends
	     end       entry
