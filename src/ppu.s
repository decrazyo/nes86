
.include "ppu.inc"
.include "chr.inc"
.include "nmi.inc"
.include "const.inc"

.exportzp gzbPpuMask
.exportzp gzbPpuCtrl

.export ppu
.export ppu_disable_rendering
.export ppu_restore_rendering

.segment "ZEROPAGE"

gzbPpuMask: .res 1
gzbPpuCtrl: .res 1

.segment "CODE"

; initialize the ppu
.proc ppu
    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    ; initialize tiles on screen.
    lda #BLANK_TILE
    ldx #(SCREEN_W_TILE * SCREEN_H_TILE) / 4

@clear_screen:
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    dex
    bne @clear_screen

    ; initialize palette data.
    lda #$3f
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

    lda #$0f ; universal background color (black).
    ldy #$30 ; white.
    ldx #4

@set_pallets:
    ; set the 2 colors that the screen will use.
    sta PPU_DATA
    sty PPU_DATA
    sty PPU_DATA
    sty PPU_DATA
    dex
    bne @set_pallets

    ; enable NMI interrupts
    lda #PPU_CTRL_V
    sta gzbPpuCtrl
    sta PPU_CTRL

    ; NMI will handle setting the scroll position.
    jsr nmi_wait

    ; enable rendering
    lda #PPU_MASK_b | PPU_MASK_m
    sta gzbPpuMask
    sta PPU_MASK

    rts
.endproc

.proc ppu_disable_rendering
    lda gzbPpuMask
    and #<~(PPU_MASK_s | PPU_MASK_b)
    sta PPU_MASK
    rts
.endproc

.proc ppu_restore_rendering
    lda gzbPpuMask
    sta PPU_MASK
    rts
.endproc
