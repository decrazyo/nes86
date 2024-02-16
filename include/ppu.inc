
; definitions for the picture processing unit (PPU).

.ifndef _PPU_
.define _PPU_

; PPU registers
PPU_CTRL     = $2000 ; VPHBSINN
PPU_MASK     = $2001 ; BGRsbMmG
PPU_STATUS   = $2002 ; VSO-----
PPU_OAM_ADDR = $2003 ; OAM read/write address
PPU_OAM_DATA = $2004 ; OAM data read/write
PPU_SCROLL   = $2005 ; fine scroll position (two writes: X scroll, Y scroll)
PPU_ADDR     = $2006 ; PPU read/write address (two writes: most significant byte, least significant byte)
PPU_DATA     = $2007 ; PPU data read/write
PPU_OAM_DMA  = $4014 ; OAM DMA high address 

; PPU register flags / bit masks.

; PPU_CTRL register flags
PPU_CTRL_V = %10000000 ; NMI enable
PPU_CTRL_P = %01000000 ; PPU master/slave
PPU_CTRL_H = %00100000 ; sprite height (0: 8x8 pixels; 1: 8x16 pixels)
PPU_CTRL_B = %00010000 ; background pattern table select (0: $0000; 1: $1000)
PPU_CTRL_S = %00001000 ; sprite pattern table select (0: $0000; 1: $1000; ignored in 8x16 mode)
PPU_CTRL_I = %00000100 ; increment mode (0: add 1, going across; 1: add 32, going down)
PPU_CTRL_N = %00000011 ; nametable select (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)

; PPU_MASK register flags
PPU_MASK_B = %10000000 ; color emphasis blue
PPU_MASK_G = %01000000 ; color emphasis green (red on PAL/Dendy)
PPU_MASK_R = %00100000 ; color emphasis red (green on PAL/Dendy)
PPU_MASK_s = %00010000 ; sprite enable
PPU_MASK_b = %00001000 ; background enable
PPU_MASK_M = %00000100 ; sprite left column enable
PPU_MASK_m = %00000010 ; background left column enable
PPU_MASK_g = %00000001 ; greyscale

; PPU_STATUS register flags
PPU_STATUS_V = %10000000 ; vblank
PPU_STATUS_S = %01000000 ; sprite 0 hit
PPU_STATUS_O = %00100000 ; sprite overflow; read resets write pair for $2005/$2006

; TODO: add definitions for OAM, nametables, pallets, etc...

.endif
