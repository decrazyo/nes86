
.ifndef _MMC5_
    _MMC5_ = 1

    .include "header.inc"

    .scope Mmc5

        .import mmc5

        .import clear_ram
        .import test_ram
        .import test_rom

        ; 8 x 8 multiplier.
        ; don't use this during interrupts or you'll corrupt the x86 emulator.
        MULT_LO = $5205
        MULT_HI = $5206

        ; interrupt control registers
        IRQ_COMPARE = $5203
        IRQ_STATUS = $5204

        ; interrupt flags
        IRQ_STATUS_E = %10000000 ; scanline IRQ enable flag (1 = enabled)
        IRQ_STATUS_S = %10000000 ; scanline IRQ pending flag
        IRQ_STATUS_V = %01000000 ; in frame flag (0 = in v-blank)

        ; bitmask to OR with the value supplied to a WINDOW_#_CTRL register.
        ; used to select PRG RAM or PRG ROM.
        RAM = %00000000
        ROM = %10000000

        ; registers that control which bank is mapped to a given window.
        WINDOW_0_CTRL = $5113
        WINDOW_1_CTRL = $5115
        WINDOW_2_CTRL = $5117

        ; addresses of the PRG RAM/ROM windows
        WINDOW_0 = $6000 ; RAM only
        WINDOW_1 = $8000 ; RAM/ROM
        WINDOW_2 = $C000 ; ROM only

        BANK_SIZE = $2000

        PRG_ROM_WINDOW_SIZE = WINDOW_2 - WINDOW_1 ; should be 16k
        PRG_ROM_SIZE = Header::PRG_ROM ; PRG ROM size in bytes
        PRG_ROM_PAGES = PRG_ROM_SIZE / $100 ; number of 256 byte PRG ROM pages
        PRM_ROM_WINDOWS = PRG_ROM_SIZE / PRG_ROM_WINDOW_SIZE ; number of 16k PRG ROM windows
        PRG_ROM_BANKS = PRG_ROM_SIZE / BANK_SIZE ; number of 8k PRG ROM banks

        PRG_RAM_WINDOW_SIZE = WINDOW_1 - WINDOW_0 ; should be 8k
        PRG_RAM_SIZE = Header::PRG_RAM ; PRG RAM size in bytes
        PRG_RAM_PAGES = PRG_RAM_SIZE / $100 ; number of 256 byte PRG RAM pages
        PRG_RAM_WINDOWS = PRG_RAM_SIZE / PRG_RAM_WINDOW_SIZE ; number of 8k PRG RAM windows
        PRG_RAM_BANKS = PRG_RAM_SIZE / BANK_SIZE ; number of 8k PRG RAM banks

    .endscope

.endif
