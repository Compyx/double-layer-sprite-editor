Double layer sprite editor
==========================


Introduction
------------

A simple editor for creating double layer sprites, that is: one multicolor
sprite with a singe color sprite on top. I wrote this for a demo project I'm
working on, so it's tailored to my needs (eg edit with keys, not joystick).

So far there's no disk menu, so you need to save the data manually with a
ML monitor in your cartridge or emulator. The sprites are located at
$2000-$3ffe, with each double layer sprite taking 128 bytes.


Building
--------

Building this tool requires [64tass](https://sourceforge.net/projects/tass64/).
For Unix-like systems, a Makefile is provided: just issue `make` to build, or
`make x64` to build and run with VICE.


TODO
----

* Add disk menu
* Properly compress binary with exomizer or something similar
* Proper documentation

