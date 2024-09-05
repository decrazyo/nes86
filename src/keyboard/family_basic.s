
; this module manages the family BASIC keyboard.
; TODO: refactor this module to be more readable/maintainable.
; TODO: add support for additional keys. CTRL, arrows, etc...

.include "const.inc"
.include "keyboard.inc"
.include "keyboard/family_basic.inc"

.export family_basic

MATRIX_ROWS = 9

.segment "ZEROPAGE"

zbaMatrixState: .res MATRIX_ROWS
zbaRowKeys: .res 1
zbaRowState: .res 1
zbJoypad1State: .res 1
zbKeyIndex: .res 1

; holds the state of modifier keys.
zbModifierKeys: .res 1
zbModifierKeysNew: .res 1

.segment "RODATA"

LSHIFT_MASK = %00010000
RSHIFT_MASK = %00100000
MOD_MASK   = %10000000

; the high bit is set to identify these as modifier keys.
LSHIFT = MOD_MASK | LSHIFT_MASK
RSHIFT = MOD_MASK | RSHIFT_MASK

; 0       1       2       3       4       5       6       7
; ----------------------------------------------------------------
; F8      RETURN  [       ]       KANA    RSHIFT  ¥       STOP
; F7      @       :       ;       _       /       -       ^
; F6      O       L       K       .       ,       P       0
; F5      I       U       J       M       N       9       8
; F4      Y       G       H       B       V       7       6
; F3      T       R       D       F       C       5       4
; F2      W       S       A       X       Z       E       3
; F1      ESC     Q       CTR     LSHIFT  GRPH    1       2
; CLR     UP      RIGHT   LEFT    DOWN    SPACE   DEL     INS

rbaKeyTable:
.byte $00,  $0a,  "[",  "]",  $00,   RSHIFT, "\\", $00
.byte $00,  "@",  ":",  ";",  "_",   "/",   "-",  "^"
.byte $00,  "o",  "l",  "k",  ".",   ",",   "p",  "0"
.byte $00,  "i",  "u",  "j",  "m",   "n",   "9",  "8"
.byte $00,  "y",  "g",  "h",  "b",   "v",   "7",  "6"
.byte $00,  "t",  "r",  "d",  "f",   "c",   "5",  "4"
.byte $00,  "w",  "s",  "a",  "x",   "z",   "e",  "3"
.byte $00,  $00,  "q",  $00,  LSHIFT, $00,   "1",  "2"
.byte $00,  $00,  $00,  $00,  $00,   " ",   $08,  $00

rbaShiftKeyTable:
.byte $00,  $0a,  "[",  "]",  $00,   RSHIFT, "\\", $00
.byte $00,  "@",  "*",  "+",  "_",   "?",   "=",  "^"
.byte $00,  "O",  "L",  "K",  ">",   "<",   "P",  "0"
.byte $00,  "I",  "U",  "J",  "M",   "N",   ")",  "("
.byte $00,  "Y",  "G",  "H",  "B",   "V",   "'",  "&"
.byte $00,  "T",  "R",  "D",  "F",   "C",   "%",  "$"
.byte $00,  "W",  "S",  "A",  "X",   "Z",   "E",  "#"
.byte $00,  $00,  "Q",  $00,  LSHIFT, $00,   "!",  '"'
.byte $00,  $00,  $00,  $00,  $00,   " ",   $08,  $00


JOYPAD1_R = %00000001 ; reset the keyboard to the first row.
JOYPAD1_C = %00000010 ; select column, row is incremented if this bit goes from high to low.
JOYPAD1_K = %00000100 ; enable keyboard matrix

JOYPAD2_MASK = %00011110 ; receive key status of currently selected row/column.

.segment "CODE"

; detect and initialize a Family BASIC keyboard.
; > C = 1 keyboard not detected
;   C = 0 keyboard initialize
; changes: A, X, Y
.proc family_basic
    jsr reset

    ; select the 10th row.
    ; this row doesn't contain any keys.
    ldx #18
loop:
    jsr next
    dex
    bne loop

    ; read row 10.
    ; since this row has no keys, reading it should return no pressed keys.
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    ; the keyboard indicates a pressed key with a 0 bit.
    ; invert the data so that a 1 bit indicates a key press.
    eor #JOYPAD2_MASK
    bne done ; branch if a key press is detected.

    ; A = 0
    ; disable the keyboard matrix
    sta Const::JOYPAD1
    jsr delay

    ; read the keyboard again
    ; since the keyboard is disabled, we should read all 0s.
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    bne done

    ; it looks like we have a Family BASIC keyboard attached
    ; so we will install our "scan" routine.
    ldx #<scan
    stx Keyboard::zpScanFunc
    ldx #>scan
    stx Keyboard::zpScanFunc+1 ; must be done last

done:
    cmp #1 ; set or clear C to indicate success or failure to our caller.
    rts
.endproc


; scan the keyboard matrix.
; buffer any pressed keys.
; changes: A, X, Y
.proc scan
    ; reset the keyboard to row 0
    jsr reset

    ldx #0
    stx zbModifierKeysNew
    stx zbKeyIndex
    ldy #MATRIX_ROWS - 1

read_row:
    ; read a row of the keyboard matrix
    jsr next
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    lsr
    sta zbaRowState
    jsr next
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    asl
    asl
    asl
    ora zbaRowState
    sta zbaRowState

    ; compare against the the previous state of this row.
    ; this isolates the bits representing newly pressed keys on this row.
    eor zbaMatrixState, y
    and zbaMatrixState, y
    ; a 1 bit will indicate a pressed key.
    sta zbaRowKeys

    sec
    ror zbaRowKeys
    ; check each bit it determine if the associated key is pressed.
check_key:
    bcc skip_key ; branch if the key isn't pressed
    ldx zbKeyIndex

    lda zbModifierKeys

    bne shift_key
    lda rbaKeyTable, x
    jmp handle_key
shift_key:
    lda rbaShiftKeyTable, x

handle_key:
    beq skip_key ; branch if this is a key we don't care about
    bpl normal_key

    ; we're dealing with a modifier key
    ; strip off the high bit because we don't want/need it.
    and #<~MOD_MASK
    sta zbModifierKeysNew

    ; alter the row state to indicate that the modifier key isn't pressed.
    ; this allows us to detect the key if it is held between frames.
    ora zbaRowState
    sta zbaRowState

    bne skip_key
normal_key:
    jsr Keyboard::put_key

skip_key:
    inc zbKeyIndex
    lsr zbaRowKeys
    bne check_key

    ; update the matrix state for this row.
    lda zbaRowState
    sta zbaMatrixState, y

    dey
    bpl read_row

    ; save the new state of modifier keys
    lda zbModifierKeysNew
    sta zbModifierKeys

    rts
.endproc


; reset the keyboard to the 0th row, 0th column.
; changes: A
.proc reset
    lda #(JOYPAD1_K | JOYPAD1_R)
    sta Const::JOYPAD1
    lda #(JOYPAD1_K | JOYPAD1_C)
    sta zbJoypad1State
    jmp delay
    ; [tail_jump]
.endproc


; select the next section of the keyboard matrix by toggling the column bit.
; changes: A
.proc next
    lda zbJoypad1State
    eor #JOYPAD1_C
    sta zbJoypad1State
    sta Const::JOYPAD1
    jmp delay
    ; [tail_jump]
.endproc


; burn some cycles to give the keyboard time to settle.
; changes: A
.proc delay
    sec
    lda #0
loop:
    ror
    bne loop
    rts
.endproc
