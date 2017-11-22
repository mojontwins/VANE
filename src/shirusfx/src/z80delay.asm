;different delays
;be aware about registers usage when reuse this code



;delay for 9t

    MACRO delay9t
    ld a,r          ;9t
    ENDM
 
;delay for 10t

    MACRO delay10t
    ld de,0         ;10t
    ENDM
 
;delay for 15t

    MACRO delay15t
    or 0            ;7
    nop             ;4
    nop             ;4=15t
    ENDM
 
;delay for 18t

    MACRO delay18t
    ld ix,0         ;14
    nop             ;4=18t
    ENDM
 
;delay for 20t

    MACRO delay20t
    bit 0,(ix)      ;20
    ENDM

;delay for 36t

    MACRO delay36t
    bit 0,(ix)      ;20
    ld bc,0         ;10
    inc bc          ;6=36t
    ENDM
 
;delay for 44t

    MACRO delay44t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    nop             ;4=44t
    ENDM
 
;delay for 47t

    MACRO delay47t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    or 0            ;7=47t
    ENDM
 
;delay for 55t

    MACRO delay55t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    or 0            ;7
    nop             ;4
    nop             ;4=55t
    ENDM

;delay for 58t

    MACRO delay58t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    ld bc,0         ;10
    nop             ;4
    nop             ;4=58t
    ENDM

;delay for 67t

    MACRO delay67t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    ld c,0          ;7=67t
    ENDM
 
;delay for 68t

    MACRO delay68t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    nop             ;4
    nop             ;4=68t
    ENDM
 
;delay for 71t

    MACRO delay71t
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    bit 0,(ix)      ;20
    ld b,0          ;7
    nop             ;4=71t
    ENDM
 
;delay for 79t

    MACRO delay79t
    ld b,4          ;7
    dec b           ;4
    jp nz,$-1       ;10
    nop             ;4
    nop             ;4
    nop             ;4
    nop             ;4=79t
    ENDM
 
;delay for 83t

    MACRO delay83t
    ld c,5          ;7
    dec b           ;4
    jp nz,$-1       ;10
    inc bc          ;6=83t
    ENDM
 
;delay for 85t

    MACRO delay85t
    ld de,4         ;10
    dec e           ;4
    jp nz,$-1       ;10
    ld e,0          ;7
    nop             ;4
    nop             ;4
    nop             ;4=85t
    ENDM
 
;delay for 102t

    MACRO delay102t
    ld bc,6         ;10
    dec c           ;4
    jp nz,$-1       ;10
    nop             ;4
    nop             ;4=102t
    ENDM

;delay for 110t

    MACRO delay110t
    ld bc,6         ;10
    dec c           ;4
    jp nz,$-1       ;10
    ld bc,0         ;10
    inc bc          ;6=110t
    ENDM
 
;delay for 111t

    MACRO delay111t
    ld d,7          ;7
    dec d           ;4
    jp nz,$-1       ;10
    inc de          ;6=111t
    ENDM
 
;delay for 123t

    MACRO delay123t
    ld bc,7         ;10
    dec c           ;4
    jp nz,$-1       ;10
    ld c,0          ;7
    nop             ;4
    nop             ;4=123t
    ENDM

;delay for 114t

    MACRO delay114t
    ld bc,7         ;10
    dec c           ;4
    jp nz,$-1       ;10
    inc bc          ;6=114t
    ENDM
 
;delay for 127t

    MACRO delay127t
    ld bc,7         ;10
    dec c           ;4
    jp nz,$-1       ;10
    ld c,0          ;7
    nop             ;4
    nop             ;4
    nop             ;4=127t
    ENDM

;delay for 181t

    MACRO delay181t
    ld c,12         ;7
    dec c           ;4
    jp nz,$-1       ;10
    inc bc          ;6=181t
    ENDM
 
;delay for 191t

    MACRO delay191t
    ld c,12         ;7
    dec c           ;4
    jp nz,$-1       ;10
    ld hl,(0)       ;16=191t
    ENDM
 
;delay for 248t

    MACRO delay248t
    ld bc,17        ;10
    dec c           ;4
    jp nz,$-1       ;10=248t
    ENDM