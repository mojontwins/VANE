VANE - Visual Adventure Novel Engine
====================================

VANE is a Visual Novel engine for SEGA Mega CD (we have in mind porting it to other weird systems such as PC XT/CGA, for example). It's based upon several subprograms which are chained together to create a game. There's one module missing: a Snatcher style battle engine which I never finished.

You will need BasiEgaXorz. Go get it from http://devster.monkeeh.com/sega/basiegaxorz/ . Read some docs and get a hello world program running from a cart in your emulator before even attempting to read this doc.

Also, you should learn a bit about how Mega CD works. There's a data track on the CD, which is divided in "clusters". Clusters are numbered chunks of data within the data track which can be individually loaded by the Mega CD. We'll be talking about clusters *a lot*, so be sure you understand the basics.

Visual Novels are created assembling assets in clusters. Most of your clusters will be image data or script data. Together, a image data cluster and [at least] a script data cluster will make a "chapter". Each cluster is loaded in the Mega CD's RAM space, so the length of your "chapter" is somewhat limited. In each "chapter" you have 120K for images and 4K for scripting. A VANE game is divided into "chapters". 

Subprograms
===========

As mentioned, VANE is based on several chained subprograms. Such subprograms reside in individual clusters in the CD. A minimal VANE game would contain three subprograms:

- **main.bex** - This is the main program, which initalizes stuff and jumps to the menu (if present) or directly to the engine (otherwise).
- **menu.bex** - This should contain your main menu / title screen / etc. You have to code this in BEX yourself.
- **vane.bex** - This is the engine itself, which runs the defined "chapters" in order.

The engine supports two extra programs with almost no modification:

- **gameover.bex** - You know.
- **ending.bex** - Yeah, you know.

You can add your own custom subprograms. There are 32 slots for defining custom subprograms. The first five slots are reserved for the above mentioned subprograms and should not be altered.

In a Mega CD, programs are loaded from clusters. There's a 32 byte reserved memory section used to define which cluster contains each of the defined subprograms. If the value stored is 0, it means that such slot contains no subprogram.

main.bex
========

BEX is a tad strange. The implementation of Mega CD support is a bit sketchy, but it gets the job done. Basicly, you have a main subprogram which BEX will stuff in cluster 1. BEX runtime itself is stored at cluster 0. When you run the CD, BEX runtime will jump to cluster 1 after initializing some stuff.

This main subprogram is a bit special - besides actual code, it contains compiler directives which instruct BEX which additional clusters it should add to the data track in the CD. This is performed via `addscd` commands. 

In VANE, `main.bex` is used to load binaries and programs into clusters, configure the program slots and other options, and then run the menu slot or the engine slot.

Slots-clusters mapping
----------------------

The first section in `main.bex` contains POKEs to map suprogram slots to clusters. As mentioned, the five first slots are reserved for menu, engine, battle, game over and ending. Slots table is located at memory addresses $FFFF00 - $FFFF1F inclusive. A typical, minimal slot mapping would be:

```
    ' Configure the location of subprograms here.
    ' Poke a 0 to deactivate.
    
    Poke &HFFFF00, 2                    ' MENU.SCD
    Poke &HFFFF01, 3                    ' VANE.SCD
    Poke &HFFFF02, 0                    ' BATTLE.SCD
    Poke &HFFFF03, 0                    ' GAMEOVER.SCD
    Poke &HFFFF04, 0                    ' ENDING.SCD
```

As mentioned, a 0 means "not present". VANE will ignore default slots if a zero is found. The battle system is still not implemented nor hooked, by the way.

Cluster loading
---------------

The next section in main.bex is used to tell BEX which binaries / compiled subprograms it should add to the data track in the CD. This is done via `addscd` commands. Note that `addscd` only takes a file name as a parameter, so you should keep track of the cluster number yourself.

As we mentioned before, BEX's runtime is stored at cluster 0, whereas the main subprogram in main.bex will be stored at cluster 1. So the first `addscd` command you issue will load the binary at cluster 2, the next at cluster 3, and so on. Do yourself a favour and take note of which cluster contains which binary. 

The subprograms you want to add to your CD data track must be compiled first. Open them in BEX and compile them to SCD. Be sure to store all your SCDs together alongside the main.bex file. Once you have them in SCD you can add them using `addscd`. On a minimal VANE project, as described, you should have `menu.scd` (from `menu.bex`) and `vane.scd` from `vane.bex` ready. Then load them up:

```
'' Cluster loading...

    addscd menu.scd                     ' 2
    addscd vane.scd                     ' 3
```

Note how I keep track of which clusters are those binaries being loaded to using coments. Note also how the cluster numbers are the same POKEd to the $FFFF00 - $FFFF1F range in the first section of `main.bex`.

