
; definitions for the picture processing unit (PPU).

.ifndef _PPU_
_PPU_ = 1

.scope Ppu
    .importzp zbMask
    .importzp zbCtrl

    .import ppu
    .import disable_rendering
    .import restore_rendering

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

    ; TODO: add definitions for OAM, nametables, pallets, etc...
.endscope

.endif
