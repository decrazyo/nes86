
; this module handles x86 arithmetic and logic operations.
; functions are written to only utilize the A register, C flag, and RAM.
; arguments are passed in through source pseudo-registers.
; source pseudo-registers are not modified.
; results are written to destination pseudo-registers.
; some complex operations also use temporary RAM addresses.
; this module does not access the x86 flags register.
;
; this module contains some "extended" ALU functions that do not follow the above rules.
; they utilize X and Y to pass zero-page addresses to use as source and destination address.
; these functions are more flexible at the cost of size and cycles.
;
; this module also contains some special-purpose ALU functions.
; these are intended to perform common operations that would be difficult/inefficient
; to reproduce with other ALU functions.
; e.g. computing 20-bit x86 addresses.
;
; see also:
;   x86/reg.s
;   tmp.s

.include "x86/alu.inc"
.include "x86/reg.inc"

.include "const.inc"
.include "mmc5.inc"
.include "tmp.inc"

.export inc_16
.export inc_8

.export dec_16
.export dec_8

.export add_16_16
.export add_8_8

.export adc_16_16
.export adc_8_8

.export sub_16_16
.export sub_8_8

.export sbb_16_16
.export sbb_8_8

.export mul_16_16
.export mul_8_8

.export div_32_16
.export div_16_8

.export aam_8_8

.export imul_16_16
.export imul_8_8

.export idiv_32_16
.export idiv_16_8

.export neg_16
.export neg_8

.export not_16
.export not_8

.export and_16_16
.export and_8_8

.export or_16_16
.export or_8_8

.export xor_16_16
.export xor_8_8

.export shl_16_8
.export shl_8_8

.export shr_16_8
.export shr_8_8

.export sar_16_8
.export sar_8_8

.export rol_16_8
.export rol_8_8

.export ror_16_8
.export ror_8_8

.export rcl_16_8
.export rcl_8_8

.export rcr_16_8
.export rcr_8_8

.segment "CODE"

; TODO: examine shift/rotate functions.
;       i think there are some performance improvements that can be made there.

; 16-bit increment. D0X = S0X + 1.
; < S0X
; > D0X
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc inc_16
    clc
    lda Reg::zwS0X
    adc #1
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    adc #0
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit increment. D0L = S0L + 1.
; < S0L
; > D0L
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc inc_8
    clc
    lda Reg::zbS0L
    adc #1
    sta Reg::zbD0L
    rts
.endproc


; 16-bit decrement. D0X = S0X - 1.
; < S0X
; > D0X
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc dec_16
    sec
    lda Reg::zwS0X
    sbc #1
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sbc #0
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit decrement. D0L = S0L - 1.
; < S0L
; > D0L
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc dec_8
    sec
    lda Reg::zbS0L
    sbc #1
    sta Reg::zbD0L
    rts
.endproc


; 16-bit addition. D0X = S0X + S1X.
; < S0X
; < S1X
; > D0X
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc add_16_16
    clc
    ; [fall_through]
.endproc

; 16-bit addition with carry. D0X = S0X + S1X + C.
; < S0X
; < S1X
; < C
; > D0X
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc adc_16_16
    lda Reg::zwS0X
    adc Reg::zwS1X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    adc Reg::zwS1X+1
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit addition. D0L = S0L + S1L.
; < S0L
; < S1L
; > D0L
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc add_8_8
    clc
    ; [fall_through]
.endproc

; 8-bit addition with carry. D0L = S0L + S1L + C.
; < S0L
; < S1L
; < C
; > D0L
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc adc_8_8
    lda Reg::zbS0L
    adc Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit subtraction. D0X = S0X - S1X.
; < S0X
; < S1X
; > D0X
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc sub_16_16
    sec
    ; [fall_through]
.endproc

; 16-bit subtraction with borrow. D0X = S0X - S1X - ~C.
; < S0X
; < S1X
; < C
; > D0X
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc sbb_16_16
    lda Reg::zwS0X
    sbc Reg::zwS1X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sbc Reg::zwS1X+1
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit subtraction. D0L = S0L - S1L.
; < S0L
; < S1L
; > D0L
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc sub_8_8
    sec
    ; [fall_through]
