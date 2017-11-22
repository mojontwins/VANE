;------------------------------------------
; LOAD Z80 DRIVER
;------------------------------------------

LOADZ80:
    move.w  #$100,$a11100    ;busreq on
    move.w  #$100,$a11200     ;reset off

    lea     $000000,a0
    lea     $a00000,a1
    move.l  #8192,d0
copyLoop0:
    move.b  (a0)+,(a1)+
    subq.w  #1,d0
    bne     copyLoop0
    
    lea     DriverZ80,a0        ;copy Z80 driver to Z80 RAM
    lea     $a00000,a1
    move.l  #DriverZ80end,d0
    move.l  #DriverZ80,d1
    sub.l   d1,d0
copyLoop:
    move.b  (a0)+,(a1)+
    subq.w  #1,d0
    bne     copyLoop

    move.l  #SoundEmpty,d0       ;store bank and offset of empty buffer
    lea     $a01ff0,a0
    lsr.l   #8,d0
    move.l  d0,d1
    lsr.l   #7,d1
    move.b  d1,(a0)+             ;bank number
    or.l    #$80,d0
    move.b  d0,(a0)+             ;bank offset (msb)

    move.w  #$0,$a11200       ;reset on
    move.w  #$0,$a11100      ;busreq off
    move.w  #$100,$a11200     ;reset off
	rts
	
;------------------------------------------
; SAMPLE EXECUTE CALL
;------------------------------------------

Play_Sample2:
    move.l #Sound2Start,d0
    move.l #Sound2End,d1
    bra    PlaySample
	rts
	
;------------------------------------------
; PLAY SAMPLE ROUTINE
;------------------------------------------
 
PlaySample:
    sub.l d0,d1
    ;wait until sample player will be ready
waitPlayer:
    move.w  #$100,$a11100    ;busreq on
    lea $a01ff0,a0
    move.b (a0),d2
    move.w  #$0,$a11100      ;busreq off

;   cmp.b #$00,d2
;   beq   waitEnd
 
;   move.l #$10000,d2
;waitLoop:
;   subq.w  #1,d2
;   bne waitLoop
;   bra waitPlayer 
waitEnd:
    move.w  #$100,$a11100    ;busreq on
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
    move.w  #$0,$a11100        ;busreq off
    ;wait some more time to prevent call sounds too frequently (for this demo)
;    move.l #$200000,d2
;waitLoop0:
;    subq.w  #1,d2
;    bne waitLoop0
	rts

;------------------------------------------
; INCLUDED FILES
;------------------------------------------

    ALIGN 256                 ;samples must be 256-byte aligned!

SoundEmpty:
    incbin "sfx\blank.raw"    ;empty buffer for silence channels

Sound2Start:
    incbin "sfx\sound2.raw"
Sound2End:

DriverZ80:
    incbin "sfx\driver.bin"
DriverZ80end:
