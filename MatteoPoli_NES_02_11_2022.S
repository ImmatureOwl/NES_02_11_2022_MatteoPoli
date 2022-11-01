.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.org $8000

.define PPUCTRL $2000
.define PPUMASK $2001
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014

.define JOYPAD1 $4016
.define JOYPAD2 $4017

.define SCROLL_X $00
.define buttons $01
.define SCROLL_Y $02
.define counter $03
.define bgStartAddr $04
.define bgIndex $05
.define bgNextLine $06
.define bgRows $07
.define posX $08
.define posY $09

start:

    ;set variables
    LDA #%10010000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK

    LDA #$00
    STA bgIndex
    LDA #$0F
    STA bgRows
    LDA #$22
    STA posX
    LDA #0
    STA posY
    
    ; load background palette
    LDA #$3f
    STA PPUADDR
    LDA #0
    STA PPUADDR

    LDA #$0F
    STA PPUDATA
    LDA #$05
    STA PPUDATA
    LDA #$28
    STA PPUDATA
    LDA #$2D
    STA PPUDATA

    ; load first sprite palette
    LDA #$3f
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    LDA #$0F
    STA PPUDATA
    LDA #$22
    STA PPUDATA
    LDA #$23
    STA PPUDATA
    LDA #$24
    STA PPUDATA

    ; load second sprite palette
    LDA #$16
    STA PPUDATA
    LDA #$17
    STA PPUDATA
    LDA #$18
    STA PPUDATA
    LDA #$19
    STA PPUDATA

    ; load background tiles
    LDA #$21
    STA PPUADDR
    LDA #$50
    STA PPUADDR
    STA bgStartAddr
    bgLoop:
        LDA #$0F
        STA bgNextLine

        bgRowLoop:
            LDA bgIndex
            STA PPUDATA
            INC bgIndex
            DEC bgNextLine
            LDA bgNextLine
            BNE bgRowLoop
        ;end rowLoop

        LDA #$21
        STA PPUADDR
        LDA bgStartAddr
        ADC #$20
        STA bgStartAddr
        STA PPUADDR
        DEC bgRows
        LDA bgRows
        BNE bgLoop
    ;end loop

    ;load objs
    LDA #$00
    STA OAMADDR
    LDA posY
    STA OAMDATA
    LDA #$21
    STA OAMDATA
    LDA #%00000001
    STA OAMDATA
    LDA posX
    STA OAMDATA

loop:
    JMP loop
;end loop
    
; At the same time that we strobe bit 0, we initialize the ring counter
; so we're hitting two birds with one stone here
readjoy:
    LDA #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD1 will only return the state of the
    ; first button: button A.
    STA JOYPAD1
    STA buttons
    LSR a        ; now A is 0
    ; By storing 0 into JOYPAD1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD1.
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR a	       ; bit 0 -> Carry
    ROL buttons  ; Carry -> bit 0; bit 7 -> Carry
    BCC joyloop
RTS

nmi:
    PHA
    JSR readjoy
    PLA
    ;readUp
        LDA buttons
        AND #%00001000
        BEQ readDown
        ;up pressed
        LDA #00
        STA OAMADDR
        LDA posY
        CMP #02
        BCC readDown
        DEC posY
        LDA posY
        STA OAMDATA
    readDown:
        LDA buttons 
        AND #%00000100
        BEQ readLeft
        ;down pressed
        LDA #00
        STA OAMADDR
        LDA posY
        CMP #$E8
        BCS readLeft
        INC posY
        LDA posY
        STA OAMDATA
    readLeft:
        LDA buttons
        AND #%00000010
        BEQ readRight
        ;left pressed
        LDA SCROLL_X
        CMP #01
        BCC sprLeft
        DEC SCROLL_X
        sprLeft:
            LDA #03
            STA OAMADDR
            LDA posX
            CMP #01
            BCC readRight
            DEC posX
            LDA posX
            STA OAMDATA
    readRight:
        LDA buttons
        AND #%00000001
        BEQ loadscroll
        ;right pressed
        LDA SCROLL_X
        CMP #$F8
        BCS sprRight
        INC SCROLL_X
        sprRight:
            LDA #03
            STA OAMADDR
            LDA posX
            CMP #$F8
            BCS loadscroll
            INC posX
            LDA posX
            STA OAMDATA

    loadscroll:
        LDA SCROLL_X
        STA PPUSCROLL
        LDA #0
        STA PPUSCROLL
        RTI
;end nmi

irq:
    RTI

.goto $FFFA

.dw nmi
.dw start
.dw irq

.incbin mario0.chr
.incbin aiv256.chr