.endproc

; 8-bit subtraction with borrow. D0L = S0L - S1L - ~C.
; < S0L
; < S1L
; < C
; > D0L
; > C = 0 if overflow occurs
;   C = 1 otherwise
; changes: A
.proc sbb_8_8
    lda Reg::zbS0L
    sbc Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit unsigned multiplication. D1X:D0X = S0X * S1X
; < S0X = multiplicand
; < S1X = multiplier
; > D0X = product low
; > D1X = product high
; changes: A, C
.proc mul_16_16
    ; 4 calls to the MMC5's built-in multiplier and some addition
    ; will achieve 16-bit unsigned multiplication.

    ; D0X = S0L * S1L
    lda Reg::zbS0L
    sta Mmc5::MULT_LO
    lda Reg::zbS1L
    sta Mmc5::MULT_HI

    lda Mmc5::MULT_LO
    sta Reg::zbD0L
    lda Mmc5::MULT_HI
    sta Reg::zbD0H

    ; D1X = S0H * S1H
    lda Reg::zbS0H
    sta Mmc5::MULT_LO
    lda Reg::zbS1H
    sta Mmc5::MULT_HI

    lda Mmc5::MULT_LO
    sta Reg::zbD1L
    lda Mmc5::MULT_HI
    sta Reg::zbD1H

    ; D1X:D0X += (S0L * S1H) << 8
    lda Reg::zbS0L
    sta Mmc5::MULT_LO
    lda Reg::zbS1H
    sta Mmc5::MULT_HI

    clc

    lda Mmc5::MULT_LO
    adc Reg::zbD0H
    sta Reg::zbD0H

    lda Mmc5::MULT_HI
    adc Reg::zbD1L
    sta Reg::zbD1L

    lda #0
    adc Reg::zbD1H
    sta Reg::zbD1H

    ; D1X:D0X += (S0H * S1L) << 8
    lda Reg::zbS0H
    sta Mmc5::MULT_LO
    lda Reg::zbS1L
    sta Mmc5::MULT_HI

    clc

    lda Mmc5::MULT_LO
    adc Reg::zbD0H
    sta Reg::zbD0H

    lda Mmc5::MULT_HI
    adc Reg::zbD1L
    sta Reg::zbD1L

    lda #0
    adc Reg::zbD1H
    sta Reg::zbD1H

    rts
.endproc


; 8-bit unsigned multiplication. D0X = S0L * S1L
; < S0L = multiplicand
; < S1L = multiplier
; > D0X = product
; changes: A
.proc mul_8_8
    ; we'll take advantage of the MMC5's built-in multiplier
    ; to handle multiplying 8-bit numbers
    lda Reg::zbS0L
    sta Mmc5::MULT_LO
    lda Reg::zbS1L
    sta Mmc5::MULT_HI

    lda Mmc5::MULT_LO
    sta Reg::zwD0X
    lda Mmc5::MULT_HI
    sta Reg::zwD0X+1

    rts
.endproc


; 32-bit by 16-bit unsigned integer division. D1X:D0X = S1X:S0X / S1X, D2X = S1X:S0X % S1X.
; < S0X = divisor
; < D0X = dividend low
; < D1X = dividend high
; > S1X = quotient
; > D0X = remainder
; > C = 0 success
;   C = 1 error
.proc div_32_16
    ; using temp byte 1 as an iteration counter.
    lda #32
    sta Tmp::zb1

    ; initialize S1X to 0 so we can detect errors
    lda #0
    sta Reg::zwS1X
    sta Reg::zwS1X+1

    ; using temp word 1 as a 16-bit accumulator.
    ; further comments will refer to this as A16.
    sta Tmp::zw1
    sta Tmp::zw1+1

