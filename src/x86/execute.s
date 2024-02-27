
.include "x86/execute.inc"
.include "x86/reg.inc"
.include "x86.inc"

.export execute

.segment "RODATA"

; instruction types
.enum
    IN0 ; INC 16
    IN1 ; DEC 16
    IN2 ; ADD 8
    IN3 ; ADD 16
    IN4 ; SUB 8
    IN5 ; SUB 16
    IN6 ; MOV

    BAD = <-1
.endenum

; map x86 opcodes to their instruction type.
; i.e. opcodes $40, $41, $42, and $43 are all INC instructions.
; this is used to determine which handler function should be called for an instruction.
rbaOpcodeInstruction:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,IN2,IN3,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,IN4,IN5,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte IN0,IN0,IN0,IN0,IN0,IN0,IN0,IN0,IN1,IN1,IN1,IN1,IN1,IN1,IN1,IN1 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6,IN6 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

; map instructions, not opcodes, to their execution functions.
rbaExecuteFuncLo:
.byte <(execute_inc_16-1)
.byte <(execute_dec_16-1)
.byte <(execute_add_8-1)
.byte <(execute_add_16-1)
.byte <(execute_sub_8-1)
.byte <(execute_sub_16-1)
.byte <(execute_mov-1)
rbaExecuteFuncHi:
.byte >(execute_inc_16-1)
.byte >(execute_dec_16-1)
.byte >(execute_add_8-1)
.byte >(execute_add_16-1)
.byte >(execute_sub_8-1)
.byte >(execute_sub_16-1)
.byte >(execute_mov-1)
rbaExecuteFuncEnd:

; ==============================================================================
; public interface
; ==============================================================================

; execute the current instruction.
.proc execute
    ; find the instruction that this opcode maps to.
    ldx Reg::zbInstrOpcode
    ldy rbaOpcodeInstruction, x

    ; check for an unsupported instruction.
    ; check for an unsupported instruction.
    cpy #BAD
    bne not_bad
    lda #X86::Err::EXECUTE_BAD
    jsr X86::panic
not_bad:

    ; check for an unsupported encoding.
    cpy #(rbaExecuteFuncEnd - rbaExecuteFuncHi)
    bcc func_ok
    lda #X86::Err::EXECUTE_FUNC
    jsr X86::panic
func_ok:

    ; find the correct handler for this instruction.
    lda rbaExecuteFuncHi, y
    pha
    lda rbaExecuteFuncLo, y
    pha
    rts
.endproc


; ==============================================================================
; execution handlers
; ==============================================================================

; TODO: optimize jsr rts

.proc execute_inc_16
    ; write $0001 to source 1 so we can use a generic add function.
    ldx #1
    stx Reg::zdS1
    dex
    stx Reg::zdS1+1

    clc
    ldy #2
    jsr add_with_carry

    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_add_16

    rts
.endproc


.proc execute_dec_16
    ; write $0001 to source 1 so we can use a generic subtract function.
    ldx #1
    stx Reg::zdS1
    dex
    stx Reg::zdS1+1

    sec
    ldy #2
    jsr sub_with_borrow

    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_sub_16

    rts
.endproc


.proc execute_add_8
    clc
    ldy #1
    jsr add_with_carry

    jsr set_carry_flag_add_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_add_8

    rts
.endproc


.proc execute_add_16
    clc
    ldy #2
    jsr add_with_carry

    jsr set_carry_flag_add_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_add_16

    rts
.endproc


.proc execute_sub_8
    sec
    ldy #1
    jsr sub_with_borrow

    jsr set_carry_flag_sub_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_sub_8

    rts
.endproc


.proc execute_sub_16
    sec
    ldy #2
    jsr sub_with_borrow

    jsr set_carry_flag_sub_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_sub_16

    rts
.endproc


.proc execute_mov
    rts
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; < Y = number of bytes to add
; < C = initial carry
.proc add_with_carry
    ldx #0
loop:
    lda Reg::zdS0, x
    adc Reg::zdS1, x
    sta Reg::zdD0, x
    inx
    dey
    bne loop
    rts
.endproc

; < Y = number of bytes to add
; < C = initial borrow
.proc sub_with_borrow
    ldx #0
loop:
    lda Reg::zdS0, x
    sbc Reg::zdS1, x
    sta Reg::zdD0, x
    inx
    dey
    bne loop
    rts
