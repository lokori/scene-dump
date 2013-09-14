# Makefile for DPMI (Watcom C++ 9.5) interface.

DPMICC=wcc386 -d3 -mf -3r -ox -w9 -zq -i=c:\progr\watcom\h
DPMILN=wcl386 -l=pmodew -d2 -ox -mf -fm -hw -i=c:\progr\watcom\h

fong.exe: fong.obj ppoly.obj lmath.obj lvideo.obj
        $(DPMILN) fong.obj ppoly.obj lmath.obj lvideo.obj
                                     
fong.obj: fong.c ppoly.h lmath.h lvideo.h
        $(DPMICC) fong.c

lmath.obj: lmath.c
        $(DPMICC) lmath.c

lvideo.obj: lvideo.c
        $(DPMICC) lvideo.c