loop:
    dec Tmp::zb1
    bmi store_remainder

    ; shift the dividend into A16 one bit at a time.
    asl Reg::zwD0X
    rol Reg::zwD0X+1
    rol Reg::zwD1X
    rol Reg::zwD1X+1
    rol Tmp::zw1
    rol Tmp::zw1+1

    ; compare A16 to the divisor to determine the next bit of the quotient.
    ; we'll have to use subtraction instead of a normal compare instruction.
    sec
    lda Tmp::zw1
    sbc Reg::zwS0X
    lda Tmp::zw1+1
    sbc Reg::zwS0X+1

    ; C now contains the next bit of the quotient.
    ; rotate it into the quotient destination.
    rol Reg::zwS1X
    rol Reg::zwS1X+1
    bcs done ; branch if the quotient is too big for the destination.

    lda Reg::zwS1X
    lsr
    bcc loop ; branch if A16 < divisor

    ; subtract the divisor.
    lda Tmp::zw1
    sbc Reg::zwS0X
    sta Tmp::zw1
    lda Tmp::zw1+1
    sbc Reg::zwS0X+1
    sta Tmp::zw1+1
    bcs loop ; branch always

store_remainder:
    ; store the remainder
    lda Tmp::zw1
    sta Reg::zwD0X
    lda Tmp::zw1+1
    sta Reg::zwD0X+1

    clc ; success
done:
    rts
.endproc


; 16-bit by 8-bit unsigned integer division. D0L = S0X / S1L, D1L = S0X % S1L.
; < S0L = divisor
; < D0X = dividend
; > S1L = quotient
; > D0L = remainder
; > C = 0 success
;   C = 1 error
; changes: A, temp
.proc div_16_8
    ; using temp byte 3 as an iteration counter.
    lda #16
    sta Tmp::zb3

    ; initialize S1L to 0 so we can detect errors
    lda #0
    sta Reg::zbS1L

loop:
    dec Tmp::zb3
    bmi store_remainder

    ; shift the dividend into A one bit at a time.
    asl Reg::zwD0X
    rol Reg::zwD0X+1
    rol

    ; compare A to the divisor to determine the next bit of the quotient.
    cmp Reg::zbS0L
    rol Reg::zbS1L
    bcs done ; branch if the quotient is too big for the destination.

    cmp Reg::zbS0L
    bcc loop ; branch if A < divisor

    ; subtract the divisor.
    sbc Reg::zbS0L
    bcs loop ; branch always

store_remainder:
    sta Reg::zbD0L
    clc
done:
    rts
.endproc


; 8-bit unsigned integer division. D1L = S0L / S1L, D0L = S0L % S1L.
; note that the quotient and remainder are swapped compared to the other div functions.
; < S0L = dividend
; < S1L = divisor
; > D0L = remainder
; > D1L = quotient
; > C = 0 success.
;   C = 1 error.
; on error:
; changes: A, temp
.proc aam_8_8
    ; copy the dividend to D0L.
    ; D0L will be destroyed by the calculation.
    lda Reg::zbS0L
    sta Reg::zbD0L

    ; using temp byte 3 as an iteration counter.
    lda #8
    sta Tmp::zb3

    lda #0

loop:
    dec Tmp::zb3
    bmi store_remainder

    ; shift the dividend into A one bit at a time.
    asl Reg::zbD0L
    rol

    ; compare A to the divisor to determine the next bit of the quotient.
    cmp Reg::zbS1L
    rol Reg::zbD1L

    cmp Reg::zbS1L
    bcc loop ; branch if A < divisor

    ; subtract the divisor.
    sbc Reg::zbS1L
    bcs loop ; branch always

store_remainder:
    sta Reg::zbD0L
    rts
.endproc


; 16-bit signed multiplication
; < S0X = multiplicand
; < S1X = multiplier
; > D0X = product low
; > D1X = product high
.proc imul_16_16
    ; calculate the result's sign
    lda Reg::zwS0X+1
    eor Reg::zwS1X+1
    pha

    ; negate the operands if they are negative
    lda Reg::zwS0X+1
    bpl positive_multiplicand
    sec
    lda #0
    sbc Reg::zwS0X
    sta Reg::zwS0X
    lda #0
    sbc Reg::zwS0X+1
    sta Reg::zwS0X+1

