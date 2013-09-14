;ฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒ
;ฒฒ                                                  ฒฒ
;ฒ             Calculating the Julia set              ฒ
;ฒ                                                    ฒ  
;ฒ            protected mode version 0.1แ             ฒ
;ฒ                                                    ฒ
;ฒ      (C) by Antti Virtanen aka L”k” / Napalm       ฒ
;ฒฒ                                                  ฒฒ
;ฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒฒ

    IDEAL       
    P386
    LOCALS              
                 
STACKLEN       	= 4000h 		; size of stack in bytes
                                                           
segment         _DATA           dword public use32 'DATA'
ends            _DATA           
segment         _BSS            para public use32 'BSS'                                                
ends            _BSS            
                                                       
group           DGROUP   _DATA, _BSS
assume  cs:_TEXT, ds:DGROUP             
                                                         
extrn   _pm_info:far, _pm_init:far      
                                        
segment         PMODE_TEXT      para public use16 'CODE'
assume  cs:PMODE_TEXT, ds:PMODE_TEXT    
                                 
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
align 2            
errmsgtbl       dw      errmsg0,errmsg1,errmsg2,errmsg3
                dw      errmsg4,errmsg5,errmsg6
                  
errmsg0         db      'Not enough low memory!',13,10,36
errmsg1         db      '80386 or better not detected!',13,10,36
errmsg2         db      'System already in protected mode and no VCPI or DPMI found!',13,10,36
errmsg3         db      'DPMI host is not 32bit!',13,10,36
errmsg4         db      'Could not enable A20 gate!',13,10,36                                          
errmsg5         db      'Could not enter DPMI 32bit protected mode!',13,10,36
errmsg6         db      'Could not allocate needed DPMI selectors!',13,10,36 
                 
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
                                                         
macro   aallocate_memory
     	mov cx,1 			; allocate 1 descriptor
        xor ax,ax
        int 31h  
        mov gs,ax                       ;GS="da precalc segment"
                 
        mov ax,0501h
        mov bx,10h                      ;allocate 1 megabyte...
        xor cx,cx
        int 31h  
        mov [offset allochandle],si
        mov [offset allochandle+2],di
        mov dx,cx                       ;starting address
        mov cx,bx     
        mov bx,gs                                                                                      
        mov ax,7      
        int 31h       
                      
        mov cx,20h                      ; set size to 2Mb
        xor dx,dx                                        
        mov ax,8      
        int 31h       
            
        mov ax,gs
        lar cx,ax                       ;set access rights...
        and cl,011110011b
        mov bx,gs
        mov ax,9
        int 31h
mov [dword gs:666],0
endm             
                 
macro   allocate_memory
        mov ax,0ah                      ; create alias descriptor
        mov bx,es
        int 31h
        mov gs,ax
                
        mov ax,0501h
        mov bx,10h                      ;allocate 1 megabyte...
        xor cx,cx
        int 31h  
        mov [offset allochandle],si
        mov [offset allochandle+2],di                  
        mov dx,cx                       ;starting address
        mov cx,bx                                      
        mov bx,gs                                                                                      
        mov ax,7                                       
        int 31h                                        
endm             
                 
                 
start:  
	push cs 			; DS = CS      
        pop ds                                         
                
	call _pm_info			; get information
	jnc short @@startf0		; if no error, go on
                
@@startf1:      
	mov si,ax			; print error message for code AX                              
        add si,ax
        mov dx,[errmsgtbl+si]                          
        mov ah,9          
        int 21h           
        mov ax,4cffh                                     
        int 21h                                          
                               
