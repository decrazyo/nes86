
.ifndef _CONST_
_CONST_ = 1

.scope Const
    ; joypad addresses
    JOYPAD1 = $4016
    JOYPAD2 = $4017

    ; joypad bit masks
    JOYPAD_A      = %10000000
    JOYPAD_B      = %01000000
    JOYPAD_SELECT = %00100000
    JOYPAD_START  = %00010000
    JOYPAD_UP     = %00001000
    JOYPAD_DOWN   = %00000100
    JOYPAD_LEFT   = %00000010
    JOYPAD_RIGHT  = %00000001

    ; tile dimensions
    TILE_W = 8
    TILE_H = 8

    ; screen dimensions in tiles
    SCREEN_W_TILE = 32
    SCREEN_H_TILE = 30

    ; screen dimensions in pixels
    SCREEN_W_PIXEL = 256
    SCREEN_H_PIXEL = 240

    ZERO_PAGE = $00

    ; bitmask for segment index in instruction prefix
    PREFIX_SEG_MASK = %00011000

    ; bitmask for opcodes with an embedded register index
    OPCODE_REG_MASK = %00000111

    ; ModR/M bitmasks
    MODRM_MOD_MASK   = %11000000 ; access mode
    MODRM_REG_MASK   = %00111000 ; register index
    MODRM_INSTR_MASK = %00111000 ; instruction index
    MODRM_SEG_MASK   = %00011000 ; segment register index
    MODRM_RM_MASK    = %00000111 ; register index or index to registers to use as pointers

    ; ModR/M R/M field indicates a direct address
    MODRM_RM_DIRECT  = %00000110

.endscope

; CPU ignores the following 1 or 2 bytes
.define SKIP_BYTE .byte $24 ; 8-bit BIT instruction.
.define SKIP_WORD .byte $2c ; 16-bit BIT instruction.
.define KILL .byte $02 ; halt and catch fire.

.macro mov8 dst, src
    lda src
    sta dst
.endmac

.macro mov16 dst, src
    lda src
    sta dst
    lda src+1
    sta dst+1
.endmac

.endif
