cseg         segment   para public 'CODE'
	     assume    cs:cseg
	     org 100h                           ;Make as COM file
	     .286

;
;*********** BOOT SECTOR SPECIFIC CODE
;

begin:       jmp       short start              ;Jump
	     nop
bpb          db        3FH DUP (0)              ;Reserve enough space for BPB

start        proc      far
	     cli                                ;Clear Interrupts, while modifying stack
	     xor       ax,ax                           
	     mov       ss,ax                    ;Set Stack...
	     mov       sp,7c00h                 ;..below Code
	     mov       ax,7b0h                  ;Set Segment-Registers that Offset is 100H
	     push      ax                       ;Push Segment twice
	     push      ax
	     pop       ds                       ;Get Segment in DS
	     pop       es                       ;Also in ES to move the code...
	     mov       si,100h                  ;Set Source to 100H
	     mov       di,300h                  ;Set Destination to 300H
	     mov       cx,100h                  ;Set Count to 512 Bytes (1 Sector)
	     rep       movsw                    ;Move Code
	     mov       ax,7d0h                  ;New Segment at 7d0h (+20H)
	     push      ax                       ;Push Segment two times
	     push      ax
	     pop       ds                       ;Get new segment in DS
	     mov       ax,offset entry          ;Offset of next instruction
	     push      ax                       ;Push to stack
	     ret                                ;and pop it to CS:IP
start        endp

;
;*********** GENERAL (INTRO) CODE
;

entry        proc      far
	     sti
	     cld
	     call inittextmode

	     mov si,offset texti
	     mov ah,8                           ;Darkgray
	     mov di,160*10+54
	     mov cx,19
	     @tet:
	     lodsb
	     stosw
	     loop @tet

	     ;After LOOP, cl is automatically zero... saves bytes...
	     @hiahia:
	     hlt                        ;Delay a bit...
	     call darkgrayfade
	     inc cl
	     cmp cl,63
	     jbe @hiahia
	     
	     ;**
	     ;** ACTUAL INTRO... LET'S MAKE SOME COPPER!!!!
	     ;** 

	     mov ah,1
	     mov bx,4

	     maincopper:      
	     call waitretrace            ;Init frame 
	     
	     mov dx,3dah
	     mov cl,bl
	     @h1:               ;Wait horizontal retrace
	     in al,dx
	     test al,1
	     jnz @h1
	     @h2:
	     in al,dx
	     test al,1
	     jz @h2
	     loop @h1          ;Loop blank shit away 
	     
	     ;CX=0, coz of the previous LOOP - instr. saves byte :-)

	     @makecopper2:     ;Kick some ass....
	     call makesinglecopper
	     inc cl
	     cmp cl,63
	     jne @makecopper2
	     @makecopper:
	     call makesinglecopper
	     loop @makecopper
	     
	     add bl,ah            ;move copper bar
	     cmp byte ptr cs:[offset counter1],200
	     jne @nosj
	     mov byte ptr cs:[offset counter1],0
	     neg ah               ;Change direction
	     inc byte ptr cs:[offset counter2]
	     @nosj:
	     inc byte ptr cs:[offset counter1]
	     cmp byte ptr cs:[offset counter2],4
	     jne maincopper

	     mov cl,63
	     @hiahia2:                  ;Fade text away
	     hlt                        ;Delay a bit...
	     call waitretrace           ;Sync with monitor -> no flickering
	     mov dx,3c8h
	     mov al,56                  ;DARKGRAY palette index, see above
	     out dx,al
	     inc dx
	     mov al,cl
	     out dx,al
	     out dx,al
	     out dx,al
	     loop @hiahia2

	     ;**
	     ;**  FIRE !!!!
	     ;**
	     
	     mov ax,13h                 ;Init 320x200 256 colors
	     int 10h
	     push 0a000h
	     pop es
	     mov ax,4209h               ;Tweak a bit....
	     mov dx,3d4h
	     out dx,ax

	     ;** Init the palette
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
	     loop @palinit

	     mainfire:

	     ;** init new row of fire primitives
	     mov di,320*133
	     mov cx,255
	     mov ax,320
	     @initnewfire:
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

	     mov ah,1     ;Keep flames until key is pressed
	     int 16h
	     jz  mainfire

	     ;**
	     ;**  EXIT THE INTRO
	     ;**
	     call inittextmode
	     mov si,offset texti2
	     mov ah,8                           ;Darkgray
	     mov di,160*10+76
	     mov cx,4
	     @tet3:
	     lodsb
	     stosw
	     loop @tet3
	     mov cl,63                  ;Fade some palette
	     @hiahia3:
	     call darkgrayfade
	     loop @hiahia3

	     int 19h    ;reboot...
entry        endp

;
;***********   GENERAL PROCEDURES
;

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

;
;*********** OPTIMISATION PROCEDURES
;

inittextmode proc near
	     mov ax,3                           ;Init 80x25 text mode
	     int 10h
	     mov dx,3d4h
	     mov ax,0800eh                      ;Hide cursor
	     out dx,ax
	     push 0b800h                        ;Video segment
	     pop es
	     ret
inittextmode    endp

darkgrayfade    proc    near
	     hlt                        ;Delay a bit...
	     call waitretrace           ;Sync with monitor -> no flickering
	     mov dx,3c8h
	     mov al,56                  ;DARKGRAY palette index, see above
	     out dx,al
	     inc dx
	     mov al,cl
	     out dx,al
	     out dx,al
	     out dx,al
	     ret
darkgrayfade    endp

;** MAKE A SINGLE LINE OF COPPER BAR (CL=which one)
makesinglecopper        proc    near
	     mov dx,3dah
	     @h3:               ;Wait horizontal retrace
	     in al,dx
	     test al,1
	     jnz @h3
	     @h4:
	     in al,dx
	     test al,1
	     jz @h4
	     mov dx,3c8h       ;Output palette index 0
	     xor al,al
	     out dx,al
	     inc dx
	     mov al,cl
	     out dx,al
	     shr al,1          ;Elite palette shade....
	     out dx,al
	     shr al,1
	     out dx,al
	     ret
makesinglecopper        endp

;
;*********** INTRO DATA
;

texti        db 'Boot by L™K™/Napalm'
texti2       db 'BYE!'
seed         dw 9821                           ;Random number seed
counter1     db 0
counter2     db 0

	     db        55h,0aah                 ;"FDREAD MAGIC BYTES"

cseg         ends
	     end       begin