@@startf0:      
	xor ax,ax  	  		; check low memory and allocate low
	mov cx,ss			;  buffer needed for protected mode
	add cx,STACKLEN                                                    
        movzx edx,[word ptr es:2]
        sub dx,cx                                                         
        cmp dx,bx                                      
        jb @@startf1
        mov es,cx
                
	movzx ecx,cx			; calculate base and size of free low
	shl ecx,4			;  memory and push to stack
        push ecx                                                                                       
        sub dx,bx
        shl edx,4                                      
        push edx                                    
                                                    
	call _pm_init	      		; enter protected mode
	jc @@startf1			; if error, go to error message
                                                    
     	mov cx,1			; allocate 1 descriptor              
        xor ax,ax                                                            
        int 31h                                                              
	mov bx,ax      		       	; BX = descriptor allocated          
        mov dx,0ffffh                   ; set size to 4G
        mov cx,dx                                                  
        mov ax,8                                        
        int 31h                                         
        mov edx,0                       ; base address=0                   
        mov ecx,edx                                     
        mov ax,7                                        
        int 31h                                         
        mov es,bx                       ; ES="da flat segment"                                         
                                
	mov cx,1			; allocate 1 descriptor
        xor ax,ax
        int 31h                                     
                                                              
	mov bx,ax			; BX = descriptor allocated
                                                    
        mov dx,0ffffh                   ; set size to 4G
        mov cx,dx                                      
        mov ax,8                                         
        int 31h                                     

	mov edx,_TEXT			; base address = 32bit code segment
        shl edx,4                                      
        shld ecx,edx,16
        mov ax,7                                                           
        int 31h
          
	mov ax,cs			; set descriptor type to 32bit code
	                                ;lar cx,ax	 		;  at the current CPL          
        lar cx,ax
        mov cl,ch                                      
        mov ch,0c0h
        mov ax,9 
        int 31h                                               
                                                         
	mov bp,bx			; preserve selector
                                                              
	mov bx,ds			; BX = current data selector
                                                              
        mov dx,0ffffh                   ; set size to 4G      
        mov cx,dx                                        
        mov ax,8                                              
        int 31h                                               
                                                              
	mov edx,DGROUP	       		; base address = 32bit data segment
        shl edx,4                                             
        shld ecx,edx,16                                       
        mov ax,7                                              
        int 31h                                               
                                                                           
        cli                             ; we don't want to be interrupted
		 			;  while changing SS:ESP
	mov ds,bx			; set all segment registers to data
	;mov es,bx  		 	;  selector              
        mov fs,bx                                               
        ;mov gs,bx                                               
        mov ss,bx                                               
                                                                
assume  ds:DGROUP                                               
                                                                
	mov eax,EXE_STACK		; adjust ESP for new base of stack
        mov ebx,DGROUP                                          
        sub eax,ebx                                             
        shl eax,4                                               
        add esp,eax                                                        
                                                                
        sti                                                      
                                                                    
  	mov [_lowbase],edx		; base address of 32bit data segment          
	pop [_lowheaplen] 		; relative base of free low memory 
	pop [_lowheapbase]		; size of free low memory
                                                                 
	push ebp			; push target CS:EIP in 32bit code
        db 66h,68h                                               
        dd offset start32                                        
                                                                 
	db 66h				; 32bit RETF to 32bit code
        retf                                                     
                                                                 
ends            PMODE_TEXT                                      

segment         _TEXT           para public use32 'CODE'
assume  cs:_TEXT                                                 
                                                                 
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
proc  juliaset      near                                        
      pusha                                                     
      mov           [dword y],-y_size/2*256              
      mov           [temp],20*max_x+(max_x-x_size)/2+0a0000h   
      @vertloop:                                                           
                mov           ebx,[y]                           
                sar           ebx,yfixer
                mov           [ozr],ebx                         
                mov           [dword x],-(x_size/2)*256          
                @horizloop:                                      
                           mov  edi,[x]                        
                           sar  edi,xfixer               ;edi=z.i
                           mov  esi,[ozr]                       
                           mov  ebx,maxiter+1                 
                        align 16
                         @iterloop:                            
                                     mov        ecx,esi                       
                                     mov        esi,[4096*4+imulprecalc+esi*4] ;esi=z.r^2
                                     mov        eax,[4096*4+imulprecalc+edi*4] ;eax=z.i^2
                                     lea        ebp,[eax+esi] ;ebp=z.r^2+z.i^2
                                     shr        ebp,18         
                                     jnz        @enuffiters ;z would grow to infinity...           
                                     sub        esi,eax  ;esi=z.r^2-z.i^2
                                     sar        esi,8                 
                                     xor        edx,edx                    
                                     imul       edi,ecx   ;edi=z.r*z.i     
                                     sar        edi,7                      
                                     db         81h,0c6h ;add esi,immed32 opcode
                                     kehitys_i  db 0f4h,0ffh,0ffh,0ffh ;-12
                                     db         81h,0c7h ;add edi,immed32 opcode
                                     kehitys_r  db 60h,1,0,0 ;352                                     
                           dec       ebx                                          
                           jnz       @iterloop                                    
                        align 16                         
                         @enuffiters:                          
                                mov     edi,[temp]             
                                mov     [es:edi],bl            
                                inc     [temp]                 
                add [dword x],256                                                 
                cmp [dword x],(x_size/2)*256                                      
                jl  @horizloop                                                    
                add [dword temp],max_x-x_size    
        add [dword y],256                                                         
        cmp [dword y],(y_size/2)*256                                              
        jl  @vertloop                                                             
      popa                                                                        
      ret                                                                         
