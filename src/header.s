
.include "header.inc"

; iNES/NES 2.0 ROM file header
.segment "HEADER"

; TODO: add more sanity checks.

; iNES header (bytes 0-7)
.byte 'N', 'E', 'S', $1A ; iNES file identifier
.byte Header::Ines::PRG_ROM
.byte Header::Ines::CHR_ROM
.byte Header::Ines::MIRROR | (Header::Ines::SRAM << 1) | (Header::Ines::TRAINER << 2) | ((Header::Ines::MAPPER & $0f) << 4)

.ifndef Header::USE_NES2
.byte (Header::Ines::MAPPER & $f0) | Header::Ines::CONSOLE
.else
.byte (Header::Ines::MAPPER & $f0) | Header::Ines::CONSOLE | (2 << 2)

.assert Header::Nes2::PRG_RAM <= $0f, error, "Header::Nes2::PRG_RAM too large"
.assert Header::Nes2::PRG_NVRAM <= $0f, error, "Header::Nes2::PRG_NVRAM too large"
.assert Header::Nes2::CHR_RAM <= $0f, error, "Header::Nes2::CHR_RAM too large"
.assert Header::Nes2::CHR_NVRAM <= $0f, error, "Header::Nes2::CHR_NVRAM too large"

; NES 2.0 header (bytes 8-15)
.byte ((Header::Ines::MAPPER & $ff00) >> 8)
.byte ((Header::Ines::PRG_ROM & $f00) >> 8) | ((Header::Ines::CHR_ROM & $f00) >> 4)
.byte (Header::Nes2::PRG_RAM & $0f) | ((Header::Nes2::PRG_NVRAM & $0f) << 4)
.byte (Header::Nes2::CHR_RAM & $0f) | ((Header::Nes2::CHR_NVRAM & $0f) << 4)
.byte Header::Nes2::TIMING
.byte $00 ; Vs. System / extended console stuff
.byte $00 ; miscellaneous ROMs
.byte Header::Nes2::EXP_DEV

.endif