positive_multiplicand:
    lda Reg::zwS1X+1
    bpl positive_multiplier
    sec
    lda #0
    sbc Reg::zwS1X
    sta Reg::zwS1X
    lda #0
    sbc Reg::zwS1X+1
    sta Reg::zwS1X+1

positive_multiplier:
    jsr mul_16_16

    ; get the result's sign
    pla
    bpl done ; branch if the result should remain positive

    ; negate the result
    sec
    lda #0
    sbc Reg::zwD0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwD0X+1
    sta Reg::zwD0X+1
    lda #0
    sbc Reg::zwD1X
    sta Reg::zwD1X
    lda #0
    sbc Reg::zwD1X+1
    sta Reg::zwD1X+1

done:
    rts
.endproc


; 8-bit signed multiplication
; < S0L = multiplicand
; < S1L = multiplier
; > D0X = product
.proc imul_8_8
    ; calculate the result's sign
    lda Reg::zbS0L
    eor Reg::zbS1L
    pha

    ; negate the operands if they are negative
    lda Reg::zbS0L
    bpl positive_multiplicand
    clc
    eor #$ff
    adc #1
    sta Reg::zbS0L

positive_multiplicand:
    lda Reg::zbS1L
    bpl positive_multiplier
    clc
    eor #$ff
    adc #1
    sta Reg::zbS1L

positive_multiplier:
    jsr mul_8_8

    ; get the result's sign
    pla
    bpl done ; branch if the result should remain positive

    ; negate the result
    sec
    lda #0
    sbc Reg::zwD0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwD0X+1
    sta Reg::zwD0X+1

done:
    rts
.endproc


; 32-bit by 16-bit signed division
; < S0X = divisor
; < D0X = dividend low
; < D1X = dividend high
; > S1X = quotient
; > D0X = remainder
; > C = 0 success
;   C = 1 error
.proc idiv_32_16
    lda Reg::zwD1X+1 ; dividend's sign
    pha ; remainder's sign
    eor Reg::zwS0X+1 ; divisor's sign
    pha ; quotient's sign

    ; negate the operands if they are negative
    lda Reg::zwS0X+1
    bpl positive_divisor
    sec
    lda #0
    sbc Reg::zwS0X
    sta Reg::zwS0X
    lda #0
    sbc Reg::zwS0X+1
    sta Reg::zwS0X+1

positive_divisor:
    lda Reg::zwD1X+1
    bpl positive_dividend
    sec
    lda #0
    sbc Reg::zwD0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwD0X+1
    sta Reg::zwD0X+1
    lda #0
    sbc Reg::zwD1X
    sta Reg::zwD1X
    lda #0
    sbc Reg::zwD1X+1
    sta Reg::zwD1X+1

positive_dividend:
    jsr div_32_16

    ; get the quotient's sign
    pla
    bcs div_error ; branch if there was a division error
    bpl positive_quotient ; branch if the quotient should be positive

    ; negate the quotient
    sec
    lda #0
    sbc Reg::zwS1X
    sta Reg::zwS1X
    lda #0
    sbc Reg::zwS1X+1
    sta Reg::zwS1X+1

    ; the quotient should be negative or zero
    bmi negative_quotient
    beq negative_quotient
    bpl idiv_error ; branch if the quotient is positive

positive_quotient:
    ; the quotient should be positive.
    lda Reg::zwS1X+1
    bmi idiv_error ; branch if the quotient is negative

negative_quotient:

    ; get the remainder's sign
    pla
    bpl success ; branch if the remainder should be positive

    ; negate the remainder
    sec
    lda #0
    sbc Reg::zwD0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwD0X+1
    sta Reg::zwD0X+1

success:
    clc
    rts

idiv_error:
    sec
div_error:
    pla
    rts
.endproc


; 16-bit by 8-bit signed division
; < S0L = divisor
; < D0X = dividend
; > S1L = quotient
; > D0L = remainder
; > C = 0 success
;   C = 1 error
.proc idiv_16_8
    lda Reg::zwD0X+1 ; dividend's sign
    pha ; remainder's sign
    eor Reg::zbS0L ; divisor's sign
    pha ; quotient's sign

    ; negate the operands if they are negative
    lda Reg::zbS0L
    bpl positive_divisor
    clc
    eor #$ff
    adc #1
    sta Reg::zbS0L

