Tutorial
========

Please read `readme.md` and `scripting.md` first. In this document I'll be document how I make the example project included. The example will contain two minimal chapters. It's not a decent showcase of the scripting capabilities and definitely doesn't demonstrate the ability to run external subprograms written in native BEX, but it should suffice.

What I will be doing
====================

The game will be made of two chapters. The first will show a splash screen and a simple cut. The second will set up a scrolling background and show some text. The first chapter will jump to the second, and the second to the first.

Folder structure
================

I have this structure:

```
+--src
   +--bin
   +--script
   +--shirusfx
+--gfx
+--snd
+--util
```

Preparing the image clusters
============================

The first chapter's image cluster will contain a logo and a cut which will be printed over it. Both images use the same palette. Images are gfx\LSLOGO.png and gfx\cut.png. To create the image cluster containing both images, run:

```
    jcastano@SDTPC374 D:\git\VANE
    > cd gfx

    jcastano@SDTPC374 D:\git\VANE\gfx
    > ..\util\mkimgcluster.exe ..\src\bin\im00c.bin LSLOGO.png#cut.png cut.png
    Image: LSLOGO.png, extract palette from cut.png
    Reading cut.png
    Calculating palette.
    Reading LSLOGO.png
    This is a full screen image
    Building tileset and tilemap
    Unique tiles: 94, tileset is 3008 bytes.
    Adding to binary ...

    Image: cut.png
    Reading cut.png
    Calculating palette.
    Reading cut.png
    This is a 8x8 tiles cut.
    Building tileset and tilemap
    Unique tiles: 47, tileset is 1504 bytes.
    Adding to binary ...

    Cool! Writing output...
    Writing index
    Writing data
```

This will generate im00c.bin in src\bin\. Note how we use the same palette for both images. We could have done it the way around, or used pal:cut.png at the beginning. 

The second chapter's image cluster will contain the scrolling BG, and nothing else.

```
    jcastano@SDTPC374 D:\git\VANE\gfx
    > ..\util\mkimgcluster.exe ..\src\bin\im01c.bin a003.png
    Image: a003.png
    Reading a003.png
    Calculating palette.
    Reading a003.png
    This is a 64x24 tiles cut.
    Building tileset and tilemap
    Unique tiles: 606, tileset is 19392 bytes.
    Adding to binary ...

    Cool! Writing output...
    Writing index
    Writing data
```

This will generate im01c.bin in src\bin\. 

Preparing the scripts
=====================

The first chapter's script will show the BG (image 0), load up the cut (image 1) as cut #0 and paste it on screen several times. Then it will show some text, and jump to chapter 1. File is src\script\sp00c.spt:

```
# sp00c.spt, splashy demo

    TALK OFF
    CLEARTEXT
    CLS

    TW "THIS IS A BORING, BORING, BORING DEMONSTRATION OF THE VANE ENGINE."

# Play some music

    CDPLAY 2

    FANCY ON
    CLEARTEXT

    # Display image 0 as background
    IMAGE 0

    # Load image 1 to cut 1
    CUT_LOAD 1, 1

    TW "LET ME DISPLAY SOME CUTS"

    CUT_SHOW 1, 5, 5
    CUT_SHOW 1, 10, 10
    CUT_SHOW 1, 15, 15

    TW "DONE! JUMP TO CHAPTER 1."

    CHAPTER NEXT
    
```

The second chapter will set up a slow auto scroll while displaying text. Then it will jump back to chapter 0. File is src\script\sp01c.spt

```
# sp01c.spt, scrolly demo

    TALK OFF
    CLEARTEXT
    CLS

    # Reset scroll
    SCROLL_SET 0

    # Set image 0 in this cluster as scrolly bg
    SCROLL_BG 0

    # Start a slowish scroll
    # 34 means 34-32 = 3 frames per pixel.
    # Notation trick: /N means N/8. Useful...
    # This is the same as SCROLL_TO 24, 34
    SCROLL_TO /192, 34

    # This doesn't interrupt the execution. 
    # display text meanwhile
    TALK "XINKSS"
    TW "THIS IS SOME TEXT BEING DISPLAYED WHILE THE SCROLLY IS DOING ITS JOB... ONCE YOU CLICK, THIS IS DONE."

    CHAPTER 0
```

Compile both scripts to /src/bin:

```
    jcastano@SDTPC374 D:\git\VANE\gfx
    > cd ..\src\script

    jcastano@SDTPC374 D:\git\VANE\src\script
    > ..\..\util\gmgsc.exe sp00c.spt ..\bin\sp00c.bin
    VANE Script Compiler v0.5 by The Mojon Twins
    Reading your shit from sp00c.spt...
    Done processing. Alias 0, texts 3 (126 bytes), labels 0, branches 0.
    Writing your shit @ ..\bin\sp00c.bin

    jcastano@SDTPC374 D:\git\VANE\src\script
    > ..\..\util\gmgsc.exe sp01c.spt ..\bin\sp01c.bin
    VANE Script Compiler v0.5 by The Mojon Twins
    Reading your shit from sp01c.spt...
    Done processing. Alias 0, texts 1 (106 bytes), labels 0, branches 0.
    Writing your shit @ ..\bin\sp01c.bin
```

