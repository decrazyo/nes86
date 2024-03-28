
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

.export cbw
.export cwd

.export inc16
.export inc8

.export dec16
.export dec8

.export add16
.export add8

.export adc16
.export adc8

.export sub16
.export sub8

.export sbb16
.export sbb8

.export mul16
.export mul8

.export div16
.export div8

.export imul16
.export imul8

.export idiv16
.export idiv8

.export neg16
.export neg8

.export not16
.export not8

.export and16
.export and8

.export or16
.export or8

.export xor16
.export xor8

.export shl16
.export shl8

.export shr16
.export shr8

.export sar16
.export sar8

.export rol16
.export rol8

.export ror16
.export ror8

.export rcl16
.export rcl8

.export rcr16
.export rcr8

.segment "CODE"

; sign extend byte to word.
; < S0L
; > D0X
; changes: C
.proc cbw
    lda Reg::zbS0L
    sta Reg::zwD0X
    asl
    lda #$ff
    sbc #0
    sta Reg::zwD0X + 1
    rts
.endproc


; sign extend word to double.
; < S0X
; > D0X
; > D1X
; changes: C
.proc cwd
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    asl
    lda #$ff
    sbc #0
    sta Reg::zwD1X
    sta Reg::zwD1X+1
    rts
.endproc


; 16-bit increment. D0X = S0X + 1.
; < S0X
; > D0X
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc inc16
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
.proc inc8
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
.proc dec16
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
.proc dec8
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
.proc add16
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
.proc adc16
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
.proc add8
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
.proc adc8
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
.proc sub16
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
.proc sbb16
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
.proc sub8
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
.proc sbb8
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
.proc mul16
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
.proc mul8
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


; 16-bit unsigned integer division. D1X:D0X = S1X:S0X / S1X, D2X = S1X:S0X % S1X.
; < S0X = dividend low
; < S1X = dividend high
; < S2X = divisor
; > D0X = quotient low
; > D1X = quotient high
; > D2X = remainder
; > C = 0 success.
;   C = 1 error.
; on error:
; > A = 0 divide by zero.
;   A != 0 16-bit overflow in quotient.
; changes: A, temp
.proc div16
    ; copy the dividend to D2X:D1X.
    ; D2X:D1X will be destroyed by the calculation.
    lda Reg::zwS0X
    sta Reg::zwD1X
    lda Reg::zwS0X+1
    sta Reg::zwD1X+1
    lda Reg::zwS1X
    sta Reg::zwD2X
    lda Reg::zwS1X+1
    sta Reg::zwD2X+1

    ; using temp byte 1 as an iteration counter.
    lda #32
    sta Tmp::zb1

    ; using temp word 1 as a 16-bit accumulator.
    ; further comments will refer to this as A16.
    lda #0
    sta Tmp::zw1
    sta Tmp::zw1+1

loop:
    dec Tmp::zb1
    bmi store_remainder

    ; shift the dividend into A16 one bit at a time.
    asl Reg::zwD1X
    rol Reg::zwD1X+1
    rol Reg::zwD2X
    rol Reg::zwD2X+1
    rol Tmp::zw1
    rol Tmp::zw1+1

    ; shift D1X back one bit.
    ; this will let us shift the high bits of the quotient into.
    ; we'll use this to detect overflow after division.
    ror Reg::zwD1X+1
    ror Reg::zwD1X

    ; compare A16 to the divisor to determine the next bit of the quotient.
    ; we'll have to use subtraction instead of a normal compare instruction.
    sec
    lda Tmp::zw1
    sbc Reg::zwS2X
    lda Tmp::zw1+1
    sbc Reg::zwS2X+1

    ; C now contains the next bit of the quotient.
    ; rotate it into the quotient destination.
    rol Reg::zwD0X
    rol Reg::zwD0X+1
    rol Reg::zwD1X
    rol Reg::zwD1X+1

    lda Reg::zwD0X
    lsr
    bcc loop ; branch if A16 < divisor

    ; subtract the divisor.
    lda Tmp::zw1
    sbc Reg::zwS2X
    sta Tmp::zw1
    lda Tmp::zw1+1
    sbc Reg::zwS2X+1
    sta Tmp::zw1+1
    bcs loop ; branch always

store_remainder:
    ; store the remainder
    lda Tmp::zw1
    sta Reg::zwD2X
    lda Tmp::zw1+1
    sta Reg::zwD2X+1

    sec ; error

    ; check if we divided by zero.
    lda Reg::zwS2X
    beq done ; branch if error
    lda Reg::zwS2X+1
    beq done ; branch if error

    ; check if we overflowed the quotient.
    lda Reg::zwD1X
    bne done ; branch if error
    lda Reg::zwD1X+1
    bne done ; branch if error

    clc ; success
done:
    rts
.endproc


