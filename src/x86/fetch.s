
.include "x86/fetch.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.export fetch

.segment "RODATA"

; instruction encodings
.enum
    ; 1 byte instruction with reg16 in bits 0-2.
    ; INC reg16
    ; DEC reg16
    EN0

    ; special cases
    SP0 = $80 | $00

    BAD = <-1
.endenum

; map x86 opcodes to their reg/mem encoding scheme.
; the encoding scheme is used to determine the length of the instruction
; and how it should be decoded.
; opcode from different instructions may share the same encoding.
; i.e. opcodes for INC reg16 and DEC reg16 have the same encoding.
rbaOpcodeEncoding:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0 ; 4_
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

; map instruction encodings to instruction lengths.
rbaEncodingLength:
.byte $01 ; EN0

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc fetch
    lda #0
    sta Reg::zbInstrLen

    ; read a byte of code.
    ; probably an opcode but maybe a prefix or unsupported instruction.
    jsr Mmu::get_byte

    ; if the byte is an opcode then this will give us its encoding.
    tax
    lda rbaOpcodeEncoding, x

    ; check for an unsupported instruction.
    cmp #BAD
    bne not_bad
    lda #X86::Err::FETCH
    jsr X86::panic
not_bad:

    ; TODO: check for special cases like a prefix byte.

    stx Reg::zbInstrOpcode
    inc Reg::zbInstrLen

    ; use the encoding to determine the length of the instruction.
    sta Reg::zbInstrEnc
    tax
    lda rbaEncodingLength, x

    ; TODO: check for special cases like the length depending on the opcode.

    ; TODO: copy the operands into the instruction buffer.

    rts
.endproc

