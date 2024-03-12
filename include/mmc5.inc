
.ifndef _MMC5_
_MMC5_ = 1

.scope Mmc5
    .import mmc5

    RAM = %00000000
    ROM = %10000000

    WIN0_BANK = $5113
    WIN1_BANK = $5114
    WIN2_BANK = $5115
    WIN3_BANK = $5116
    WIN4_BANK = $5117

    MULT_LO = $5205
    MULT_HI = $5206

    WINDOW0 = $6000 ; RAM only  (stack segment)
    WINDOW1 = $8000 ; RAM/ROM   (any segment)
    WINDOW2 = $A000 ; RAM/ROM   (TODO: code segment)
    WINDOW3 = $C000 ; RAM/ROM   (unused)
    WINDOW4 = $E000 ; ROM only  (unused)
.endscope

.endif