endp                                                                              
                                                                                  
start32:                                                                          
;        allocate_memory                                  
;precalculate x*y, 0<x<1024, 0<y<1024 
;        xor     ebx,ebx         
;        mov     edi,ebx
;        @prelloo:                     
;          xor   ecx,ecx         
;          @preloo:              
;                mov eax,ecx     
;                cdq             
;                mul ebx         
;                mov [gs:edi],eax 
;                inc edi
;                       
;                inc ecx
;                cmp ecx,1024
;                jl  @preloo
;       inc ebx
;       cmp ebx,1024
;       jl @prelloo
                                                         
;precalculate x^2, x varies from -4096 to 4096                                    
        mov     ebx,4096                                                          
        xor     edi,edi                                                           
        @precalcloop:                                                             
        mov     eax,ebx                                  
        xor     edx,edx                                                           
        mul     eax                                                               
        mov     [imulprecalc+edi],eax                                             
        add     edi,4                                                             
        dec     ebx                                                               
        jnz     @precalcloop                                                      
        @precalcloop2:                                                            
        mov     eax,ebx                                                           
        xor     edx,edx                                                           
        mul     eax                                                               
        mov     [imulprecalc+edi],eax                                             
        add     edi,4                                                             
        inc     ebx                                                               
        cmp     ebx,4096                                                          
        jne     @precalcloop2                                                     
                                                                                  
;initialize graphics..                                                            
        mov     ax,13h                                                            
        int     10h                                                               
        mov     ecx,16000
        mov     edi,0a0000h                                                       
        mov     eax,50505050h   ;fill vga memory with color 32s
        rep     stosd                                                             
                                                                                  
                     mov  edx,3c8h                                                
                     mov  al,0                                                    
                     out  dx,al                                                   
                     mov  ebx,63*256                                              
                     inc  edx                                                     
                     mov  ecx,maxiter                                             
                     @pal:                                                        
                     mov  eax,ebx                                                 
                     sub  ebx,paletteass                                          
                     shr  eax,8                                                   
                     out  dx,al                                                   
                     mov  al,0                                                    
                     out  dx,al                                                   
                     out  dx,al                                                   
                     loop @pal                                                    
                                                         
mov     esi,152                                          
mov     ebx,352                                          
mov     ecx,-12                                                            
      @mainloop:                                                                  
      mov      [offset kehitys_r],ebx
      mov      [offset kehitys_i],ecx
      sub       ecx,2
      sub       ebx,4
      call      juliaset                                 
      mov       ah,1                                     
      int       16h                                      
      jz        @mainloop                                                                      
      ;dec esi                                           
      ;jnz        @mainloop           
                                      
      mov       ax,3                                     
      int       10h                   
      ;free memory                    
      mov       ax,502h               
      mov       si,[offset allochandle]
      mov       di,[offset allochandle+2]
      int       31h                   
      mov       ax,4c00h              
      int       21h                   
        mov     [es:012345h],bl 
ends            _TEXT           
                                
public  _lowbase, _lowheapbase, _lowheaplen
                                
segment         _BSS            para public use32 'BSS'
        
_lowbase	dd	?		; base address of 32bit data segment
_lowheapbase 	dd	?		; relative base of free low memory
_lowheaplen  	dd	?		; size of free low memory
                                                         
;ฒฒฒฒฒฒฒฒ data area ฒฒฒฒฒฒฒ                              
                                                         
maxiter         equ     12              ;max. number of iterations (8-40)
paletteass      equ     256*64/maxiter                   
x_size          equ     256                              
max_x           equ     320                              
y_size          equ     128                              
xfixer          equ     6                                
yfixer          equ     5                                
                                                                 
align 16
temp            dd      0                                
x               dd      0                                        
y               dd      0                                        
                                                                 
                                                                 
ozr             dd      0                                        
                                                                           
z               dd      0               ;real part               
                dd      0               ;imaginary part          
                                                                 
t               dd      0               ;temp complex number     
                dd      0                                        
                                                                 
zoom            dd      40                                       
                                                                                          
                                                                                          
imulprecalc     dd      4096*2 dup (0)    ;x^2 precalc...
                                                         
allochandle     dd      0                                 
                                                                 
ends            _BSS                                                       
                                                                           
segment         EXE_STACK        para stack use16 'STACK'                  
                db      STACKLEN dup(?)                                    
ends            EXE_STACK                                                  
                                                                           
end     start                                            