.endproc

; ==============================================================================
; set flags based on execution result
; ==============================================================================


; set the carry flag based the result of an 8-bit addition.
.proc set_carry_flag_add_8
    lda Reg::zdD0
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 16-bit addition.
.proc set_carry_flag_add_16
    lda Reg::zdD0
    ora Reg::zdD0+1
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 8-bit addition.
.proc set_carry_flag_sub_8
    lda Reg::zdD0
    eor #$ff
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 16-bit addition.
.proc set_carry_flag_sub_16
    lda Reg::zdD0
    ora Reg::zdD0+1
    eor #$ff
    beq set_carry_flag
    bne clear_carry_flag
.endproc


clear_carry_flag:
    lda #<Reg::FLAG_CF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_carry_flag:
    lda #<Reg::FLAG_CF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the parity flag based the result of an execution.
; only considers the lowest 8 bits
.proc set_parity_flag
    ; count the number of set bits
    ldx #0
    lda Reg::zdD0
loop:
    cmp #0
    beq done
    lsr a
    bcc loop
    inx
    bne loop
done:

    ; check if the number of set bits is odd or even
    txa
    lsr
    ; set or clear the parity flag accordingly
    bcc set_flag ; branch if even number of bits
    lda #<Reg::FLAG_PF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    lda #<Reg::FLAG_PF
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the auxiliary carry flag if addition caused a carry in the low nibble.
.proc set_auxiliary_flag_add
    lda Reg::zdD0
    and #$0f
    beq set_auxiliary_flag
    bne clear_auxiliary_flag
.endproc


; set the auxiliary carry flag if subtraction caused a carry in the low nibble.
.proc set_auxiliary_flag_sub
    lda Reg::zdD0
    and #$0f
    eor #$0f
    beq set_auxiliary_flag
    bne clear_auxiliary_flag
.endproc


clear_auxiliary_flag:
    lda #<Reg::FLAG_AF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_auxiliary_flag:
    lda #<Reg::FLAG_AF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the zero flag if an 8-bit operation resulted in an output of 0.
.proc set_zero_flag_8
    lda Reg::zdD0
    beq set_zero_flag
    bne clear_zero_flag
.endproc


; set the zero flag if a 16-bit operation resulted in an output of 0.
.proc set_zero_flag_16
    lda Reg::zdD0
    ora Reg::zdD0+1
    beq set_zero_flag
    bne clear_zero_flag
.endproc


clear_zero_flag:
    lda #<Reg::FLAG_ZF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_zero_flag:
    lda #<Reg::FLAG_ZF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_8
    lda Reg::zdD0
    bmi set_sign_flag
    bpl clear_sign_flag
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_16
    lda Reg::zdD0+1
    bmi set_sign_flag
    bpl clear_sign_flag
.endproc


clear_sign_flag:
    lda #<Reg::FLAG_SF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_sign_flag:
    lda #<Reg::FLAG_SF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the overflow flag if 8-bit addition caused an arithmetic overflow.
.proc set_overflow_flag_add_8
    lda Reg::zdS0
    eor Reg::zdS1
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zdS0
    eor Reg::zdD0
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if 16-bit addition caused an arithmetic overflow.
.proc set_overflow_flag_add_16
    lda Reg::zdS0+1
    eor Reg::zdS1+1
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zdS0+1
    eor Reg::zdD0+1
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if subtraction caused an arithmetic overflow.
.proc set_overflow_flag_sub_8
    lda Reg::zdS0
    eor Reg::zdS1
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zdS0
    eor Reg::zdD0
    bpl clear_overflow_flag ; branch if source 1 and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if subtraction caused an arithmetic overflow.
.proc set_overflow_flag_sub_16
    lda Reg::zdS0+1
    eor Reg::zdS1+1
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zdS0+1
    eor Reg::zdD0+1
    bpl clear_overflow_flag ; branch if source 1 and destination have the same sign
    bmi set_overflow_flag ; branch if source 1 and destination have the same sign
.endproc


set_overflow_flag:
    lda #>Reg::FLAG_OF
    jmp Reg::set_flag_hi ; jsr rts -> jmp
clear_overflow_flag:
    lda #>Reg::FLAG_OF
    jmp Reg::clear_flag_hi ; jsr rts -> jmp
