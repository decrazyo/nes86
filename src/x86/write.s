
.include "x86/write.inc"
.include "x86/reg.inc"
.include "x86.inc"

.export write

.segment "RODATA"

; instruction encodings
.enum
    ; nothing to write
    WR0
    ; D0 -> 8-bit register embedded in opcode
    WR1
    ; D0 -> 16-bit register embedded in opcode
    WR2
    ; D0 -> AL
    WR3
    ; D0 -> AX
    WR4
    ; D0 -> EIP
    WR5

    BAD = <-1 ; used for unimplemented or non-existent instructions
.endenum

; map instruction encodings to their write functions.
rbaWriteFuncLo:
.byte <(write_nop-1)
.byte <(write_embed_reg8-1)
.byte <(write_embed_reg16-1)
.byte <(write_al-1)
.byte <(write_ax-1)
.byte <(write_eip-1)
rbaWriteFuncHi:
.byte >(write_nop-1)
.byte >(write_embed_reg8-1)
.byte >(write_embed_reg16-1)
.byte >(write_al-1)
.byte >(write_ax-1)
.byte >(write_eip-1)

; map opcodes to instruction encodings
rbaInstrWrite:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,WR3,WR4,BAD,BAD,BAD,BAD,BAD,BAD,WR3,WR4,BAD,BAD ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 1_
.byte BAD,BAD,BAD,BAD,WR3,WR4,BAD,BAD,BAD,BAD,BAD,BAD,WR3,WR4,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,WR3,WR4,BAD,BAD,BAD,BAD,BAD,BAD,WR0,WR0,BAD,BAD ; 3_
.byte WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5,WR5 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte WR0,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte WR1,WR1,WR1,WR1,WR1,WR1,WR1,WR1,WR2,WR2,WR2,WR2,WR2,WR2,WR2,WR2 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

; write data back to memory or registers after execution.
.proc write
    ldx Reg::zbInstrOpcode
    ldy rbaInstrWrite, x

    ; check for an unsupported encoding.
    cpy #(rbaWriteFuncHi - rbaWriteFuncLo)
    bcc func_ok
    lda #X86::Err::WRITE_FUNC
    jsr X86::panic
func_ok:

    lda rbaWriteFuncHi, y
    pha
    lda rbaWriteFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; write back handlers
; ==============================================================================

.proc write_nop
    rts
.endproc

.proc write_embed_reg8
    lda Reg::zbInstrOpcode
    and #Reg::REG_MASK
    jmp Reg::dst0_to_reg8 ; jsr rts -> jmp
.endproc

.proc write_embed_reg16
    lda Reg::zbInstrOpcode
    and #Reg::REG_MASK
    jmp Reg::dst0_to_reg16 ; jsr rts -> jmp
.endproc

.proc write_al
    lda Reg::zdD0
    sta Reg::zdEAX
    rts
.endproc

.proc write_ax
    jsr write_al
    lda Reg::zdD0+1
    sta Reg::zdEAX+1
    rts
.endproc

.proc write_eip
    lda Reg::zdD0
    sta Reg::zdEIP
    lda Reg::zdD0+1
    sta Reg::zdEIP+1
    lda Reg::zdD0+2
    sta Reg::zdEIP+2
    lda Reg::zdD0+3
    sta Reg::zdEIP+3
    rts
.endproc