General asset loading
---------------------

The next section will load some binaries used for general assets. In the barebones project included with this distribution, I load two pairs of charset-palette definitions. I use the first pair in the menu and the second pair in VANE. 

```
    addscd bin\charset-menu.bin         ' 4
    addscd bin\charset-menu-pal.bin     ' 5
    
    addscd bin\charset-vane.bin         ' 6
    addscd bin\charset-vane-pal.bin     ' 7
```

We also use this section to add a cluster with custom sounds we can fire up from the scripts. Please read the section *Sounds cluster* for more info:

```
    addscd bin\sounds.bin               ' 8
```

Chapters loading
----------------

Your game is split in chapters, which are [in their simplest form] pairs of clusters containing image data and script data. In the engine (see later), each chapter is refered by the cluster number of its image cluster (the related script cluster[s] comes next), so related image and script clusters should be loaded together, image cluster first. 

The next part of `main.bex` is used to load up the clusters of each chapter in the game. Our bare bones proyect only has two chapters:

```
    ' The game
    
    ' Chapter 1
    addscd bin\im00c.bin                ' 9
    addscd bin\sp00c.bin                ' 10

    ' Chapter 2
    addscd bin\im01c.bin                ' 11
    addscd bin\sp01c.bin                ' 12
```

The last thing `main.bex` does is executing `menu.scd` if its slot #1 does not equal 0 but a cluster number, or `vane.scd` directly, otherwise.

menu.bex
========

You can use menu.bex for many things. For example, you could store several visual novels in the same CD and launch the engine starting in the correct "chapter" for each novel, or implement a password option for jumping directly to certain chapters in your novel... You name it. 

menu.bex will present a menu (or just a splash screen), it will POKE some values in the engine configuration memory area, then fire up `vane.scd`.

Engine configuration memory area
--------------------------------

The engine configuration memory area starts at $FFFF20. It is used to configure several aspects of the engine, such as from which chapter it should start, viewport position, text window size, menu position, etc.

Chapter Number
--------------

```
    Poke &HFFFF20, chapter 
```

When run, the VANE engine will start executing from the chapter number stored at $FFFF20. As explained later, `vane.bex` should contain a table specifying the cluster where each chapter resides.

Flag 127
--------

```
    Poke &HFFFF21, value 
```

