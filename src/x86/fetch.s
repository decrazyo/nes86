
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
    ; ADD imm8
    ; SUB imm8
    EN1
    ; ADD imm16
    ; SUB imm16
    EN2
    ; MOV reg8, imm8
    EN3
    ; MOV reg16, imm16
    EN4

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
.byte BAD,BAD,BAD,BAD,EN1,EN2,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN1,EN2,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN4,EN4,EN4,EN4,EN4,EN4,EN4,EN4 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

; map instruction encodings to instruction lengths.
rbaEncodingLength:
.byte $01 ; EN0
.byte $02 ; EN1
.byte $03 ; EN2
.byte $02 ; EN3
.byte $03 ; EN4
rbaEncodingLengthEnd:

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc fetch
    ; read a byte of code.
    ; probably an opcode but maybe a prefix or unsupported instruction.
    jsr Mmu::get_byte

    ldx #0
    stx Reg::zbInstrLen

    ; if the byte is an opcode then this will give us its encoding.
    tax
    lda rbaOpcodeEncoding, x

    ; check for an unsupported instruction.
    cmp #BAD
    bne not_bad
    lda #X86::Err::FETCH_BAD
    jsr X86::panic
not_bad:

    ; TODO: check for special cases like a prefix byte.

    stx Reg::zbInstrOpcode
    inc Reg::zbInstrLen

    ; use the encoding to determine the length of the instruction.
    sta Reg::zbInstrEnc


    ; check for an unsupported instruction.
    cmp #<(rbaEncodingLengthEnd - rbaEncodingLength)
    bcc len_ok
    lda #X86::Err::FETCH_LEN
    jsr X86::panic
len_ok:

    tax
    lda rbaEncodingLength, x
    ldx Reg::zbInstrLen
    sta Reg::zbInstrLen

    ; TODO: check for special cases like the length depending on the opcode.

    ; copy the operands into the instruction buffer.

loop:
    cpx Reg::zbInstrLen
    beq done
    jsr Mmu::get_byte
    sta Reg::zbInstrOpcode, x
    inx
    bne loop
done:
    rts
.endproc