positive_divisor:
    lda Reg::zwD0X+1
    bpl positive_dividend
    sec
    lda #0
    sbc Reg::zwD0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwD0X+1
    sta Reg::zwD0X+1

positive_dividend:
    jsr div_16_8

    ; get the quotient's sign
    pla
    bcs div_error ; branch if there was a division error
    bpl positive_quotient ; branch if the quotient should be positive

    ; negate the quotient
    sec
    lda #0
    sbc Reg::zbS1L
    sta Reg::zbS1L

    ; the quotient should be negative or zero
    bmi negative_quotient
    beq negative_quotient
    bpl idiv_error ; branch if the quotient is positive

positive_quotient:
    ; the quotient should be positive.
    lda Reg::zbS1L
    bmi idiv_error ; branch if the quotient is negative

negative_quotient:

    ; get the remainder's sign
    pla
    bpl success ; branch if the remainder should be positive

    ; negate the remainder
    sec
    lda #0
    sbc Reg::zbD0L
    sta Reg::zbD0L

success:
    clc
    rts

idiv_error:
    sec
div_error:
    pla
    rts
.endproc


; 16-bit two's complement negation. D0X = 0 - S0X
; < S0X
; > D0X
; > C
; changes: A, C
.proc neg_16
    sec
    lda #0
    sbc Reg::zwS0X
    sta Reg::zwD0X
    lda #0
    sbc Reg::zwS0X+1
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit two's complement negation. D0L = 0 - S0L
; < S0L
; > D0L
; > C
; changes: A, C
.proc neg_8
    sec
    lda #0
    sbc Reg::zbS0L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit one's complement negation. D0X = S0X ^ $ffff
; < S0X
; > D0X
; changes: A, C
.proc not_16
    lda Reg::zwS0X+1
    eor #$ff
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; 8-bit one's complement negation. D0L = S0L ^ $ff
; < S0L
; > D0L
; changes: A, C
.proc not_8
    lda Reg::zbS0L
    eor #$ff
    sta Reg::zbD0L
    rts
.endproc


; 16-bit bitwise and. D0X = S0X & S1X
; < S0X
; < S1X
; > D0X
; changes: A
.proc and_16_16
    lda Reg::zwS0X+1
    and Reg::zwS1X+1
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; 8-bit bitwise and. D0L = S0L & S1L
; < S0L
; < S1L
; > D0L
; changes: A
.proc and_8_8
    lda Reg::zbS0L
    and Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit bitwise inclusive or. D0X = S0X | S1X
; < S0X
; < S1X
; > D0X
; changes: A
.proc or_16_16
    lda Reg::zwS0X+1
    ora Reg::zwS1X+1
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; 8-bit bitwise inclusive or. D0L = S0L | S1L
; < S0L
; < S1L
; > D0L
; changes: A
.proc or_8_8
    lda Reg::zbS0L
    ora Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit bitwise exclusive or. D0X = S0X ^ S1X
; < S0X
; < S1X
; > D0X
; changes: A
.proc xor_16_16
    lda Reg::zwS0X+1
    eor Reg::zwS1X+1
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; 8-bit bitwise exclusive or. D0L = S0L ^ S1L
; < S0L
; < S1L
; > D0L
; changes: A
.proc xor_8_8
    lda Reg::zbS0L
    eor Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit logical shift left. C:D0X = S0X:0 << S1L
; C is unchanged if S1L == 0
; < S0X
; < S1L
; > D0X
; > C = (S0X << (S1L - 1)).15
; changes: A, D1L
.proc shl_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    asl Reg::zwD0X
    rol Reg::zwD0X+1
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit logical shift left. C:D0L = S0L:0 << S1L
; C is unchanged if S1L == 0
; < S0L
; < S1L
; > D0L
; > C = (S0L << (S1L - 1)).7
; changes: A, D1L
.proc shl_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    asl Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit logical shift right. D0X:C = 0:S0X >> S1L
; C is unchanged if S1L == 0
; < S0X
; < S1L
; > D0X
; > C = (S0X >> (S1L - 1)).0
; changes: A, D1L
.proc shr_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lsr Reg::zwD0X+1
    ror Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit logical shift right. D0L:C = 0:S0L >> S1L
