
     IDEAL
     P386
     LOCALS

     segment    _DATA      para use32 'DATA'
                xend    dd      0
                xstart  dd      0
     ends       _DATA

     segment    _BSS para
     ends       _BSS


     group              DGROUP  _DATA, _BSS

     segment            _TEXT byte use32 public 'CODE'
                        assume  CS:_TEXT, DS:DGROUP
                        public  phonginterpola_

     proc               phonginterpola_       far
                        push    ebp
                        mov     ebp,esp         ;get access to arguments
                        pusha

                        mov     edi,[ebp+8+4]   ;XX
                        mov     esi,[ebp+8]     ;X

                        cmp     edi,0           ;do tha clipfucking
                        jge     @not_zerro
                        xor     edi,edi
                       @not_zerro:
                        cmp     edi,320*256
                        jl      @not_muchos
                        mov     edi,319*256
                       @not_muchos:
                        shr     edi,8
                        add     edi,[ebp+8+12]
                        cmp     esi,0           ;ADSASDASD
                        jge     @not_zerroo
                        xor     esi,esi
                       @not_zerroo:
                        cmp     esi,320*256
                        jl      @not_muchoss
                        mov     esi,319*256
                       @not_muchoss:
                        shr     esi,8
                        add     esi,[ebp+8+12]

                        cmp     edi,esi         ;edi=XX, esi=X
                        je      fast_end
                        jg      @no_change
                        xchg    ebx,ecx
                        xchg    eax,edx
                        xchg    esi,edi
                       @no_change:
                        mov     [xend],edi
                        mov     [xstart],esi
                        xchg    edi,ecx         ;XX
                        sub     ecx,esi
                        sub     edi,ebx         ;EDI=BV-AV
                        mov     esi,edx
                        sub     eax,edx         ;EAX=BU-AU
                        cdq
                        idiv    ecx
                        xchg    eax,edi         ;EBX=starting V, EDI=U adder
                        cdq
                        idiv    ecx
                        mov     ecx,[xstart]
                        xchg    esi,eax         ;EAX=starting U, ESI=V adder
                        mov     ebp,[ebp+8+8]   ;ebp=pointer to phongmap
                        xor     edx,edx
                        @loop:
                                mov     dh,bh
                                mov     dl,ah
                                mov     dl,[edx+ebp]
                                mov     [ecx],dl
                                add     eax,edi
                                add     ebx,esi
                                inc     ecx
                                cmp     ecx,[xend]
                                jne     @loop
                      fast_end:
                        popa
                        mov     esp,ebp
                        pop     ebp
                        retn
     endp               phonginterpola_

     ends       _TEXT
     end
