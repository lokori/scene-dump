Not-an-engine
=============

It is perhaps an exaggeration to call this "3D engine" but when I wrote this things were different. The hardware accelerated 3D graphics was only becoming mainstream.

And I had an intention to make this a real engine. But then I went to university to learn programming and it turned out that I actually knew very little about it.

Anyway, it actually does some things
 * Fake phong-shading in software, the de facto standard of that era
 * Loads 3D Studio objects (ASC format)
 * 4x4 matrix based affine transforms are in place
 * The time-critical parts are optimized in various ways 

Toolset
======= 
Watcom C
Watcom make
Borland's TASM for the phong shader inner loop 
Borland's TLINK for linking objects

