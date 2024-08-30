
.include "irq.inc"

.include "const.inc"
.include "ppu.inc"
.include "mmc5.inc"
.include "terminal.inc"
.include "keyboard/ram.inc"
.include "keyboard/on_screen.inc"

.export irq

.segment "ZEROPAGE"

zwTemp: .res 2

zbMode: .res 1

.enum eMode
    SCROLL_KEYBOARD
    SCROLL_TERMINAL
.endenum

.segment "LOWCODE"

; global IRQ handler.
; exclusively used by the on-screen keyboard.
.proc irq
    ; save CPU state
    pha ; save A register
    txa
    pha ; save X register
    tya
    pha ; save Y register

    clc
    lda Ppu::zbScrollPixelY
    adc #OnScreen::KEYBOARD_HEIGHT - 1

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
    sta zwTemp

    lda Ppu::zbScrollPixelX
    lsr
    lsr
    lsr
    ora zwTemp
    sta zwTemp

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
    ldx $00
    stx Ppu::ADDR

    ; ### NN ##### XXXXX
    ; ||| || ||||| +++++-- coarse X scroll
    ; ||| || +++++-------- coarse Y scroll
    ; ||| ++-------------- nametable select
    ; +++----------------- fine Y scroll

    ; ldy Ppu::zbScrollPixelY
    sty Ppu::SCROLL

    nop
    nop

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

    lda zwTemp
    sta Ppu::ADDR

    lda Ppu::zbCtrl
    and #%11111100
    sta Ppu::zbCtrl
    sta Ppu::CTRL

    ; clear the IRQ pending flag.
    lda Mmc5::IRQ_STATUS
    ; disable scanline interrupts.
    ; the on-screen keyboard driver will re-enable it if necessary.
    lda #0
    sta Mmc5::IRQ_STATUS

    ; disable sprite rendering.
    lda Ppu::zbMask
    sta Ppu::MASK

    ; restore CPU state
    pla ; restore Y register
    tay
    pla ; restore X register
    tax
    pla ; restore A register

    rti
.endproc
