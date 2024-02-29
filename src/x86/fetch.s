
.include "x86/fetch.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.export fetch

.segment "RODATA"

; instruction lengths
.enum
    LN1 = 1
    LN2
    LN3
    LN4
    LN5
    BAD = <-1 ; used for unimplemented or non-existent instructions
.endenum

; map opcodes to instruction length
rbaInstrLength:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,LN2,LN3,BAD,BAD,BAD,BAD,BAD,BAD,LN2,LN3,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,LN2,LN3,BAD,BAD,BAD,BAD,BAD,BAD,LN2,LN3,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1,LN1 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte LN1,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN2,LN3,LN3,LN3,LN3,LN3,LN3,LN3,LN3 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc fetch
    ; read a byte before resetting the instruction length.
    ; this is done to the previous instruction can been seen in debugging output.
    jsr Mmu::get_byte

    ; lookup the new instruction length.
    tax
    ldy rbaInstrLength, x

    ; reset the instruction length.
    ldx #0
    stx Reg::zbInstrLen

    ; A = instruction byte
    ; X = current instruction length
    ; Y = final instruction length

    ; check if this is an unsupported instruction.
    cpy #BAD
    bcc handle_prefix
    bne copy_loop_start
    ; record the instruction byte for debugging.
    sta Reg::zbInstrOpcode
    inc Reg::zbInstrLen
    ; error out
    lda #X86::Err::FETCH_BAD
    jsr X86::panic
handle_prefix:
    ; TODO: handle prefix bytes.
    jmp copy_loop_start

    ; the buffer and buffer length are updated in lockstep in case of crashes.
    ; this is kind of inefficient but worth is for debugging.
copy_loop:
    jsr Mmu::get_byte
copy_loop_start:
    sta Reg::zbInstrOpcode, x
    inc Reg::zbInstrLen
    inx
    cpy Reg::zbInstrLen
    bne copy_loop

    rts
.endproc