; 8-bit unsigned integer division. D0L = S0X / S1L, D1L = S0X % S1L.
; < S0X = dividend
; < S1L = divisor
; > D0X = quotient
; > D1L = remainder
; > C = 0 success.
;   C = 1 error.
; on error:
; > A = 0 divide by zero.
;   A != 0 8-bit overflow in quotient.
; changes: A, D1H, temp
.proc div8
    ; copy the dividend to D1X.
    ; D1X will be destroyed by the calculation.
    lda Reg::zwS0X
    sta Reg::zwD1X
    lda Reg::zwS0X+1
    sta Reg::zwD1X+1

    ; using temp byte 3 as an iteration counter.
    lda #16
    sta Tmp::zb3

    lda #0

loop:
    dec Tmp::zb3
    bmi store_remainder

    ; shift the dividend into A one bit at a time.
    asl Reg::zwD1X
    rol Reg::zwD1X+1
    rol

    ; compare A to the divisor to determine the next bit of the quotient.
    cmp Reg::zbS1L
    rol Reg::zwD0X
    rol Reg::zwD0X+1 ; error if this ends up being non-zero.

    cmp Reg::zbS1L
    bcc loop ; branch if A < divisor

    ; subtract the divisor.
    sbc Reg::zbS1L
    bcs loop ; branch always

store_remainder:
    sta Reg::zbD1L


    sec ; error

    ; check if we divided by zero.
    lda Reg::zbS1L
    beq done ; branch if error

    ; check if we overflowed the quotient.
    lda Reg::zwD0X+1
    bne done ; branch if error

    clc ; success
done:
    rts
.endproc


; 16-bit signed multiplication
.proc imul16
    rts
.endproc


; 8-bit signed multiplication
.proc imul8
    rts
.endproc


; 16-bit signed division
.proc idiv16
    rts
.endproc


; 8-bit signed division
.proc idiv8
    rts
.endproc


; 16-bit two's complement negation. D0X = (S0X ^ $ffff) + 1
; < S0X
; > D0X
; changes: A, C
.proc neg16
    clc
    lda Reg::zwS0X
    eor #$ff
    adc #1
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    eor #$ff
    adc #0
    sta Reg::zwD0X+1
    rts
.endproc


; 8-bit two's complement negation. D0L = (S0L ^ $ff) + 1
; < S0L
; > D0L
; changes: A, C
.proc neg8
    clc
    lda Reg::zbS0L
    eor #$ff
    adc #1
    sta Reg::zbD0L
    rts
.endproc


; 16-bit one's complement negation. D0X = S0X ^ $ffff
; < S0X
; > D0X
; changes: A, C
.proc not16
    lda Reg::zwS0X+1
    eor #$ff
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; 8-bit one's complement negation. D0L = S0L ^ $ff
; < S0L
; > D0L
; changes: A, C
.proc not8
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
.proc and16
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
.proc and8
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
.proc or16
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
.proc or8
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
.proc xor16
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
.proc xor8
    lda Reg::zbS0L
    eor Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc


; 16-bit logical shift left. C:D0X = S0X:0 << S1L
; < S0X
; < S1L
; > D0X
; > C = (S0X << (S1L - 1)).15
; changes: A, D1L
.proc shl16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    asl Reg::zwD0X
    rol Reg::zwD0X+1
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit logical shift left. C:D0L = S0L:0 << S1L
; < S0L
; < S1L
; > D0L
; > C = (S0L << (S1L - 1)).7
; changes: A, D1L
.proc shl8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    asl Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit logical shift right. D0X:C = 0:S0X >> S1L
; < S0X
; < S1L
; > D0X
; > C = (S0X >> (S1L - 1)).0
; changes: A, D1L
.proc shr16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    lsr Reg::zwD0X+1
    ror Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit logical shift right. D0L:C = 0:S0L >> S1L
; < S0L
; < S1L
; > D0L
; > C = (S0L << (S1L - 1)).0
; changes: A, D1L
.proc shr8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    lsr Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit arithmetic shift right. D0X:C = S0X.15:S0X >> S1L
; < S0X
; < S1L
; > D0X
; > C = (S0X >> (S1L - 1)).0
; changes: A, D1L
.proc sar16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    lda Reg::zwD0X+1
    rol
    lda Reg::zwD0X+1
    ror
    sta Reg::zwD0X+1
    lda Reg::zwD0X
    ror
    sta Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit arithmetic shift right. D0L:C = S0L.7:S0L >> S1L
; < S0L
; < S1L
; > D0L
; > C = (S0L >> (S1L - 1)).0
; changes: A, D1L
.proc sar8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zbD0L
loop:
    rol
    lda Reg::zbD0L
    ror
    sta Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate left S1L times. D0X = (S0X << (D1L % 16)) | (S0X >> 16-(D1L % 16))
