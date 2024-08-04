
.ifndef _KEYBOARD_ON_SCREEN_
_KEYBOARD_ON_SCREEN_ = 1

.include "const.inc"

.scope OnScreen

    .import on_screen

    KEYBOARD_ROWS = 5
    KEYBOARD_COLS = 14
    ; account for the 2 blank rows. 1 above the keyboard and 1 below.
    KEYBOARD_HEIGHT = ((KEYBOARD_ROWS + 2) * Const::TILE_HEIGHT)

.endscope

.endif
