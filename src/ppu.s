
.include "ppu.inc"
.include "chr.inc"
.include "nmi.inc"
.include "const.inc"

.exportzp zbMask
.exportzp zbCtrl

.export ppu
.export disable_rendering
.export restore_rendering

.segment "ZEROPAGE"

zbMask: .res 1
zbCtrl: .res 1

.segment "CODE"

; initialize the ppu
.proc ppu
    lda #$20
    sta Ppu::ADDR
    lda #$00
    sta Ppu::ADDR

    ; initialize tiles on screen.
    lda #Chr::BLANK_TILE
    ldx #(Const::SCREEN_W_TILE * Const::SCREEN_H_TILE) / 4

@clear_screen:
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    sta Ppu::DATA
    dex
    bne @clear_screen

    ; initialize palette data.
    lda #$3f
    sta Ppu::ADDR
    lda #$00
    sta Ppu::ADDR

    lda #$0f ; universal background color (black).
    ldy #$30 ; white.
    ldx #4

@set_pallets:
    ; set the 2 colors that the screen will use.
    sta Ppu::DATA
    sty Ppu::DATA
    sty Ppu::DATA
    sty Ppu::DATA
    dex
    bne @set_pallets

    ; enable NMI interrupts
    lda #Ppu::CTRL_V
    sta zbCtrl
    sta Ppu::CTRL

    ; NMI will handle setting the scroll position.
    jsr Nmi::wait

    ; enable rendering
    lda #Ppu::MASK_b | Ppu::MASK_m
    sta zbMask
    sta Ppu::MASK

    rts
.endproc

.proc disable_rendering
    lda zbMask
    and #<~(Ppu::MASK_s | Ppu::MASK_b)
    sta Ppu::MASK
    rts
.endproc

.proc restore_rendering
    lda zbMask
    sta Ppu::MASK
    rts
.endproc
