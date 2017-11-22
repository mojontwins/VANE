;4ch digital player v1.1x
;6-bit samples with any length, 16000Hz
;by Shiru, 04.05.07 debug version


    ;DEFINE DEBUG
 
;sample output, occurs every 224t (3580000/16000, i.e. fCPU/fSampleRate)

    MACRO sampleOutput
    exx             ;4
    ld a,(hl)       ;7 read sample from play buffer
    ld (hl),e       ;7 clear play buffer
    ld (bc),a       ;7 play sample
    inc l           ;4 increment with looping
    exx             ;4=33t
    ENDM
 


;read next two bytes and mix with output buffer
;  SP=current position in sample
;  HL=current position in mix buffer

    MACRO readAndMix
    pop de      ;12 (because wait in ROM, not sure for exact time)
    ld a,e      ;4
    add a,(hl)  ;7
    ld (hl),a   ;7
    inc l       ;4
    ld a,d      ;4
    add a,(hl)  ;7
    ld (hl),a   ;7
    inc l       ;4=56t
    ENDM
 
 
 
;bankswitch, only 7 bits from 9 is used (enough for addressing 4MB ROM)

    MACRO bankSwitch
    ld hl,#6000 ;10
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    rra         ;4
    ld (hl),a   ;7
    ld (hl),l   ;7
    ld (hl),l   ;7=97t
    ENDM
 


    INCLUDE z80delay.asm
 
 
 
 
