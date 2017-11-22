Scripting
=========

Available commands, may be incomplete. It's been ages since I don't touch this project.

Images
------

Before starting a scene, you must prepare the graphics which need to be displayed. This typically includes a backdrop image and a series of "cuts", or smaller images you can paste on the background. The first thing you should so is:

```
    CLEAR
```

Which will clear the screen and reset the pattern table. Once you have done that, load your assets.

```
    IMAGE N
```

Shows image #N in the currently loaded image cluster. Images should be 320xHeight pixels. Height is determined by your UI configuration.
    
Instead of fixed images, you can load a wider image and scroll across it afterwards:

```
    SCROLL_BG N
```

By default, the scroll position will be set at the leftmost column. You can change it:

```
    SCROLL_SET p
```

will set the scroll position to column p (in tiles).

You can program an automatic scroll which doesn't interrupt execution with:

``` 
    SCROLL_TO x, v
```

Which will scroll from the current position to column x (in tiles), v pixels per frame (if v <= 32) or 1/(v-32) pixels per frame if v > 32. For example, 33 means 1/2 pixel per frame, or two frames to scroll one pixel, 34 means 1/3 pixel per frame, or three frames to scroll one pixel, and so on. There's 50 frames per second in PAL and 60 frames per second in NTSC.

Works exactly as IMAGE N but for 512xHeight pixels images.

```
    CUT_LOAD N, M
```

Loads image #M in cut #N. There are up to 8 cuts. Think of "stickers" you can put on screen afterwards. The patterns cuts use are loaded after the patterns used in the background. Note that there's a maximum of ~1500 patterns in total.

Once images are assigned to cuts, you can paint them using:

```
    CUT_SHOW N, X, Y
```

Which shows cut #N at (X, Y). This can be done at any time, for example as a response to a user input.

Cuts are not sprites: they actually substitute the patterns in the background layer. If you want to paint the cuts in the foreground layer, you can use this command instead:

```
    CUT_OVL N, X, Y
```

But be careful, as the UI is displayed in the foreground layer and you may overwrite it!

If you want to delete all the cuts you have stuck to the background, just call

```
    RESTORE_BG
```

You can activate a silly transition when displaying images:

```
    FANCY ON
```

Or turn it off.

```
    FANCY OFF
```

Displaying text
---------------

The text window may be captioned, or not. Captions are used to tell which character is speaking. To remove any captions in the text window, use:

```
    TALK OFF
```
    
To activate a caption (with the name of the character speaking), use:

```
    TALK "NAME"
```

And "NAME" will be used as a caption. In the text window.

To display text in the text window (with automatic word wrapping), use:

```
    TEXT "PLEASE, SHOW THIS TEXT, BUDDY!"
```

To wait until the player hits a button to continue, issue an:

```
    WT
```

As most of the time you'll be using TEXT "BLAH BLAH" and then WT, I added a command which combines both: prints text, then waits for user input.

```
    TW "PLEASE, SHOW THIS TEXT, AND THEN WAIT UNTIL A BUTTON IS PRESSED!"
```

To clear the text window...

```
    CLEARTEXT
```

Creating a menu
---------------

Menues are created adding options. Options can be edited, modified, and deleted in runtime. First of all, clear the existing options:

```
    CLEAR_MENU
```

Then you may add options sequentially:

```
    ADD_ITEM "XXXXXXXXXX"
```

Use an ADD_ITEM command for each option you need. Note that options must be under 10 characters in length!

To add a menu option to a specified position (this is useful to change an existing menu entry after a condition is fullfilled, for example), use this syntax instead:

```
    ADD_ITEM "XXXXXXXXXX", N
```
    
Where N is the position. Note that if N > number of defined active options, the behaviour is UNDEFINED. Options are numbered from 1 onwards. 

You can also add an option sequentially, but store the option number in a flag. To do so, use this syntax:

```
    ADD_ITEM "XXXXXXXXXX" -> F
```

Where F is the # of the flag. This can be useful if you plan to modify the option later on.

Once your menu is completely defined, make it work:

```
    DO_MENU
```
    
This command will show the menu as defined, wait for user input, let the user select an option, and write the selected option to flag #0. If the user cancels, it writes a 0.

Once the menu option is written to flag #0, you can do some checks and take some action.

Flags
-----

There are 128 flags (from 0 to 127) you can use to describe the game state. Flags 0 and 127 are somewhat reserved, as flag 0 will be overwritten each time you run a menu, and flag 127 is used to receive a value from `menu.bex`.

To assign a value to a flag:

```
    LET A = B
```

Will assign value "B" to flag number A. B may be an integer literal, or another flag. Flags are specified prepending a #. For example, to asign flag 1 the value of flag 2, you can do:

```
    LET 1 = #2
```

You can use aliases. Aliases are assigned an actual flag number in compile time. Aliases are defined the first time they are used in a LET command:

```
    LET $MY_IMPORTANT_VALUE = 7
```

Note that you can do this:

```
    LET $ONE_VALUE = 2
    LET $COPIED_VALUE = #$ONE_VALUE
```

Note how you still have to use # when dereferencing a flag number, as $XXXX are just aliases to numbers.

Maths with flags
----------------

Nothing very fancy:

```
    INC n
```

Increments flag #n

```
    DEC n
```

Decrements flag #n.

Note that you don't use # here to dereference (flag numbers are expected). Remember you can use aliases. And beware:

```
    DEC #6
```

Will not decrement flag 6, but the flag whose number is stored in flag 6.


Conditionals & branching
------------------------

Branching is based upon the use of markers or labels in the code. Such labels are plan strings starting with ":", for example:

```
:THIS_LABEL
```

You can perform simple checks on flags. If the condition is fulfilled, the interpreter will jump to the specified label in the code. Note that you mustn't include the ":"

```
    IF A = B LABEL
    IF A <> B LABEL
    IF A < B LABEL
    IF A > B LABEL
```

Where A and B can be literals or flags. For example, to check if the player chose option #1 in the menu, one would usually do:

```
    IF #0 = 1 OPTION_1
```

which would make the interpreter jump to the label defined as :OPTION_1 if the user selected the first menu item.

Of course, you can use aliases. Again, don't forget the #:

```
    IF #$GOT_KEY = 1 LABEL_2
    IF #$PLAYER_CHOICE < #$COMPUTER_CHOICE LABEL_3
```

To jump unconditionally, just

```
    GOTO LABEL
```

While developing the first (unreleased) adventure with VANE I noticed that coding menus and branching upon user input got tedious very soon. That's why I added the AUTOBRANCH option. Menus always return a value in the range 1..N, with N the total number of options. Adding this to your script:

```
    AUTO_BRANCH PREFIX N
```

equals to writing a list of N IFs:

```
    IF #0 = 1 PREFIX_1
    IF #0 = 2 PREFIX_2
    ...
    IF #0 = N PREFIX_N
```

which is quite handy.

Audio CD
--------

Pretty straightforward:

```
    CDPLAY n
```

Plays track N in loop. Note that first audio track is 2.

Samples
-------

If you added a sample cluster, you have a small memory pool for samples. Not very big. That's why you have to select which samples from the cluster you need and load them in runtime. There are 16 slots for samples, but being able to use all 16 slots depends on the samples being rather small. First of all, clear the pool:

```
    CLEAR_SAMPLES
```

Then you can add a sample from the cluster. Samples are indexes in your cluster. You used a list of samples in a txt file. The order is the same. 0 is the first sample in the cluster.

```
    ADD_SAMPLE idx
```

Slots are filled sequentially. Once you have filled some slots, you can play the sounds whenever you like:

```
    PLAY_SAMPLE n
```

Plays sample at slot n. Slots are numbered 0..15

Jumping to another chapter
--------------------------

Load & Run another chapter with

```
    CHAPTER N
```

Where N is the chapter number, or the text "NEXT", "PREV" or "REPEAT" to load next chapter in the list, the previous one, or to repeat the current chapter from the beginning.

External programs
-----------------

This hasn't been tested yet, but it should work. Or not, who knows. Remember you have 32 slots for subprograms written in pure BEX. The first five slots are fixed, but from slot #5 onwards you can configure additional subprogram clusters. Usually you do this via POKEs in `main.bex`,  but the contents of such slots can be changed at runtime (in case you need it):

``` 
    SET n = a
```

What `SET n = a` does is, in fact, POKE the value a to $FFFF00 + n, so you can use this to modify the engine configuration memory area as well, with n = $20 onwards. Check `memory_map.md`.

Will set slot n (0..31) to point to cluster a.

To run the subprogram at slot n from your script, do this:

```
    RUN_SLOT n
```

Your subprogram should end by running `VANE.bex`. You can use this BEX code to do it:

```
    ' Load VANE.SCD
    loadscd Peek(&HFFFF01)
```

VANE should resume executing your script from the next command after `RUN_SLOT`.

Comments
--------

Make the compiler ignore the rest of the line using # and a space.

```
    # This is a comment.
```

