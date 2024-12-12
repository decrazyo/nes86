
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

        ZERO_PAGE = $00

        ; TODO: move this stuff to ppu.inc

        ; tile dimensions
        TILE_WIDTH = 8
        TILE_HEIGHT = 8

        ; screen dimensions in tiles
        SCREEN_TILE_WIDTH = 32
        SCREEN_TILE_HEIGHT = 30
        SCREEN_TILE_AREA = SCREEN_TILE_WIDTH * SCREEN_TILE_HEIGHT

        ; screen dimensions in pixels
        SCREEN_PIXEL_WIDTH = 256
        SCREEN_PIXEL_HEIGHT = 240
        SCREEN_PIXEL_AREA = SCREEN_PIXEL_WIDTH * SCREEN_PIXEL_HEIGHT

        EMU_ROM_SIZE = $4000 ; all of the emulator code/data take 16k bytes

    .endscope

    ; TODO: remove this stuff completely.

    ; CPU ignores the following 1 or 2 bytes
    .define SKIP_BYTE .byte $24 ; 8-bit BIT instruction.
    .define SKIP_WORD .byte $2c ; 16-bit BIT instruction.
    .define KILL .byte $02 ; halt and catch fire.

.endif
