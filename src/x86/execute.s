
.include "x86/execute.inc"
.include "x86/reg.inc"
.include "x86.inc"

.export execute

.segment "RODATA"

; instruction types
.enum
    IN0 ; INC
    IN1 ; DEC

    BAD = <-1
.endenum

; map x86 opcodes to their instruction type.
; i.e. opcodes $40, $41, $42, and $43 are all INC instructions.
; this is used to determine which handler function should be called for an instruction.
rbaOpcodeInstruction:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte IN0,IN0,IN0,IN0,IN0,IN0,IN0,IN0,IN1,IN1,IN1,IN1,IN1,IN1,IN1,IN1 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

; map instructions, not opcodes, to their execution functions.
rbaExecuteFuncLo:
.byte <(execute_inc_reg16-1)
.byte <(execute_dec_reg16-1)
rbaExecuteFuncHi:
.byte >(execute_inc_reg16-1)
.byte >(execute_dec_reg16-1)
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
    cpy #(rbaExecuteFuncEnd - rbaExecuteFuncHi)
    bcc no_panic
    lda #X86::Err::EXECUTE
    jsr X86::panic
no_panic:

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

.proc execute_inc_reg16
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


.proc execute_dec_reg16
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

; set the parity flag based the result of an execution.
; only considers the lowest 8 bits
.proc set_parity_flag
    ldy #<Reg::FLAG_PF

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
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the auxiliary carry flag if addition caused a carry in the low nibble.
.proc set_auxiliary_flag_add
    ldy #<Reg::FLAG_AF

    lda Reg::zdD0
    and #$0f
    beq set_flag ; branch if carry happened
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the auxiliary carry flag if subtraction caused a carry in the low nibble.
.proc set_auxiliary_flag_sub
    ldy #<Reg::FLAG_AF

    lda Reg::zdD0
    and #$0f
    eor #$0f
    beq set_flag ; branch if carry happened
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the zero flag if an execution resulted in an output of 0.
.proc set_zero_flag_8
    ldy #<Reg::FLAG_ZF

    lda Reg::zdD0
    beq set_flag
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the zero flag if an execution resulted in an output of 0.
.proc set_zero_flag_16
    ldy #<Reg::FLAG_ZF

    lda Reg::zdD0
    ora Reg::zdD0+1
    beq set_flag
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_8
    ldy #<Reg::FLAG_SF

    lda Reg::zdD0
    bmi set_flag ; branch if negative
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_16
    ldy #<Reg::FLAG_SF

    lda Reg::zdD0+1
    bmi set_flag ; branch if negative
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the overflow flag if addition caused an arithmetic overflow.
.proc set_overflow_flag_add_16
    ldy #>Reg::FLAG_OF

    lda Reg::zdS0+1
    eor Reg::zdS1+1
    bmi clear_flag ; branch if source registers have different signs

    lda Reg::zdS0+1
    eor Reg::zdD0+1
    bpl clear_flag ; branch if sources and destination have the same sign

    jmp Reg::set_flag_hi ; jsr rts -> jmp
clear_flag:
    jmp Reg::clear_flag_hi ; jsr rts -> jmp
.endproc


; set the overflow flag if subtraction caused an arithmetic overflow.
.proc set_overflow_flag_sub_16
    ldy #>Reg::FLAG_OF

    lda Reg::zdS0+1
    eor Reg::zdS1+1
    bpl clear_flag ; branch if source registers have the same signs

    lda Reg::zdS0+1
    eor Reg::zdD0+1
    bpl clear_flag ; branch if source 1 and destination have the same sign

    jmp Reg::set_flag_hi ; jsr rts -> jmp
clear_flag:
    jmp Reg::clear_flag_hi ; jsr rts -> jmp
.endproc
