bootsector intro
================

Apparently I wrote this in 1995. It is a custom boot sector code for the diskettes of that era. 

The boot sector size back then was 512 bytes and the intro has two demoeffects (copper bars and fire) and allows the user to proceed with normal boot. 

I made a custom build of FDFORMAT utility program to use this boot sector code instead of the original.

FDB.ASM contains the intro code. Compiles with TASM. 
The rest is Turbo Pascal code and compiles with Turbo Pascal.

About boot sectors
==================

What made boot sector intros particularly interesting was that it was very low-level. Just bare metal and BIOS.

Also there was extreme control. No need to "malloc" anything since my code was the only thing running at that point. Of course there was no malloc to call anyway since by definition there was no operating system available.

A challenge
===========

Try doing that with today's machines. Make that machine do something interesting without an operating system. Good luck.



