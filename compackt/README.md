runtime RLE packer 
==================

Packs MS-DOS executable (COM) using simple RLE coding.
I was experimenting.

The packer was mostly just a proof-of-concept as better
crunchers were available already.

The SBOBB.ASM is a simple 1k shadebob intro/effect which
the packer crunches into 10% smaller executable.

The virii aspect
================

This unpacker/packer scheme is very similar to what virus programs
do when they infect a host executable. I was interested in this but
didn't really want to create a virus with payload and infect-mechanisms.

