
; this module handles audio generation.
; TODO: refactor this module to improve readability/maintainability

.include "apu.inc"

.export apu
.export beep
.export boop

.segment "RODATA"

rbaRegInit:
.byte $30,$08,$00,$00
.byte $30,$08,$00,$00
.byte $80,$00,$00,$00
.byte $30,$00,$00,$00
.byte $00,$00,$00,$00

.segment "CODE"

; initialize the APU
; changes: A, Y
.proc apu
    ; Init $4000-4013
    ldy #$13

loop:
    lda rbaRegInit, y
    sta $4000, y
    dey
    bpl loop

    ; We have to skip over $4014 (OAMDMA)
    lda #$0f
    sta Apu::STATUS
    lda #$40
    sta Apu::FRAME

    rts
.endproc


; make a short 900 Hz "beep" sound
; used for a POST beep on startup and the terminal receiving a BELL character.
; changes: A
.proc beep
    FREQUENCY = 900 ; Hz
    PERIOD = 1118608 / (FREQUENCY * 10) - 1
    DURATION = $0

    lda #<PERIOD
    sta $4002

    lda #>PERIOD | <(DURATION << 3)
    sta $4003

    lda #%10011111
    sta $4000

    rts
.endproc


; make a short 400 Hz "boop" sound
; used to indicate that a key was pressed on the on-screen keyboard.
; changes: A
.proc boop
    FREQUENCY = 400 ; Hz
    PERIOD = 1118608 / (FREQUENCY * 10) - 1
    DURATION = $0

    lda #<PERIOD
    sta $4002

    lda #>PERIOD | <(DURATION << 3)
    sta $4003

    lda #%10010100
    sta $4000

    rts
.endproc
