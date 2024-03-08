
.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export decode

.segment "RODATA"

; instruction encodings
.enum
    D00 ; no operands. nothing to do.
    D01 ; 16-bit register embedded in opcode -> S0
    D02 ; AL -> S0 ; imm8 -> S1
    D03 ; AX -> S0 ; imm16 -> S1
    D04 ; imm8 -> S1
    D05 ; imm16 -> S1
    D06 ; IP -> S0 ; imm8 -> S1
    D07 ; rm8 -> S0 ; reg8 -> S1
    D08 ; rm16 -> S0 ; reg16 -> S1
    D09 ; reg8 -> S0 ; rm8 -> S1
    D10 ; reg16 -> S0 ; rm16 -> S1

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_nop-1)
.byte <(decode_s0_embed_reg16-1)
.byte <(decode_s0_al_s1_imm8-1)
.byte <(decode_s0_ax_s1_imm16-1)
.byte <(decode_s1_imm8-1)
.byte <(decode_s1_imm16-1)
.byte <(decode_s0_ip_s1_imm8-1)
.byte <(decode_s0_modrm_rm8_s1_modrm_reg8-1)
.byte <(decode_s0_modrm_rm16_s1_modrm_reg16-1)
.byte <(decode_s0_modrm_reg8_s1_modrm_rm8-1)
.byte <(decode_s0_modrm_reg16_s1_modrm_rm16-1)
.byte <(decode_bad-1)
rbaDecodeFuncHi:
.byte >(decode_nop-1)
.byte >(decode_s0_embed_reg16-1)
.byte >(decode_s0_al_s1_imm8-1)
.byte >(decode_s0_ax_s1_imm16-1)
.byte >(decode_s1_imm8-1)
.byte >(decode_s1_imm16-1)
.byte >(decode_s0_ip_s1_imm8-1)
.byte >(decode_s0_modrm_rm8_s1_modrm_reg8-1)
.byte >(decode_s0_modrm_rm16_s1_modrm_reg16-1)
.byte >(decode_s0_modrm_reg8_s1_modrm_rm8-1)
.byte >(decode_s0_modrm_reg16_s1_modrm_rm16-1)
.byte >(decode_bad-1)
rbaDecodeFuncEnd:

.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = (rbaDecodeFuncEnd - rbaDecodeFuncHi), error, "incomplete decode function"
.assert (rbaDecodeFuncHi - rbaDecodeFuncLo) = FUNC_COUNT, error, "decode function count"

; map opcodes to instruction encodings
rbaInstrDecode:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte D07,D08,D09,D10,D02,D03,BAD,BAD,D07,D08,D09,D10,D02,D03,BAD,BAD ; 0_
.byte D07,D08,D09,D10,D02,D03,BAD,BAD,D07,D08,D09,D10,D02,D03,BAD,BAD ; 1_
.byte D07,D08,D09,D10,D02,D03,BAD,BAD,D07,D08,D09,D10,D02,D03,BAD,BAD ; 2_
.byte D07,D08,D09,D10,D02,D03,BAD,BAD,D07,D08,D09,D10,D02,D03,BAD,BAD ; 3_
.byte D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01,D01 ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06,D06 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,D07,D08,D09,D10,BAD,BAD,BAD,BAD ; 8_
.byte D00,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte D04,D04,D04,D04,D04,D04,D04,D04,D05,D05,D05,D05,D05,D05,D05,D05 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory needs to be accessed.
; move data into pseudo-registers.
.proc decode
    ldx Reg::zbInstrOpcode
    ldy rbaInstrDecode, x
    lda rbaDecodeFuncHi, y
    pha
    lda rbaDecodeFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; decode handlers.
; ==============================================================================

; do nothing and return.
; used to handle instructions that don't need any decoding.
.proc decode_nop
    rts
.endproc


; handle an opcode that contains an index to a 16-bit register
.proc decode_s0_embed_reg16
    ; lookup the address of the register
    lda Reg::zbInstrOpcode
    and #Reg::OPCODE_REG_MASK
    tay
    ldx Reg::rzbaReg16Map, y

    ; copy the register to S0
    lda Const::ZERO_PAGE, x
    sta Reg::zaS0
    inx
    lda Const::ZERO_PAGE, x
    sta Reg::zaS0+1

    rts
.endproc


; opcode implies that AX is used and a 16-bit operand follows it
.proc decode_s0_ax_s1_imm16
    lda Reg::zwAX+1
    sta Reg::zaS0+1

    lda Reg::zaInstrOperands+1
    sta Reg::zaS1+1

    ; fall through to copy the low bytes
.endproc

; opcode implies that AL is used and an 8-bit operand follows it
.proc decode_s0_al_s1_imm8
    lda Reg::zbAL
    sta Reg::zaS0

    lda Reg::zaInstrOperands
    sta Reg::zaS1
    rts
.endproc


; opcode is followed by a 16-bit operand
.proc decode_s1_imm16
    lda Reg::zaInstrOperands+1
    sta Reg::zaS1+1

    ; fall through to copy the low bytes
.endproc

; opcode is followed by an 8-bit operand
.proc decode_s1_imm8
    lda Reg::zaInstrOperands
    sta Reg::zaS1
    rts
.endproc


; opcode implies that IP is used and an 8-bit operand follows it.
; used for conditional jumps.
.proc decode_s0_ip_s1_imm8
    lda Reg::zwIP
    sta Reg::zaS0
    lda Reg::zwIP+1
    sta Reg::zaS0+1

    lda Reg::zaInstrOperands
    sta Reg::zaS1
    rts
.endproc


.proc decode_s0_modrm_rm8_s1_modrm_reg8
    jsr handle_modrm_rm
    lda Tmp::zb0
    sta Reg::zaS0

    jsr handle_modrm_reg
    lda Tmp::zb0
    sta Reg::zaS1

    rts
