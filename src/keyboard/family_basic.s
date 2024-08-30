
.include "keyboard/family_basic.inc"

.include "const.inc"
.include "tmp.inc"
.include "keyboard.inc"
.include "keyboard/ram.inc"

.export family_basic

.segment "LOWCODE"

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
.byte $00,  $0a,  "[",  "]",  $00,  $00,  "\\", $00
.byte $00,  "@",  ":",  ";",  "_",  "/",  "-",  "^"
.byte $00,  "o",  "l",  "k",  ".",  ",",  "p",  "0"
.byte $00,  "i",  "u",  "j",  "m",  "n",  "9",  "8"
.byte $00,  "y",  "g",  "h",  "b",  "v",  "7",  "6"
.byte $00,  "t",  "r",  "d",  "f",  "c",  "5",  "4"
.byte $00,  "w",  "s",  "a",  "x",  "z",  "e",  "3"
.byte $00,  $00,  "q",  $00,  $00,  $00,  "1",  "2"
.byte $00,  $00,  $00,  $00,  $00,  " ",  $00,  $00

JOYPAD1_R = %00000001 ; reset the keyboard to the first row.
JOYPAD1_C = %00000010 ; select column, row is incremented if this bit goes from high to low.
JOYPAD1_K = %00000100 ; enable keyboard matrix

JOYPAD2_MASK = %00011110 ; receive key status of currently selected row/column.

; detect and initialize a Family BASIC keyboard.
; > C = 1 keyboard initialize
;   C = 0 keyboard not detected
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
    cmp #0 ; set or clear C to indicate success or failure to our caller.
    clc ; TODO: remove this. added for testing on-screen keyboard.
    rts
.endproc


; scan the keyboard matrix.
; buffer any pressed keys.
; changes: A, X, Y
.proc scan
    ; reset the keyboard to row 0
    jsr reset

    ldx #0
    stx Ram::FamilyBasic::zbKeyIndex
    ldy #FamilyBasic::MATRIX_ROWS - 1

read_row:
    ; read a row of the keyboard matrix
    jsr next
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    lsr
    sta Ram::FamilyBasic::zbaRowState
    jsr next
    lda Const::JOYPAD2
    and #JOYPAD2_MASK
    asl
    asl
    asl
    ora Ram::FamilyBasic::zbaRowState
    sta Ram::FamilyBasic::zbaRowState

    ; compare against the the previous state of this row.
    ; this isolates the bits representing newly pressed keys on this row.
    eor Ram::FamilyBasic::zbaMatrixState, y
    and Ram::FamilyBasic::zbaMatrixState, y
    ; a 1 bit will indicate a pressed key.
    sta Ram::FamilyBasic::zbaRowKeys

    sec
    ror Ram::FamilyBasic::zbaRowKeys
    ; check each bit it determine if the associated key is pressed.
check_key:
    bcc skip_key ; branch if the key isn't pressed
    ldx Ram::FamilyBasic::zbKeyIndex
    lda rbaKeyTable, x
    beq skip_key ; branch if this is a key we don't care about
    jsr Keyboard::put_key

skip_key:
    inc Ram::FamilyBasic::zbKeyIndex
    lsr Ram::FamilyBasic::zbaRowKeys
    bne check_key

    ; update the matrix state for this row.
    lda Ram::FamilyBasic::zbaRowState
    sta Ram::FamilyBasic::zbaMatrixState, y

    dey
    bpl read_row

    ; TODO: check the 10th row to make sure the keyboard is still plugged in.

    rts
.endproc


; reset the keyboard to the 0th row, 0th column.
; changes: A
.proc reset
    lda #(JOYPAD1_K | JOYPAD1_R)
    sta Const::JOYPAD1
    lda #(JOYPAD1_K | JOYPAD1_C)
    sta Ram::FamilyBasic::zbJoypad1State
    jmp delay
    ; [tail_jump]
.endproc


; select the next section of the keyboard matrix by toggling the column bit.
; changes: A
.proc next
    lda Ram::FamilyBasic::zbJoypad1State
    eor #JOYPAD1_C
    sta Ram::FamilyBasic::zbJoypad1State
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
