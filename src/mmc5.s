
.include "mmc5.inc"

.include "tmp.inc"

.export mmc5

PRG_MODE = $5100
CHR_MODE = $5101

PROTECT1 = $5102
PROTECT2 = $5103

.segment "CODE"

.proc mmc5
    ; configure PRG mode 3
    ; $6000-$7FFF: 8 KB switchable PRG RAM bank
    ; $8000-$9FFF: 8 KB switchable PRG ROM/RAM bank
    ; $A000-$BFFF: 8 KB switchable PRG ROM/RAM bank
    ; $C000-$DFFF: 8 KB switchable PRG ROM/RAM bank
    ; $E000-$FFFF: 8 KB switchable PRG ROM bank
    lda #3
    sta PRG_MODE

    ; configure CHR mode 0
    ; 8KB CHR pages
    ; NOTE: consider switching to mode 3 since most games use that.
    ;       it might give us better compatibility with cheap Famiclones.
    lda #0
    sta CHR_MODE

    ; make PRG RAM writable
    lda #2
    sta PROTECT1
    lsr
    sta PROTECT2

    rts
.endproc