Preparing and compiling VANE
============================

Fire up BasiEgaXorz and open main.bex. Edit to suit our needs: two chapters, everything else is default.

```
'' VANE 0.2 by The Mojon Twins & Relevo
    option SEGACD
    option NOLOADFONT

'' Cluster configuration

    ' Configure the location of subprograms here.
    ' Poke a 0 to deactivate.
    
    Poke &HFFFF00, 2                    ' MENU.SCD
    Poke &HFFFF01, 3                    ' VANE.SCD
    Poke &HFFFF02, 0                    ' BATTLE.SCD
    Poke &HFFFF03, 0                    ' GAMEOVER.SCD
    Poke &HFFFF04, 0                    ' ENDING.SCD
    
'' Cluster loading...

    ' Main subprograms

    addscd menu.scd                     ' 2
    addscd vane.scd                     ' 3
    
    ' General assets

    addscd bin\charset-menu.bin         ' 4
    addscd bin\charset-menu-pal.bin     ' 5
    
    addscd bin\charset-vane.bin         ' 6
    addscd bin\charset-vane-pal.bin     ' 7
    
    addscd bin\sounds.bin               ' 8
    
    ' The game
    
    ' Chapter 0
    addscd bin\im00c.bin                ' 9
    addscd bin\sp00c.bin                ' 10

    ' Chapter 1
    addscd bin\im01c.bin                ' 11
    addscd bin\sp01c.bin                ' 12
    
    ''
    
    '' Jump to menu if menu exists, otherwise jump to VANE
    '' with first chapter (default)
    If Peek(&HFFFF00) <> 0 Then
        loadscd Peek(&HFFFF00)
    Else
        Poke &HFFFF20, 0
        loadscd Peek(&HFFFF01)
    End If
```

You can't compile this yet. Now tune up menu.bex as specified in the `readme.md`.

```
'' VANE 0.2 by The Mojon Twins & Relevo
    option SEGACD PROGRAM
    option NOLOADFONT
    
'' Use this module for your nice, custom menu.
    
    ' Constants
    Const #CLUSTER_CHARSET = 4
    Const #CLUSTER_CHARSET_PAL = 5
    Const #SYSFONTBASE = 0
    Const #DUMMYBUFFER = &H230000           ' Temporal buffer.
    
    ' Change constantly during development :-/
    ' Total number of chapters.
    Const #MAXCHAP = 2
    
    ' Set up font & font palette
    loadscd #CLUSTER_CHARSET, VRAM, 0, 192, #SYSFONTBASE
    loadscd #CLUSTER_CHARSET_PAL, POINTER, 0, 32, #DUMMYBUFFER
    For i = 0 To 15
        Palette PeekInt(#DUMMYBUFFER + i + i), 0, i
    Next i
    
    ' Show text (and wait for user input to unblock secret stuff
    locate 11, 10: Print "(^) LSAN PRODUKTIONS"
    locate 12, 10: Print "(^) THE MOJON TWINS"
    locate 14, 14: Print "LOADING..."

    chapter = 0
    
    '' And now fire up VANE with the correct chapter #.
    Poke &HFFFF20, chapter      ' Next chapter to load by VANE.SCD
    Poke &HFFFF21, 0            ' Gets copied to flag #127
    Poke &HFFFF23, 0            ' Run chapter from the beginning.
    Poke &HFFFF26, 0            ' Language modifier.
    Poke &HFFFF27, 1            ' Top of the screen
    Poke &HFFFF28, 1            ' Show title bar (chars at $FFFEE7-FFFEFF)
    Poke &HFFFF29, 3            ' Text window height
    Poke &HFFFF2A, 21           ' Menu Bottom
    Poke &HFFFF2B, 28           ' Menu Left
    
    '' Poke title bar from &HFFFEE7 to &HFFFEFF
    Reload titlebar_text
    For idx&=&HFFFEE7 To &HFFFEFF
        Read c: Poke idx&, c
    Next idx&
    
    ' Show CD
    DrawTilesInc 96, 18, 6, 4, 4
    
    ' Load VANE.SCD
    loadscd Peek(&HFFFF01)

titlebar_text:
    Data 32, 32, 32, 32, 32, 
```

Compile `menu.bex` and make sure `menu.scd` appears in the src directory.

Now open `vane.bex`. Be sure to specify the correct chapter list at the top of the file:

```

[...]
```

Compile `vane.bex` and make sure `vane.scd` appears in the src directory.

Now compile `main.bex`.

You sould obtaim `main.iso` in the src directory.

Adding our audio CD track
=========================

Use your favourite mp3 and rename it main02.mp3, place it in src and then create a `main.cue` file:

```
FILE "main.iso" BINARY
TRACK 01 MODE1/2048
INDEX 01 00:00:00
POSTGAP 00:02:00
FILE "main02.mp3" MP3
TRACK 02 AUDIO
PREGAP 00:02:00
INDEX 01 00:00:00
```

Cool!
=====

You are done. Feed main.iso to your emu and enjoy.