The VANE engine has up to 128 integer flags. On startup, the value at $FFFF21 is copied to the last flag (#127), so you can act accordingly. This can be used for all sorts of things related to controlling how your game behaves from the menu.

Command and Next Address in Script
----------------------------------

```
    Poke &HFFFF23, 0            ' Run chapter from the beginning.
    Poke &HFFFF24, 0
    Poke &HFFFF25, 0
```

Those addresses are used internally so a script can execute a BEX subprogram and resume execution once it ends. See later for more info on 'external subprograms'. Just set them to zero.

Language modifier
-----------------

```
    Poke &HFFFF26, language
```

We mentioned that each chapter was a "pair" of image data and script data. This is not completely true, as each chapter is in fact a "tuplet" of clusters, the first being a common image data cluster and the rest equivalent script clusters in different languages.

Imagine you want to create your novel in English and Spanish and you load your chapters as triplets of image cluster, script cluster in English, script cluster in Spanish. With that configuration, poking "0" to $FFFF26 would make VANE always run the English language scripts, and poking "1" would make it run the Spanish language scripts.

In other words, if chapter N is stored from cluster M onwards, then cluster M is the image cluster, and cluster M + 1 + language_modifier is the associated script which will be run.

For single language games, just poke a 0.

Top of the screen
-----------------

```
    Poke &HFFFF27, 1
```

This is the character line from which pictures will be displayed. If you use a title bar, for example, poke an 1.

Show title bar
--------------

```
    Poke &HFFFF28, 1            ' Show title bar (chars at $FFFEE7-FFFEFF)
```

If set to 1, VANE will draw a title bar at the top of the screen (character line 0) and will output the 25 characters stored at addresses $FFFEE7 to $FFFEFF. This usually contains the title of your game.

Contents of $FFFEE7 - $FFFEFF is POKEd from `menu.bex` using code simmilar to this:

```
    '' Poke title bar from &HFFFEE7 to &HFFFEFF
    Reload titlebar_text
    For idx&=&HFFFEE7 To &HFFFEFF
        Read c: Poke idx&, c
    Next idx&

[...]

titlebar_text:
    Data 69, 83, 80, 65, 67, 73, 79, 32, 45,  32, 84, 73, 69, 77, 80, 79, 32, 66, 89, 32, 76, 83, 95, 65, 80

```

Those numbers are character numbers from the charset loaded in cluster #6 from charset-vane.bin and contain the game title.

Text window height
------------------

```
    Poke &HFFFF29, 3            ' Text window height
```

Text window height, in character lines. Text window will be rendered at the bottom of your screen.

Menu position
-------------

```
    Poke &HFFFF2A, 21           ' Menu Bottom
    Poke &HFFFF2B, 28           ' Menu Left
```

Where the menu box is displayed. The menu box is 12 characters wide, and 2 + the number of menu items high. As the vertical size is variable and depends on the number of menu items, to define where the menu box should appear you specify the coordinates of the bottom left corner of the box. Make sure it fits!

-

Once everything is configured, `menu.bex` executes the cluster defined in slot 1 ($FFFF01), which should contain the engine, `vane.bex`.

vane.bex
========

This subprogram includes the main visual novel engine. It runs compiled scripts to display images and play Audio CD tracks, besides short samples (very limited in this regard, I'm afraid).

There's some things you must modify in `vane.bex` to get your game running, such as the chapter->cluster mapping and some miscellaneous stuff.

Chapter->Cluster mapping
------------------------

This is just a table which tells the first cluster (the image cluster) of each chapter. In our example, we just have two chapters. Their image clusters are numbers 9 and 11, so:

```
' Use this table to define the base cluster of each chapter in your game
chaptersBaseClusters:
    Data 9, 11
```

This makes chapter 0 = cluster 9 (and 10) and chapter 1 = cluster 11 (and 12). Check `main.bex` again to see how the numbers match.

Constants
---------

There are several sets of constants. You should tinker with most, but those are useful:

```
    Const #CLUSTER_CHARSET = 6
    Const #CLUSTER_CHARSET_PAL = 7
    Const #CLUSTER_SAMPLES = 8
```

These define the cluster where you loaded your charset, your charset palette, and your samples.

Image converter
===============

The image converter is used to convert images in png format and stuff them together in a cluster you can load from `main.bex`. It's located in `utils` and its main syntax is:

```
    $ mkimgcluster.exe out.bin [pal:pal.png] in1.png[#pal.png] in2.png[#pal.png] in3.png[#pal.png]
```

Where out.bin is the output binary with all the converter, indexed, and crunched images. If you include the parameter pal:pal.png, then pal.png will be used as a global palette for all the images. If you don't, each image will have its own palette, which can be calculated from the image itself or from a separate palette file.

The image list is specified next. You can append #pal.png after each entry to force fixed palettes. Palette images are simple 16x1 png files with one pixel per palette entry.

The binaries generated by this pool can be directly included as clusters from `main.bex` when defining the chapters.

**The output binary shouldn't be bigger than 120K**

Scripts compiler
================

Scripts are written in plain text files then compiled using the scripts compiler `gmgsc.exe`. For a complete language reference just check `scripting.md`. Compiling with `gmgsc.exe` is a piece of cake:

```
    $ gmgsc.exe script.spt out.bin
```

This will generate a binary file which can be directly included as a cluster from `main.bex` when defining the chapters.

**The output binary shouldn't be bigger than 4K**

Sample stuffer
==============

The sample stuffer takes a bunch of RAW samples and creates an indexed cluster with them. Such cluster can be included as the sounds cluster in `main.bex`. You can convert plain WAV files to RAW samples using the included wav2snd.exe by Shiru. Once you have your waves converted, stuff them together using `mksndclstr.exe`:

```
    $ mksndclstr.exe out.bin list.txt
```

Where list.txt contains a list of samples, one per line.

Misc stuff
==========

Image height
------------

Your images should be high enough to fit. No pun intended. The height of the screen space destined for images is determined by the value of "Top of the screen" and the value of "Window height". The value in pixels should equal:

```
    picture height = 224 - (text_window_height + top_of_the_screen) * 8
```

Palette considerations
----------------------

The converter will try to make its best, but for best results use a very dark colour as your darkest colour, less than 16 colours, and colours from `9bitpal.png`. The converter will sort the palette by luminance, meaning that the darkest colour will be used as background colour. 

I know this could be improved, but can't be arsed at the moment ;-)

Charset and charset palette
---------------------------

You should use the included charsets as a basis to design yours. Then you can convert them with Imagenesis and export the pattern data as palette binaries. Get Imagenesis from http://devster.monkeeh.com/sega/imagenesis/

Legal shit
==========

This engine is GPLv3. If you want to make a game with it and sell it, pretty please contact us so we can make an agreement.

I don't know what to do
=======================

I know the feeling, that's why I have writen a small doc on how I built the demo project, step by step. Check `tutorial.md`

Copyleft 2015 by The Mojon Twins