;------------------------------------------------------------------------------
;main code starts here
;------------------------------------------------------------------------------


    org #0000
 
    di
    ld sp,#1fff         ;used only in init, to call wrYmPortA
 
    ;setup variables
 
    ld hl,mixBuffer1
    ld (bufPlay),hl
    ld hl,mixBuffer0
    ld (bufWrite),hl
    ld ix,0             ;to be sure what delays with IX will work without wait
 
    ld a,(#1ff0)        ;get bank for empty buffer
    ld (emptyBank),a
    ld a,(#1ff1)        ;get offset for empty buffer
    ld b,a
    ld c,0
    ld (emptyOff),bc
 
    xor a
    ld (#1ff0),a        ;no new sound
 
    ;clear mix buffers
 
    ld de,mixBuffer0+1
    ld bc,511
    ld (hl),#80         ;#80 as empty
    ldir
 
    ;clear channel descriptors
 
    ld hl,chnList
    ld b,16
clearList
    ld (hl),a
    inc l
    djnz clearList

    ;ym2612 init
 
    ld de,#2b80     ;switch on DAC
    call wrYmPortA
    ld de,#2a80     ;first output to DAC, to make register selected
    call wrYmPortA
 
    ;load alternative registers set
 
    exx
    ld bc,#4001     ;ym2612 data port
    ld e,#80        ;for buffer clearing
    ld hl,(bufPlay)
    exx

    IFDEF DEBUG
    ld a,'.'
    ld (#1fe0),a
    ENDIF
 
mainLoop

;samplecount:

    IFDEF DEBUG
    ld a,'0'
    ld (#1fe0),a
    ENDIF
 
    ;process channel #0
;0
    ;set SP to offset, while playing 1 sample
    sampleOutput        ;33t
    ld hl,(chnList+2)   ;16
    ld a,h              ;4
    or l                ;4
    jp nz,ch0Setup      ;10
    ld sp,(emptyOff)    ;20-+-A
    ld a,(emptyBank)    ;13 |
    jp ch0SetOK         ;10-+
ch0Setup
    ld hl,chnList+0     ;10-+-B
    ld h,(hl)           ;7  |
    ld l,0              ;7  |
    ld sp,hl            ;6  |
    ld a,(chnList+1)    ;13-+
ch0SetOK
    ex af,af            ;4
    delay110t           ;=224t

    IFDEF DEBUG
    ld a,'1'
    ld (#1fe0),a
    ENDIF
 
;1
    ;select bank, while playing 1 sample
    sampleOutput        ;33t
    ex af,af            ;4
    bankSwitch          ;97t
    delay67t            ;67t
    ld hl,(bufWrite)    ;16
                        ;=224-7t, see below
 
    IFDEF DEBUG
    ld a,'2'
    ld (#1fe0),a
    ENDIF
 
;2
    ;read and mix 252 bytes, while playing 42 samples
    ld b,42             ;7 taken from ^^^
ch0Render
    sampleOutput        ;33t
    readAndMix
    readAndMix
    readAndMix          ;3*56=168t
    delay9t             ;9t
    dec b               ;4
    jp nz,ch0Render     ;10
                        ;=224t
 
    IFDEF DEBUG
    ld a,'3'
    ld (#1fe0),a
    ENDIF
 
;44
    ;read and mix last 4 bytes, while playing 1 sample
    sampleOutput        ;33t
    readAndMix
    readAndMix          ;2*56=112t
    delay79t            ;=224t
 
    IFDEF DEBUG
    ld a,'4'
    ld (#1fe0),a
    ENDIF
 
;45
    ;update sample position and check for sample end, while playing 1 sample
    sampleOutput        ;33t
 
    ld hl,chnList       ;10
    inc (hl)            ;11
    ld a,(hl)           ;7
    inc hl              ;6
    or a                ;4
    jp nz,ch0BankNoInc  ;10
    ld a,#80            ;7 -+-A
    inc (hl)            ;11 |
    jp ch0OffsetWr      ;10-+
ch0BankNoInc
    ld b,0              ;7 -+-B
    ld b,0              ;7  |
    ld b,b              ;4  |
    jp $+3              ;10-+
ch0OffsetWr
    dec hl              ;6
    ld (hl),a           ;7
    ld hl,(chnList+2)   ;16
    ld a,h              ;4
    or l                ;4
    jp z,ch0LenNoInc    ;10
    dec hl              ;6 -+-A
    jp ch0LenWr         ;10-+
ch0LenNoInc
    dec bc              ;6 -+-B
    jp $+3              ;10-+
ch0LenWr
    ld (chnList+2),hl   ;16
    delay36t            ;=224t

    IFDEF DEBUG
    ld a,'5'
    ld (#1fe0),a
    ENDIF

    ;process channel #1
;46
    ;set SP to offset, while playing 1 sample
    sampleOutput        ;33t
    ld hl,(chnList+6)   ;16
    ld a,h              ;4
    or l                ;4
    jp nz,ch1Setup      ;10
    ld sp,(emptyOff)    ;20-+-A
    ld a,(emptyBank)    ;13 |
    jp ch1SetOK         ;10-+
ch1Setup
    ld hl,chnList+4     ;10-+-B
    ld h,(hl)           ;7  |
    ld l,0              ;7  |
    ld sp,hl            ;6  |
    ld a,(chnList+5)    ;13-+
ch1SetOK
    ex af,af            ;4
    delay110t           ;=224t

    IFDEF DEBUG
    ld a,'6'
    ld (#1fe0),a
    ENDIF
 
;47
    ;select bank, while playing 1 sample
    sampleOutput        ;33t
    ex af,af            ;4
    bankSwitch          ;97t
    delay67t            ;67t
    ld hl,(bufWrite)    ;16
                        ;=224-7t, see below
 
    IFDEF DEBUG
    ld a,'7'
    ld (#1fe0),a
    ENDIF
 
;48
    ;read and mix 252 bytes, while playing 42 samples
    ld b,42             ;7 taken from ^^^
ch1Render
    sampleOutput        ;33t
    readAndMix
    readAndMix
    readAndMix          ;3*56=168t
    delay9t             ;9t
    dec b               ;4
    jp nz,ch1Render     ;10
                        ;=224t
 
    IFDEF DEBUG
    ld a,'8'
    ld (#1fe0),a
    ENDIF
 
;90
    ;read and mix last 4 bytes, while playing 1 sample
    sampleOutput        ;33t
    readAndMix
    readAndMix          ;2*56=112t
    delay79t            ;=224t
 
    IFDEF DEBUG
    ld a,'9'
    ld (#1fe0),a
    ENDIF
 
;91
    ;update sample position and check for sample end, while playing 1 sample
    sampleOutput        ;33t
 
    ld hl,chnList+4     ;10
    inc (hl)            ;11
    ld a,(hl)           ;7
    inc hl              ;6
    or a                ;4
    jp nz,ch1BankNoInc  ;10
    ld a,#80            ;7 -+-A
    inc (hl)            ;11 |
    jp ch1OffsetWr      ;10-+
ch1BankNoInc
    ld b,0              ;7 -+-B
    ld b,0              ;7  |
    ld b,b              ;4  |
    jp $+3              ;10-+
ch1OffsetWr
    dec hl              ;6
    ld (hl),a           ;7
    ld hl,(chnList+6)   ;16
    ld a,h              ;4
    or l                ;4
    jp z,ch1LenNoInc    ;10
    dec hl              ;6 -+-A
    jp ch1LenWr         ;10-+
ch1LenNoInc
    dec bc              ;6 -+-B
    jp $+3              ;10-+
ch1LenWr
    ld (chnList+6),hl   ;16
    delay36t            ;=224t
 
 
    IFDEF DEBUG
    ld a,'A'
    ld (#1fe0),a
    ENDIF
 
    ;process channel #2
;92
    ;set SP to offset, while playing 1 sample
    sampleOutput        ;33t
    ld hl,(chnList+10)   ;16
    ld a,h              ;4
    or l                ;4
    jp nz,ch2Setup      ;10
    ld sp,(emptyOff)    ;20-+-A
    ld a,(emptyBank)    ;13 |
    jp ch2SetOK         ;10-+
ch2Setup
    ld hl,chnList+8     ;10-+-B
    ld h,(hl)           ;7  |
    ld l,0              ;7  |
    ld sp,hl            ;6  |
    ld a,(chnList+9)    ;13-+
ch2SetOK
    ex af,af            ;4
    delay110t           ;=224t

    IFDEF DEBUG
    ld a,'B'
    ld (#1fe0),a
    ENDIF

;93
    ;select bank, while playing 1 sample
    sampleOutput        ;33t
    ex af,af            ;4
    bankSwitch          ;97t
    delay67t            ;67t
    ld hl,(bufWrite)    ;16
                        ;=224-7t, see below
 
    IFDEF DEBUG
    ld a,'C'
    ld (#1fe0),a
    ENDIF
 
;94
    ;read and mix 252 bytes, while playing 42 samples
    ld b,42             ;7 taken from ^^^
ch2Render
    sampleOutput        ;33t
    readAndMix
    readAndMix
    readAndMix          ;3*56=168t
    delay9t             ;9t
    dec b               ;4
    jp nz,ch2Render     ;10
                        ;=224t
 
    IFDEF DEBUG
    ld a,'D'
    ld (#1fe0),a
    ENDIF
 
;136
    ;read and mix last 4 bytes, while playing 1 sample
    sampleOutput        ;33t
    readAndMix
    readAndMix          ;2*56=112t
    delay79t            ;=224t
 
    IFDEF DEBUG
    ld a,'E'
    ld (#1fe0),a
    ENDIF
 
;137
    ;update sample position and check for sample end, while playing 1 sample
    sampleOutput        ;33t
 
    ld hl,chnList+8     ;10
    inc (hl)            ;11
    ld a,(hl)           ;7
    inc hl              ;6
    or a                ;4
    jp nz,ch2BankNoInc  ;10
    ld a,#80            ;7 -+-A
    inc (hl)            ;11 |
    jp ch2OffsetWr      ;10-+
ch2BankNoInc
    ld b,0              ;7 -+-B
    ld b,0              ;7  |
    ld b,b              ;4  |
    jp $+3              ;10-+
ch2OffsetWr
    dec hl              ;6
    ld (hl),a           ;7
    ld hl,(chnList+10)   ;16
    ld a,h              ;4
    or l                ;4
    jp z,ch2LenNoInc    ;10
    dec hl              ;6 -+-A
    jp ch2LenWr         ;10-+
ch2LenNoInc
    dec bc              ;6 -+-B
    jp $+3              ;10-+
ch2LenWr
    ld (chnList+10),hl   ;16
    delay36t            ;=224t
 
    IFDEF DEBUG
    ld a,'F'
    ld (#1fe0),a
    ENDIF
 
    ;process channel #3
;138
    ;set SP to offset, while playing 1 sample
    sampleOutput        ;33t
    ld hl,(chnList+14)   ;16
    ld a,h              ;4
    or l                ;4
    jp nz,ch3Setup      ;10
    ld sp,(emptyOff)    ;20-+-A
    ld a,(emptyBank)    ;13 |
    jp ch3SetOK         ;10-+
ch3Setup
    ld hl,chnList+12    ;10-+-B
    ld h,(hl)           ;7  |
    ld l,0              ;7  |
    ld sp,hl            ;6  |
    ld a,(chnList+13)   ;13-+
ch3SetOK
    ex af,af            ;4
    delay110t           ;=224t

    IFDEF DEBUG
    ld a,'G'
    ld (#1fe0),a
    ENDIF
 
;139
    ;select bank, while playing 1 sample
    sampleOutput        ;33t
    ex af,af            ;4
    bankSwitch          ;97t
    delay67t            ;67t
    ld hl,(bufWrite)    ;16
                        ;=224-7t, see below
 
    IFDEF DEBUG
    ld a,'H'
    ld (#1fe0),a
    ENDIF
 
;140
    ;read and mix 252 bytes, while playing 42 samples
    ld b,42             ;7 taken from ^^^
ch3Render
    sampleOutput        ;33t
    readAndMix
    readAndMix
    readAndMix          ;3*56=168t
    delay9t             ;9t
    dec b               ;4
    jp nz,ch3Render     ;10
                        ;=224t
 
    IFDEF DEBUG
    ld a,'I'
    ld (#1fe0),a
    ENDIF
 
;182
    ;read and mix last 4 bytes, while playing 1 sample
    sampleOutput        ;33t
    readAndMix
    readAndMix          ;2*56=112t
    delay79t            ;=224t
 
    IFDEF DEBUG
    ld a,'J'
    ld (#1fe0),a
    ENDIF
 
;183
    ;update sample position and check for sample end, while playing 1 sample
    sampleOutput        ;33t
 
    ld hl,chnList+12    ;10
    inc (hl)            ;11
    ld a,(hl)           ;7
    inc hl              ;6
    or a                ;4
    jp nz,ch3BankNoInc  ;10
    ld a,#80            ;7 -+-A
    inc (hl)            ;11 |
    jp ch3OffsetWr      ;10-+
ch3BankNoInc
    ld b,0              ;7 -+-B
    ld b,0              ;7  |
    ld b,b              ;4  |
    jp $+3              ;10-+
ch3OffsetWr
    dec hl              ;6
    ld (hl),a           ;7
    ld hl,(chnList+14)  ;16
    ld a,h              ;4
    or l                ;4
    jp z,ch3LenNoInc    ;10
    dec hl              ;6 -+-A
    jp ch3LenWr         ;10-+
ch3LenNoInc
    dec bc              ;6 -+-B
    jp $+3              ;10-+
ch3LenWr
    ld (chnList+14),hl  ;16
    delay36t            ;=224t
 
 
    IFDEF DEBUG
    ld a,'K'
    ld (#1fe0),a
    ENDIF
 
;184
    ;play all other samples-3 without work in background
    ;so there is some free time
    REPT 68
    sampleOutput        ;33t
    delay191t           ;191t
    ENDM                ;=224t
 
    IFDEF DEBUG
    ld a,'L'
    ld (#1fe0),a
    ENDIF
 
;252
    ;switch buffers and check for new sound while playing 1 sample
    sampleOutput        ;33t

    ld hl,(bufWrite)    ;16
    ld de,(bufPlay)     ;20
    ld (bufWrite),de    ;20
    ld (bufPlay),hl     ;16
    exx                 ;4
    ld hl,(bufPlay)     ;16
    exx                 ;4=96
 
    delay68t            ;68t
 
    ld a,(#1ff0)        ;13
    or a                ;4
    jp z,noNewSample    ;10
 
    IFDEF DEBUG
    ld a,'M'
    ld (#1fe0),a
    ENDIF
 
;253
    ;search new channel and write parameters while playing 3 samples
    sampleOutput        ;33t
 
    ld hl,(chnList+2)   ;16
    ld de,(chnList+6)   ;20
    ld bc,chnList       ;10
    ld a,h              ;4
    cp d                ;4
    jp c,selCh0ls0      ;10
    ld a,l              ;4 -+-A0
    cp e                ;4 -+
    jp c,selCh0ls1      ;10
    ld bc,chnList+4     ;10-+-A1
    ex de,hl            ;4  |
    jp selCh2Check      ;10-+
selCh0ls0
    nop                 ;4 -+-B0
    nop                 ;4 -+
selCh0ls1
    nop                 ;4 -+-B1
    jp $+3              ;10 |
    jp $+3              ;10-+
 
    delay85t            ;33+106+85=224t
 
    IFDEF DEBUG
    ld a,'N'
    ld (#1fe0),a
    ENDIF
 
;254
    sampleOutput        ;33t
 
selCh2Check
    ld de,(chnList+10)  ;20
    ld a,h              ;4
    cp d                ;4
    jp c,selCh2ls0      ;10
    ld a,l              ;4 -+-A0
    cp e                ;4 -+
    jp c,selCh2ls1      ;10
    ld bc,chnList+8     ;10-+-A1
    ex de,hl            ;4  |
    jp selCh3Check      ;10-+
selCh2ls0
    nop                 ;4 -+-B0
    nop                 ;4 -+
selCh2ls1
    nop                 ;4 -+-B1
    jp $+3              ;10 |
    jp $+3              ;10-+

    delay111t           ;33+80+111=224t
 
    IFDEF DEBUG
    ld a,'O'
    ld (#1fe0),a
    ENDIF
 
;255
    sampleOutput        ;33t
 
selCh3Check
    ld de,(chnList+14)  ;20
    ld a,h              ;4
    cp d                ;4
    jp c,selCh3ls0      ;10
    ld a,l              ;4 -+-A0
    cp e                ;4 -+
    jp c,selCh3ls1      ;10
    ld bc,chnList+12    ;10-+-A1
    ex de,hl            ;4  |
    jp selCheckOK       ;10-+
selCh3ls0
    nop                 ;4 -+-B0
    nop                 ;4 -+
selCh3ls1
    nop                 ;4 -+-B1
    jp $+3              ;10 |
    jp $+3              ;10-+
                        ;=80t
 
    IFDEF DEBUG
    ld a,'P'
    ld (#1fe0),a
    ENDIF
 
selCheckOK
    ld h,b              ;4
    ld l,c              ;4
    ld a,(#1ff2)        ;13 bank offset
    ld (hl),a           ;7
    inc hl              ;6
    ld a,(#1ff1)        ;13 bank number
    ld (hl),a           ;7
    inc hl              ;6
    ld bc,(#1ff3)       ;13 sample length (in 256-byte blocks)
    ld (hl),c           ;7
    inc hl              ;6
    ld (hl),b           ;7
    xor a               ;4
    ld (#1ff0),a        ;13 acknowledge new sound
 
    delay9t             ;9t
 
    IFDEF DEBUG
    ld a,'Q'
    ld (#1fe0),a
    ENDIF
 
    jp mainLoop         ;10



noNewSample

;253
    IFDEF DEBUG
    ld a,'R'
    ld (#1fe0),a
    ENDIF
 
    ;no new sound, just play 3 samples
    sampleOutput        ;33t
    delay191t           ;191t
 
    IFDEF DEBUG
    ld a,'S'
    ld (#1fe0),a
    ENDIF
 
;254
    sampleOutput        ;33t
    delay191t           ;191t
 
    IFDEF DEBUG
    ld a,'T'
    ld (#1fe0),a
    ENDIF
 
;255
    sampleOutput        ;33t
    delay181t           ;181t
 
    IFDEF DEBUG
    ld a,'U'
    ld (#1fe0),a
    ENDIF
 
    jp mainLoop         ;10t
 



 
;write word to YM2612 port A

wrYmPortA
    ld hl,#4000
.wait0
    bit 7,(hl)
    jr nz,.wait0
    ld (hl),d
.wait1
    bit 7,(hl)
    jr nz,.wait1
    inc l
    ld (hl),e
    ret
 
 
 
;variables
 
emptyBank   DB 0    ;ROM bank where empty buffer is placed
emptyOff    DW 0    ;offset of empty buffer

bufWrite    DW 0    ;addr. of buffer for mix (256-byte aligned)
bufPlay     DW 0    ;addr. of buffer for play (256-byte aligned)

chnList     DB 4*4  ;+0     byte    offset in bank (MSB only)
                    ;+1     byte    bank number (0..127)
                    ;+2     word    length in 256-byte blocks
                    ;               channel is free when length=0
 

 

    org ($/256+1)*256   ;256-byte align
 
mixBuffer0  DS 256
mixBuffer1  DS 256