.endproc


.proc decode_s0_modrm_rm16_s1_modrm_reg16
    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zaS0
    lda Tmp::zw0+1
    sta Reg::zaS0+1

    jsr handle_modrm_reg
    lda Tmp::zw0
    sta Reg::zaS1
    lda Tmp::zw0+1
    sta Reg::zaS1+1

    rts
.endproc


.proc decode_s0_modrm_reg8_s1_modrm_rm8
    jsr handle_modrm_reg
    lda Tmp::zb0
    sta Reg::zaS0

    jsr handle_modrm_rm
    lda Tmp::zb0
    sta Reg::zaS1

    rts
.endproc


.proc decode_s0_modrm_reg16_s1_modrm_rm16
    jsr handle_modrm_reg
    lda Tmp::zw0
    sta Reg::zaS0
    lda Tmp::zw0+1
    sta Reg::zaS0+1

    jsr handle_modrm_rm
    lda Tmp::zw0
    sta Reg::zaS1
    lda Tmp::zw0+1
    sta Reg::zaS1+1

    rts
.endproc


; called when an unsupported instruction byte is decoded.
; < A = instruction byte
.proc decode_bad
    lda #X86::Err::DECODE_FUNC
    jmp X86::panic
.endproc

; ==============================================================================

.segment "RODATA"

rbaModRMFuncLo:
.byte <(modrm_rm_mode0-1)
.byte <(modrm_rm_mode1-1)
.byte <(modrm_rm_mode2-1)
.byte <(modrm_rm_mode3-1)
rbaModRMFuncHi:
.byte >(modrm_rm_mode0-1)
.byte >(modrm_rm_mode1-1)
.byte >(modrm_rm_mode2-1)
.byte >(modrm_rm_mode3-1)
rbaModRMFuncEnd:

.segment "CODE"

; handle the R/M portion of a ModR/M byte based on the mode.
; for 8-bit operations
; > Tmp::zb0 8-bit data
; for 16-bit operations
; > Tmp::zw0 16-bit data
.proc handle_modrm_rm
    ; use the Mod portion of a ModR/M byte as an index to a function pointer.
    lda Reg::zaInstrOperands
    and #Reg::MODRM_MOD_MASK
    asl ; discard C as it's in an unknown state
    rol
    rol
    tax
    lda rbaModRMFuncHi, x
    pha
    lda rbaModRMFuncLo, x
    pha
    lda Reg::zaInstrOperands
    and #Reg::MODRM_RM_MASK
    rts
.endproc


; handle the reg portion of a ModR/M byte.
; for 8-bit operations
; > Tmp::zb0 8-bit data
; for 16-bit operations
; > Tmp::zw0 16-bit data
.proc handle_modrm_reg
    lda Reg::zaInstrOperands
    and #Reg::MODRM_REG_MASK
    lsr
    lsr
    lsr
    jmp modrm_rm_mode3 ; jsr rts -> jmp
.endproc


; handle pointer in registers or a direct address
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode0
    ; handle pointer in registers
    cmp #%00000110
    beq direct_address ; branch if we have a direct address as an operand

    jsr modrm_get_address
    jmp get_bytes

direct_address:
    lda Reg::zaInstrOperands+1
    sta Tmp::zw0
    lda Reg::zaInstrOperands+2
    sta Tmp::zw0+1

get_bytes:
    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc

; handle pointer in registers + 8-bit signed offset
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode1
    jsr modrm_get_address

    ; add 8-bit signed offset
    ; TODO: handle negative values
    clc
    lda Reg::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda #0
    adc Tmp::zw0+1
    sta Tmp::zw0+1

    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc


; handle pointer in registers + 16-bit unsigned offset
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from memory
.proc modrm_rm_mode2
    jsr modrm_get_address

    ; add 16-bit unsigned offset
    clc
    lda Reg::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda Reg::zaInstrOperands+2
    adc Tmp::zw0+1
    sta Tmp::zw0+1

    jmp modrm_get_bytes ; jsr rts -> jmp
.endproc


; handle register
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = byte(s) read from register
.proc modrm_rm_mode3
    tay

    ; check if the opcode is dealing with 16-bit data
    lda Reg::zbInstrOpcode
    lsr
    bcc reg8 ; branch if 8-bit data is needed

    ldx Reg::rzbaReg16Map, y
    SKIP_WORD
reg8:
    ldx Reg::rzbaReg8Map, y

    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0

    bcc done ; branch if 8-bit data is needed

    inx
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0+1

done:
    rts
.endproc


; calculate a memory address from the register(s) indicated by ModR/M.
; < A = R/M bits of a ModR/M byte
; > Tmp::zw0 = memory address
; changes: A, X, Y
.proc modrm_get_address
    ; grab the contents of a register specified by table 0
    tay
    ldx Reg::rzbaMem0Map, y
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0
    inx
    ldy Const::ZERO_PAGE, x
    sty Tmp::zw0

    cmp #4
    bcc done ; branch if we don't need data from a second register

    ; add the contents of another register specified by table 1
    clc
    tay
    ldx Reg::rzbaMem1Map, y
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0
    inx
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0

done:
    rts
.endproc


.proc modrm_get_bytes
    ; TODO: check for a segment override prefix?

    ldy #Reg::Seg::DS
    jsr Mmu::set_address
    jsr Mmu::get_byte
    sta Tmp::zw0

    ; check if the opcode is dealing with 16-bit data
    lda Reg::zbInstrOpcode
    lsr
    bcc done ; branch if the opcode is operating on 8-bit data

    ; get the next byte
    jsr Mmu::peek_next_byte
    sta Tmp::zw0+1

done:
    rts
.endproc
