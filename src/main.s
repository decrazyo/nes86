
.include "main.inc"
.include "const.inc"
.include "nmi.inc"

.export main

BLANK_TILE = <-1

.segment "ZEROPAGE"

.segment "BSS"

.segment "CODE"

.proc main
    ; initialize the screen
    ; TODO: consider moving this logic to nmi.s
    lda #$20
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR

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
    ; TODO: consider moving this logic to nmi.s
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

    ; the NMI handler will set the scroll position.
    lda #0
    sta gzbPpuScrollX
    sta gzbPpuScrolly

    ; enable rendering
    lda #PPU_MASK_b | PPU_MASK_m
    sta PPU_MASK
    lda #PPU_CTRL_V
    sta PPU_CTRL

main_loop:

    lda gzbNmiCount
@nmi_wait:
    ; NMI will increment this to break us out of the loop.
    cmp gzbNmiCount
    beq @nmi_wait
    jmp main_loop
.endproc
