How to compile:

You need AS Assembler and SjAsm:

http://sega-devega.net/ASAsm.zip
http://home.planet.nl/~realfun/sjasm.html

Place AS Assembler into directory /asasm/ and SjAsm to directory /sjasm/ (see
compile.bat for details).



About:


   This is my 4-channel sample player,  which I wrote in testing purposes for 3
days.  Maybe it can be useful for someone,  possible in  educational purposes -
because I don't think it can be useful in real programs  (until you write music
player for M68K which waste many processing power).

Note that 'simple' means functionality, not 'easy to implement or understand'.


Features:

- 4 channels of 6-bit sound
- Samples can be placed anywhere in 4MB of ROM
- Samples can have any length (i.e. much more >32KB)
- Samplerate 16000Hz

Limitations:

- Samples must be 256-byte aligned in ROM
- Samples length must be 256-byte aligned too
- Low output volume

Problems:

- Very stupid communication between Z80/M68K (I did it only for testing
  purposes)
- Very simple channel manager, but on Z80 side
- I don't know exactly how many t-states takes POP in banked ROM, just assumed
  that it near to 12t (if more then real samplerate will be lower).


   I also wrote tool,  which converts samples in acceptable format (8-bit raw,
16000Hz,  with 256-byte aligned length).  But it's better  to  resample  sound
source to  16000/8/mono  in any sound editor,  because tool  does only  simple
linear interpolation for resampling.

  Player still have some free time, so it's possible to make samplerate higher,
although  I don't think it's  really needed  (16000Hz means you spend ~16KB per
second of sound).

Do anything you want with it;)



mailto:    shiru@mail.ru
site:      http://shiru.untergrund.net
discuss:   http://www.spritesmind.net/_GenDev/forum/viewtopic.php?t=145