; < S0X
; < S1L
; > D0X
; > C = (S0X << ((D1L % 16) - 1)).15
; changes: A, D1L
.proc rol16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zwD0X+1
loop:
    rol
    lda Reg::zwD0X
    rol
    sta Reg::zwD0X
    lda Reg::zwD0X+1
    rol
    sta Reg::zwD0X+1
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate left S1L times. D0X = (S0L << (D1L % 8)) | (S0L >> 8-(D1L % 8))
; < S0L
; < S1L
; > D0L
; > C = (S0X << ((D1L % 8) - 1)).7
; changes: A, D1L
.proc rol8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zbD0L
loop:
    rol
    lda Reg::zbD0L
    rol
    sta Reg::zbD0L
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate right S1L times. D0X = (S0X >> (D1L % 16)) | (S0X << 16-(D1L % 16))
; < S0X
; < S1L
; > D0X
; > C = (S0X >> ((D1L % 16) - 1)).0
; changes: A, D1L
.proc ror16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zwD0X
loop:
    ror
    lda Reg::zwD0X+1
    ror
    sta Reg::zwD0X+1
    lda Reg::zwD0X
    ror
    sta Reg::zwD0X

    dec Reg::zbD1L
    bne loop

done:
    rts

.endproc


; 8-bit rotate right S1L times. D0X = (S0L >> (D1L % 8)) | (S0L << 8-(D1L % 8))
; < S0L
; < S1L
; > D0L
; > C = (S0X >> ((D1L % 8) - 1)).7
; changes: A, D1L
.proc ror8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zbD0L
loop:
    ror
    lda Reg::zbD0L
    ror
    sta Reg::zbD0L

    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 16-bit rotate left S1L times through C. D0X = (S0X << (D1L % 17)) | (S0X >> 17-(D1L % 17))
; < S0X
; < S1L
; > D0X
; > C = (S0X << ((D1L % 17) - 1)).15
; changes: A, D1L
.proc rcl16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    lda Reg::zwD0X
    rol
    sta Reg::zwD0X
    lda Reg::zwD0X+1
    rol
    sta Reg::zwD0X+1

    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate left S1L times through C. D0X = (S0L << (D1L % 9)) | (S0L >> 9-(D1L % 9))
; < S0L
; < S1L
; > D0L
; > C = (S0X << ((D1L % 9) - 1)).7
; changes: A, D1L
.proc rcl8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zbD0L
loop:
    rol
    dec Reg::zbD1L
    bne loop

    sta Reg::zbD0L

done:
    rts
.endproc


; 16-bit rotate right S1L times through C. D0X = (S0X >> (D1L % 17)) | (S0X << 17-(D1L % 17))
; < S0X
; < S1L
; > D0X
; > C = (S0X >> ((D1L % 17) - 1)).0
; changes: A, D1L
.proc rcr16
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

loop:
    lda Reg::zwD0X+1
    ror
    sta Reg::zwD0X+1
    lda Reg::zwD0X
    ror
    sta Reg::zwD0X
    dec Reg::zbD1L
    bne loop

done:
    rts
.endproc


; 8-bit rotate right S1L times through C. D0X = (S0L >> (D1L % 9)) | (S0L << 9-(D1L % 9))
; < S0L
; < S1L
; > D0L
; > C = (S0X >> ((D1L % 9) - 1)).7
; changes: A, D1L
.proc rcr8
    lda Reg::zbS0L
    sta Reg::zbD0L
    lda Reg::zbS1L
    sta Reg::zbD1L
    beq done

    lda Reg::zbD0L
loop:
    ror
    dec Reg::zbD1L
    bne loop

    sta Reg::zbD0L

done:
    rts
.endproc

; ==============================================================================
; extended functions
; ==============================================================================

SRC0_LO = 0
SRC0_HI = 1
SRC1_LO = 2
SRC1_HI = 3
DST0_LO = 0
DST0_HI = 1

; 16-bit addition. [Y] = [X] + [X+2]
; < X
; < Y
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc add16_ex
    clc
    ; [fall_through]
.endproc

; 16-bit addition with carry. [Y] = [X] + [X+2] + C.
; < X
; < Y
; < C
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc adc16_ex
    lda Const::ZERO_PAGE+SRC0_LO, x
    adc Const::ZERO_PAGE+SRC1_LO, x
    sta Const::ZERO_PAGE+DST0_LO, y
    lda Const::ZERO_PAGE+SRC0_HI, x
    adc Const::ZERO_PAGE+SRC1_HI, x
    sta Const::ZERO_PAGE+DST0_HI, y
    rts
.endproc


; 8-bit addition. [Y] = [X] + [X+1].
; < X
; < Y
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc add8_ex
    clc
    ; [fall_through]
.endproc

; 8-bit addition with carry. [Y] = [X] + [X+1] + C.
; < X
; < Y
; < C
; > C = 1 if overflow occurs
;   C = 0 otherwise
; changes: A
.proc adc8_ex
    lda Const::ZERO_PAGE+SRC0_LO, x
    adc Const::ZERO_PAGE+SRC1_LO, x
    sta Const::ZERO_PAGE+DST0_LO, y
    rts
.endproc

; ==============================================================================
; special purpose functions
; ==============================================================================
