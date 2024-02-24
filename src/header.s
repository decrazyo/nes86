
; iNES ROM file header
.segment "HEADER"

INES_MAPPER = 0
INES_MIRROR = 1 ; 0 = horizontal, 1 = vertical
INES_SRAM   = 0 ; 1 = battery backed save RAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; iNES file identifier
.byte $02 ; 16k PRG chunk count
.byte $01 ; 8k CHR chunk count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $0f) << 4)
.byte (INES_MAPPER & $f0)

; TODO: start using the MMC5 mapper.
