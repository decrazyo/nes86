
; iNES ROM file header
.segment "HEADER"

; define this to use the NES 2.0 style header
USE_NES2 = 1

INES_PRG_ROM = 64 ; number of 16k PRG ROM chunks (1024k)
INES_CHR_ROM = 1 ; number of 8k CHR ROM chunks
INES_MIRROR  = 1 ; 0 = horizontal, 1 = vertical
INES_SRAM    = 0 ; 1 = battery backed save RAM at $6000-7FFF
INES_TRAINER = 0 ; 1 = 512-byte trainer data
INES_ALT     = 0 ; 1 = alternative nametable layout
INES_MAPPER  = 5 ; 5 = MMC5
INES_CONSOLE = 0 ; 0 = NES/Famicom
                 ; 1 = Vs. System
                 ; 2 = Playchoice 10
                 ; 3 = extended console type

; TODO: set PRG_RAM size correctly
NES2_PRG_RAM   = 4 ; number of 64 byte PRG RAM chunks
NES2_PRG_NVRAM = 0 ; number of 64 byte PRG NVRAM chunks
NES2_CHR_RAM   = 0 ; number of 64 byte CHR RAM chunks
NES2_CHR_NVRAM = 0 ; number of 64 byte CHR NVRAM chunks
NES2_TIMING    = 2 ; 0: NTSC NES
                   ; 1: PAL NES
                   ; 2: Multi-region
                   ; 3: Dendy
NES2_EXP_DEV   = 0 ; default expansion device
                   ; $23 = Family BASIC Keyboard

; TODO: add asserts for things

; iNES header (bytes 0-7)
.byte 'N', 'E', 'S', $1A ; iNES file identifier
.byte INES_PRG_ROM
.byte INES_CHR_ROM
.byte INES_MIRROR | (INES_SRAM << 1) | (INES_TRAINER << 2) | ((INES_MAPPER & $0f) << 4)

.ifndef USE_NES2
.byte (INES_MAPPER & $f0) | INES_CONSOLE
.else
.byte (INES_MAPPER & $f0) | INES_CONSOLE | (2 << 2)

; NES 2.0 header (bytes 8-15)
.byte ((INES_MAPPER & $ff00) >> 8)
.byte ((INES_PRG_ROM & $f00) >> 8) | ((INES_CHR_ROM & $f00) >> 4)
.byte (NES2_PRG_RAM & $0f) | ((NES2_PRG_NVRAM & $0f) << 4)
.byte (NES2_CHR_RAM & $0f) | ((NES2_CHR_NVRAM & $0f) << 4)
.byte NES2_TIMING
.byte $00 ; Vs. System / extended console stuff
.byte $00 ; miscellaneous ROMs
.byte NES2_EXP_DEV

.endif
