
; this module uses a scanline interrupt to change the screen scroll position
; after the on-screen keyboard has been displayed.
; see also: keyboard/on_screen.s

.include "const.inc"
.include "irq.inc"
.include "keyboard/on_screen.inc"
.include "mmc5.inc"
.include "ppu.inc"
.include "terminal.inc"

.export irq

.segment "ZEROPAGE"

zbTemp: .res 1

.segment "LOWCODE"

; global IRQ handler.
; exclusively used by the on-screen keyboard.
; this function alters the screen scroll position in the middle of a frame.
; that requires careful modification of the state of the PPU.
; see nesdev.org for more details.
; https://www.nesdev.org/wiki/PPU_scrolling#Split_X/Y_scroll
.proc irq
    ; save CPU state
    pha ; save A register
    txa
    pha ; save X register
    tya
    pha ; save Y register

    clc
    lda Ppu::zbScrollPixelY
    adc #OnScreen::KEYBOARD_HEIGHT

    bcs adjust
    cmp #Const::SCREEN_PIXEL_HEIGHT
    bcc continue
adjust:
    sbc #Const::SCREEN_PIXEL_HEIGHT
continue:

    tay
    and #%11111000
    asl
    asl
    sta zbTemp

    lda Ppu::zbScrollPixelX
    lsr
    lsr
    lsr
    ora zbTemp
    sta zbTemp

    ; yyy NN YYYYY XXXXX
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll

    ; reset w to 0
    lda Ppu::STATUS

    ; ### ## ##YYY XXXXX
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll

    ; write nametable number << 2
    ldx #$00
    stx Ppu::ADDR

    ; ### NN ##### XXXXX
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll
    sty Ppu::SCROLL

    nop
    lda zbTemp

    ; yyy NN YYYYY #####
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll

    ldx Ppu::zbScrollPixelX
    stx Ppu::SCROLL

    ; yyy NN YY### #####
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll

    sta Ppu::ADDR

    ; clear the IRQ pending flag.
    lda Mmc5::IRQ_STATUS

    ; restore CPU state
    pla ; restore Y register
    tay
    pla ; restore X register
    tax
    pla ; restore A register

    rti
.endproc