; C is unchanged if S1L == 0
; < S0L
; < S1L
; > D0L
; > C = (S0L << (S1L - 1)).0
; changes: A, D1L
.proc shr_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lsr Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit arithmetic shift right. D0X:C = S0X.15:S0X >> S1L
; C is unchanged if S1L == 0
; < S0X
; < S1L
; > D0X
; > C = (S0X >> (S1L - 1)).0
; changes: A, D1L
.proc sar_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zwD0X+1
    rol
    ror Reg::zwD0X+1
    ror Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit arithmetic shift right. D0L:C = S0L.7:S0L >> S1L
; C is unchanged if S1L == 0
; < S0L
; < S1L
; > D0L
; > C = (S0L >> (S1L - 1)).0
; changes: A, D1L
.proc sar_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zbD0L
    rol
    ror Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate left S1L times. D0X = (S0X << (D1L % 16)) | (S0X >> 16-(D1L % 16))
; C is unchanged if S1L == 0
; < S0X
; < S1L
; > D0X
; > C = (S0X << ((D1L % 16) - 1)).15
; changes: A, D1L
.proc rol_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zwD0X+1
    rol
    rol Reg::zwD0X
    rol Reg::zwD0X+1
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate left S1L times. D0X = (S0L << (D1L % 8)) | (S0L >> 8-(D1L % 8))
; C is unchanged if S1L == 0
; < S0L
; < S1L
; > D0L
; > C = (S0X << ((D1L % 8) - 1)).7
; changes: A, D1L
.proc rol_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zbD0L
    rol
    rol Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate right S1L times. D0X = (S0X >> (D1L % 16)) | (S0X << 16-(D1L % 16))
; C is unchanged if S1L == 0
; < S0X
; < S1L
; > D0X
; > C = (S0X >> ((D1L % 16) - 1)).0
; changes: A, D1L
.proc ror_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zwD0X
    ror
    ror Reg::zwD0X+1
    ror Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts

.endproc


; 8-bit rotate right S1L times. D0X = (S0L >> (D1L % 8)) | (S0L << 8-(D1L % 8))
; C is unchanged if S1L == 0
; < S0L
; < S1L
; > D0L
; > C = (S0X >> ((D1L % 8) - 1)).7
; changes: A, D1L
.proc ror_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    lda Reg::zbD0L
    ror
    ror Reg::zbD0L

    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate left S1L times through C. D0X = (S0X << (D1L % 17)) | (S0X >> 17-(D1L % 17))
; C is unchanged if S1L == 0
; < S0X
; < S1L
; < C
; > D0X
; > C = (S0X << ((D1L % 17) - 1)).15
; changes: A, D1L
.proc rcl_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    rol Reg::zwD0X
    rol Reg::zwD0X+1
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate left S1L times through C. D0X = (S0L << (D1L % 9)) | (S0L >> 9-(D1L % 9))
; C is unchanged if S1L == 0
; < S0L
; < S1L
; < C
; > D0L
; > C = (S0X << ((D1L % 9) - 1)).7
; changes: A, D1L
.proc rcl_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    rol Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate right S1L times through C. D0X = (S0X >> (D1L % 17)) | (S0X << 17-(D1L % 17))
; C is unchanged if S1L == 0
; < S0X
; < S1L
; < C
; > D0X
; > C = (S0X >> ((D1L % 17) - 1)).0
; changes: A, D1L
.proc rcr_16_8
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    ror Reg::zwD0X+1
    ror Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate right S1L times through C. D0X = (S0L >> (D1L % 9)) | (S0L << 9-(D1L % 9))
; C is unchanged if S1L == 0
; < S0L
; < S1L
; < C
; > D0L
; > C = (S0X >> ((D1L % 9) - 1)).7
; changes: A, D1L
.proc rcr_8_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    beq done
    sta Reg::zbD1L

loop:
    ror Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc
