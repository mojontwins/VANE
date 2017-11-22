;main M68K code taken from 'ASCII text demo' by Lewis AS Bassett
;www.sega-devega.net
;and some code from some other resources
;driver loading code partially taken from MVSTracker MD z80 driver

;04.05.07 debug version


    cpu 68000
    PADDING ON
    SUPMODE ON

    SECTION CODE


Z80_BUSREQ  equ $a11100
Z80_RESET   equ $a11200


    include "asasm/lib/Header.asm"



    ;load driver to Z80 RAM

    move.w  #$100,Z80_BUSREQ    ;busreq on
    move.w  #$100,Z80_RESET     ;reset off

    lea     $000000,a0
    lea     $a00000,a1
    move.l #8192,d0
copyLoop0:
    move.b  (a0)+,(a1)+
    subq.w  #1,d0
    bne copyLoop0
    
    lea     DriverZ80,a0        ;copy Z80 driver to Z80 RAM
    lea     $a00000,a1
    move.l  #DriverZ80end,d0
    move.l  #DriverZ80,d1
    sub.l   d1,d0
copyLoop:
    move.b  (a0)+,(a1)+
    subq.w  #1,d0
    bne copyLoop

    move.l #SoundEmpty,d0       ;store bank and offset of empty buffer
    lea $a01ff0,a0
    lsr.l #8,d0
    move.l d0,d1
    lsr.l #7,d1
    move.b d1,(a0)+             ;bank number
    or.l #$80,d0
    move.b d0,(a0)+             ;bank offset (msb)

    move.w  #$0,Z80_RESET       ;reset on
    move.w  #$0,Z80_BUSREQ      ;busreq off
    move.w  #$100,Z80_RESET     ;reset off
 

 
 
SetupVDP:
	move.w #$8016,$c00004
	move.w #$8174,$c00004
	move.w #$8338,$c00004
	move.w #$8406,$c00004
	move.w #$8600,$c00004
	move.w #$8700,$c00004
	move.w #$8801,$c00004
	move.w #$8901,$c00004
	move.w #$8a00,$c00004
	move.w #$8b02,$c00004
	move.w #$8d2f,$c00004
	move.w #$9100,$c00004
	move.w #$92ff,$c00004
	
    move.w  #$8238,     $c00004;    set plane a to $E000;
    move.w  #$8407,     $c00004;    set plane b to $E000;
    move.w  #$8560,     $c00004;    sprite table begins at $c000
    move.w  #$8c00,     $c00004;    Screen is 32x28 cells
    move.w  #$8f02,     $c00004;    set VDP increment register to increment one
                               ;    word after each write
    move.w  #$9000,     $c00004;    Plane A/B are 32x32 cells


SetPallette:
    move.l  #$c0000000, $c00004;    point the VDP control port to CRAM (Colour
                               ;    Pallette)
    lea Colours(pc),    a4;
    move.w  #1,     d0;


LoadColours:
    move.w  (a4)+,      $c00000;
    dbra    d0,         LoadColours;

    bra LoadASCII;


Colours:
    dc.w    $0000;
    dc.w    $0fff;


LoadASCII:
    move.w  #$8f02,     $c00004;    reset increment register
    move.l  #$40000000, $c00004;    point control port to VRAM
    lea CharSet(pc),    a4;
    move.w  #$400,      d0;


LoadCharSet:
    move.w  (a4)+,      $c00000;
    dbra    d0,     LoadCharSet;

    bra PrintMessage;


CharSet:
    binclude    "Font.dat";


PrintMessage:
    move.l  #$60000003,     $c00004;    point to VRAM $E000
    lea Message(pc),    a4;
    move.w  #$380,      d0;     move 32*28 chars, to fill whole screen!
    clr.w   d1;


DisplayMessage:
    move.b  (a4)+,      d1;
    sub.b   #$20,       d1;
    move.w  d1,     $c00000;
    dbra    d0,     DisplayMessage;

    move.w  #$8004,     $c00004
    move.w  #$8164,     $c00004



    bsr JoypadInit

keyLoop:
    bsr JoypadRead

    btst #6,d0          ; key A
    bne keyA
    btst #4,d0          ; key B
    bne keyB
    btst #5,d0          ; key C
    bne keyC
    btst #7,d0          ; key Start
    bne keyS

	bsr ShowZ80
	
    move.l #$8000,d2
waitLoop1:
    subq.w  #1,d2
    bne waitLoop1
    
    bra keyLoop


keyA:
    move.l #Sound0Start,d0
    move.l #Sound0End,d1
    bra PlaySample
keyB:
    move.l #Sound1Start,d0
    move.l #Sound1End,d1
    bra PlaySample
keyC:
    move.l #Sound2Start,d0
    move.l #Sound2End,d1
    bra PlaySample
keyS:
    move.l #Sound3Start,d0
    move.l #Sound3End,d1
    ;bra PlaySample
 
 
 
PlaySample:
    sub.l d0,d1
    
    
    lea MsgWaitReady(pc),a4
    move.w #$20,d2
    bsr ShowStr
 
    
    ;wait until sample player will be ready
waitPlayer:
	bsr ShowZ80
	
    move.w  #$100,Z80_BUSREQ    ;busreq on
    lea $a01ff0,a0
    move.b (a0),d2
    move.w  #$0,Z80_BUSREQ      ;busreq off
    
    cmp.b #$00,d2
    beq waitEnd
 
    move.l #$10000,d2
waitLoop:
    subq.w  #1,d2
    bne waitLoop

    bra waitPlayer
 
waitEnd:

    lea MsgSendParam(pc),a4
    move.w #$20,d2
    bsr ShowStr
    
    move.w  #$100,Z80_BUSREQ    ;busreq on

    lea $a01ff1,a0              ;store sample parameters in main RAM
    lsr.l #8,d0
    move.l d0,d2
    lsr.l #7,d2
    move.b d2,(a0)+             ;bank number
    or.l #$80,d0
    move.b d0,(a0)+             ;bank offset (msb)
    lsr.l #8,d1
    move.b d1,(a0)+             ;sample length (lsb)
    lsr.l #8,d1
    move.b d1,(a0)+             ;sample length (msb)

    lea $a01ff0,a0              ;set 'new sample' flag
    move.b #$ff,d0
    move.b d0,(a0)+

    move.w  #$0,Z80_BUSREQ      ;busreq off
 

    lea MsgWaitSome(pc),a4
    move.w #$20,d2
    bsr ShowStr
    
    ;wait some more time to prevent call sounds too frequently (for this demo)

    move.l #$200000,d2
waitLoop0:
    subq.w  #1,d2
    bne waitLoop0


    lea MsgEmpty(pc),a4
    move.w #$20,d2
    bsr ShowStr
    
    
    bra keyLoop



JoypadInit:
    moveq #$40,d0
    move.b d0,$a10009
    move.b d0,$a1000b
    move.b d0,$a1000d
    rts


JoypadRead:
    move.b #$40,$a10003
    nop
    nop
    move.b $a10003,d1
    andi.b #$3f,d1
    move.b #$00,$a10003
    nop
    nop
    move.b $a10003,d0
    andi.b #$30,d0
    lsl.b #2,d0
    or.b  d1,d0
    not.b d0
    rts
 


ShowStr:
	sub.w #$02,d2
    move.l #$66420003,$c00004
    clr.w d3
    
ShowStr0:
    move.b (a4)+,d3
    sub.b #$20,d3
    move.w d3,$c00000
    dbra d2,ShowStr0
    rts
    
    
    
ShowZ80
	move.w  #$100,Z80_BUSREQ    ;busreq on
	lea $a01fe0,a0
    move.b (a0)+,d4
	move.w  #$0,Z80_BUSREQ      ;busreq off
	move.l #$66020003,$c00004
	sub.b #$20,d4
	move.w d4,$c00000
	rts
	
	
    
Interrupt:
    rte

VBL:
    rte

HBL:
    rte




Message:
;         01234567890123456789012345678901
    dc.b "                                "; 0
    dc.b "                                "; 1
    dc.b " 4-CHANNEL DIGITAL SOUND PLAYER "; 2
    dc.b "                                "; 3
    dc.b " BY SHIRU                       "; 4
    dc.b "                                "; 5
    dc.b "                                "; 6
    dc.b " USE START AND A,B,C KEYS       "; 7
    dc.b "                                "; 8
    dc.b "                                "; 9
    dc.b "                                "; 0
    dc.b "                                "; 1
    dc.b "                                "; 2
    dc.b "                                "; 3
    dc.b "                                "; 4
    dc.b "                                "; 5
    dc.b "                                "; 6
    dc.b "                                "; 7
    dc.b "                                "; 8
    dc.b "                                "; 9
    dc.b "                                "; 0
    dc.b "                                "; 1
    dc.b "                                "; 2
    dc.b "                                "; 3
    dc.b "                                "; 4
    dc.b "                                "; 5
    dc.b "                                "; 6
    dc.b "                                "; 7



MsgEmpty
	dc.b "                                "
MsgWaitReady
	dc.b "WAIT FOR Z80                    "
MsgSendParam
	dc.b "SENDING PARAMS                  "
MsgWaitSome
	dc.b "WAIT AFTER NEW SAMPLE           "    
    
    
    
    ALIGN 256               ;samples must be 256-byte aligned!

SoundEmpty:
    binclude "empty.bin"    ;empty buffer for silence channels

Sound0Start:
    binclude "sound1.raw"
Sound0End:

Sound1Start:
    binclude "sound2.raw"
Sound1End:

Sound2Start:
    binclude "sound3.raw"
Sound2End:

Sound3Start:
    binclude "loop.raw"
Sound3End:



DriverZ80:
    binclude "z80dsnd.bin";
DriverZ80end:




    org $20000-2;
    dc.w $ffff;

ROMEnd:

    ENDSECTION
