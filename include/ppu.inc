
; definitions for the picture processing unit (PPU).

.ifndef _PPU_
    _PPU_ = 1

    .scope Ppu

        .importzp zbMask
        .importzp zbCtrl

        .importzp zbScrollPixelX
        .importzp zbScrollPixelY

        .import aOamBuffer

        .import ppu

        .import transfer_data
        .import scroll
        .import oam_dma

        .import write_initialized
        .import initialize_write
        .import write_byte
        .import write_bytes
        .import finalize_write

        .enum eColor
            DARK_GRAY = $00
            DARK_AZURE
            DARK_BLUE
            DARK_VIOLET
            DARK_MAGENTA
            DARK_ROSE
            DARK_RED
            DARK_ORANGE
            DARK_YELLOW
            DARK_CHARTREUSE
            DARK_GREEN
            DARK_SPRING
            DARK_CYAN
            BLACK = $0f
            GRAY
            AZURE
            BLUE
            VIOLET
            MAGENTA
            ROSE
            RED
            ORANGE
            YELLOW
            CHARTREUSE
            GREEN
            SPRING
            CYAN
            WHITE = $20
            LIGHT_AZURE
            LIGHT_BLUE
            LIGHT_VIOLET
            LIGHT_MAGENTA
            LIGHT_ROSE
            LIGHT_RED
            LIGHT_ORANGE
            LIGHT_YELLOW
            LIGHT_CHARTREUSE
            LIGHT_GREEN
            LIGHT_SPRING
            LIGHT_CYAN
            PALE_AZURE = $31
            PALE_BLUE
            PALE_VIOLET
            PALE_MAGENTA
            PALE_ROSE
            PALE_RED
            PALE_ORANGE
            PALE_YELLOW
            PALE_CHARTREUSE
            PALE_GREEN
            PALE_SPRING
            PALE_CYAN
        .endenum

        ; PPU registers
        CTRL     = $2000 ; VPHBSINN
        MASK     = $2001 ; BGRsbMmG
        STATUS   = $2002 ; VSO-----
        OAM_ADDR = $2003 ; OAM read/write address
        OAM_DATA = $2004 ; OAM data read/write
        SCROLL   = $2005 ; fine scroll position (two writes: X scroll, Y scroll)
        ADDR     = $2006 ; PPU read/write address (two writes: most significant byte, least significant byte)
        DATA     = $2007 ; PPU data read/write
        OAM_DMA  = $4014 ; OAM DMA high address

        ; PPU register flags / bit masks.

        ; PPU control register flags
        CTRL_V = %10000000 ; NMI enable
        CTRL_P = %01000000 ; PPU master/slave
        CTRL_H = %00100000 ; sprite height (0: 8x8 pixels; 1: 8x16 pixels)
        CTRL_B = %00010000 ; background pattern table select (0: $0000; 1: $1000)
        CTRL_S = %00001000 ; sprite pattern table select (0: $0000; 1: $1000; ignored in 8x16 mode)
        CTRL_I = %00000100 ; increment mode (0: add 1, going across; 1: add 32, going down)
        CTRL_N = %00000011 ; nametable select (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)

        ; NOTE: some of these symbols do not follow the normal upper case naming convention.
        ;       instead, they borrow from the naming convention used by nesdev.org.
        ;       https://www.nesdev.org/wiki/PPU_registers
        ;       the linter will complain about this
        ;       but *.inc files aren't linted at compile time so i'm ignoring it.

        ; PPU mask register flags
        MASK_B = %10000000 ; color emphasis blue
        MASK_G = %01000000 ; color emphasis green (red on PAL/Dendy)
        MASK_R = %00100000 ; color emphasis red (green on PAL/Dendy)
        MASK_s = %00010000 ; sprite enable
        MASK_b = %00001000 ; background enable
        MASK_M = %00000100 ; sprite left column enable
        MASK_m = %00000010 ; background left column enable
        MASK_g = %00000001 ; greyscale

        ; PPU status register flags
        STATUS_V = %10000000 ; vblank
        STATUS_S = %01000000 ; sprite 0 hit
        STATUS_O = %00100000 ; sprite overflow; read resets write pair for $2005/$2006

        NAMETABLE_0 = $2000
        NAMETABLE_1 = $2400
        NAMETABLE_2 = $2800
        NAMETABLE_3 = $2C00

        ATTRIBUTE_0 = $23C0
        ATTRIBUTE_1 = $27C0
        ATTRIBUTE_2 = $2BC0
        ATTRIBUTE_3 = $2FC0

        BACKGROUND_PALLET_ADDR = $3f00
        SPRITE_PALLET_ADDR = $3f10

        SPRITE_COUNT = 64

        SPRITE_Y = $00
        SPRITE_TILE = $01
        SPRITE_ATTR = $02
        SPRITE_X = $03

        SPRITE_ATTR_V = %10000000
        SPRITE_ATTR_H = %01000000

        SPRITE_0 = $00
        SPRITE_1 = $04
        SPRITE_2 = $08
        SPRITE_3 = $0c
        SPRITE_4 = $10
        SPRITE_5 = $14
        SPRITE_6 = $18
        SPRITE_7 = $1c
        SPRITE_8 = $20
        SPRITE_9 = $24
        SPRITE_10 = $28
        SPRITE_11 = $2c
        SPRITE_12 = $30
        SPRITE_13 = $34
        SPRITE_14 = $38
        SPRITE_15 = $3c
        SPRITE_16 = $40
        SPRITE_17 = $44
        SPRITE_18 = $48
        SPRITE_19 = $4c
        SPRITE_20 = $50
        SPRITE_21 = $54
        SPRITE_22 = $58
        SPRITE_23 = $5c
        SPRITE_24 = $60
        SPRITE_25 = $64
        SPRITE_26 = $68
        SPRITE_27 = $6c
        SPRITE_28 = $70
        SPRITE_29 = $74
        SPRITE_30 = $78
        SPRITE_31 = $7c
        SPRITE_32 = $80
        SPRITE_33 = $84
        SPRITE_34 = $88
        SPRITE_35 = $8c
        SPRITE_36 = $90
        SPRITE_37 = $94
        SPRITE_38 = $98
        SPRITE_39 = $9c
        SPRITE_40 = $a0
        SPRITE_41 = $a4
        SPRITE_42 = $a8
        SPRITE_43 = $ac
        SPRITE_44 = $b0
        SPRITE_45 = $b4
        SPRITE_46 = $b8
        SPRITE_47 = $bc
        SPRITE_48 = $c0
        SPRITE_49 = $c4
        SPRITE_50 = $c8
        SPRITE_51 = $cc
        SPRITE_52 = $d0
        SPRITE_53 = $d4
        SPRITE_54 = $d8
        SPRITE_55 = $dc
        SPRITE_56 = $e0
        SPRITE_57 = $e4
        SPRITE_58 = $e8
        SPRITE_59 = $ec
        SPRITE_60 = $f0
        SPRITE_61 = $f4
        SPRITE_62 = $f8
        SPRITE_63 = $fc

        ; TODO: add definitions for OAM, pallets, etc...
    .endscope

.endif
