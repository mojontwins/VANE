wav2snd loop.wav
wav2snd sound1.wav
wav2snd sound2.wav
wav2snd sound3.wav
sjasm\sjasm z80dsnd.asm
del z80dsnd.bin
ren z80dsnd.out z80dsnd.bin
asasm\bin\as digital.asm
asasm\bin\p2bin digital.p -r $00000000-$00040000
pause
del *.p
del z80dsnd.bin
del *.lst
del *.tfc
del *.raw