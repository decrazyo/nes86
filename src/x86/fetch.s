
.include "x86/fetch.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"

.export fetch

.segment "RODATA"

; instruction lengths
.enum
    ; opcode directly determines the instruction length
    F00 ; 1 byte instruction
    F01 ; 2 byte instruction
    F02 ; 3 byte instruction
    F03 ; instruction with a ModR/M byte
    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their decoding functions.
rbaFetchFuncLo:
.byte <(fetch_len1-1)
.byte <(fetch_len2-1)
.byte <(fetch_len3-1)
.byte <(fetch_modrm-1)
.byte <(fetch_bad-1)
rbaFetchFuncHi:
.byte >(fetch_len1-1)
.byte >(fetch_len2-1)
.byte >(fetch_len3-1)
.byte >(fetch_modrm-1)
.byte >(fetch_bad-1)
rbaFetchFuncEnd:

.assert (rbaFetchFuncHi - rbaFetchFuncLo) = (rbaFetchFuncEnd - rbaFetchFuncHi), error, "incomplete fetch function"
.assert (rbaFetchFuncHi - rbaFetchFuncLo) = FUNC_COUNT, error, "fetch function count"

; map opcodes to instruction length
rbaInstrLength:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte F03,F03,F03,F03,F01,F02,F00,F00,F03,F03,F03,F03,F01,F02,F00,BAD ; 1_
.byte F03,F03,F03,F03,F01,F02,F00,F00,F03,F03,F03,F03,F01,F02,F00,F00 ; 0_
.byte F03,F03,F03,F03,F01,F02,BAD,BAD,F03,F03,F03,F03,F01,F02,BAD,BAD ; 2_
.byte F03,F03,F03,F03,F01,F02,BAD,BAD,F03,F03,F03,F03,F01,F02,BAD,BAD ; 3_
.byte F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00 ; 4_
.byte F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00,F00 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,F03,F03,F03,F03,F03,BAD,F03,BAD ; 8_
.byte F00,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte F02,F02,F02,F02,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F02,F02,F02,F02,F02,F02,F02,F02 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,F00,BAD,BAD,F00,F00,F00,F00,F00,F00,BAD,BAD ; F_

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc fetch
    ; point the MMU at CS + IP
    lda Reg::zwIP
    sta Tmp::zw0
    lda Reg::zwIP+1
    sta Tmp::zw0+1
    ldy #Reg::Seg::CS
    jsr Mmu::set_address

    ; reset the instruction length
    lda #0
    sta Reg::zbInstrLen

next:
    ; get a byte from memory
    jsr get_ip_byte

    ; lookup the appropriate fetch handler
    tax
    lda rbaInstrLength, x
    tay

    ; call the fetch handler
    ; fetch handlers can expect A to be the most recently read byte
    lda rbaFetchFuncHi, y
    pha
    lda rbaFetchFuncLo, y
    pha
    txa
    rts
.endproc


; most fetch handlers should call this after determining the instruction length.
; < X = current instruction length
; < Reg::zbInstrLen = final instruction length
; if calling copy_bytes::store_first then
; < A = instruction byte
.proc copy_bytes
    jsr get_ip_byte
store_first:
    sta Reg::zbInstrOpcode, x
    inx
    cpx Reg::zbInstrLen
    bcc copy_bytes
    beq done
    ; somehow we have read too much.
    ; TODO: remove this after testing.
    lda #X86::Err::FETCH_LEN
    jmp X86::panic
done:
    rts
.endproc

; ==============================================================================
; fetch handlers.
; ==============================================================================

; handle a simple 1 byte instruction
; < A = instruction byte
.proc fetch_len1
    ldx Reg::zbInstrLen
    ldy #1
    sty Reg::zbInstrLen
    jmp copy_bytes::store_first
.endproc


; handle a simple 2 byte instruction
; < A = instruction byte
.proc fetch_len2
    ldx Reg::zbInstrLen
    ldy #2
    sty Reg::zbInstrLen
    jmp copy_bytes::store_first
.endproc


; handle a simple 3 byte instruction
; < A = instruction byte
.proc fetch_len3
    ldx Reg::zbInstrLen
    ldy #3
    sty Reg::zbInstrLen
    jmp copy_bytes::store_first
.endproc


; handle an instruction with a ModR/M operand
; < A = instruction byte
.proc fetch_modrm
    ; store the opcode
    ldx Reg::zbInstrLen
    sta Reg::zbInstrOpcode, x
    inx
    stx Reg::zbInstrLen

    ; get the ModR/M byte
    jsr get_ip_byte
    tay ; save A for later
    and #Reg::MODRM_MOD_MASK
    bne check_displacement
    ; mod = 00
    ; check if we are dealing with a direct address
    tya
    and #Reg::MODRM_RM_MASK
    cmp #%00000110
    bne register_index ; branch if R/M is a register index
    beq operand16 ; branch if R/M is followed by a direct address

check_displacement:
    eor #Reg::MODRM_MOD_MASK
    beq register_index ; branch if R/M is a register index
    ; mod = 10 or 01 but the value in A has been inverted
    ; A = 01 if 16-bit displacement
    ;   = 10 if 8-bit displacement
    bpl operand16 ; branch if we have a 16-bit displacement address to handle
    ; handle 8-bit displacement address
    tya
    ldy #3 ; opcode(1) + modrm(1) + address(1)
    bne jmp_copy_bytes_store_first; branch always

operand16:
    tya
    ldy #4 ; opcode(1) + modrm(1) + address(2)

jmp_copy_bytes_store_first:
    sty Reg::zbInstrLen
    jmp copy_bytes::store_first

register_index:
    ; mod = 11
    ; handle register index
    sty Reg::zbInstrOpcode, x
    inc Reg::zbInstrLen
    ; no more bytes need to be fetched
    rts
.endproc


; called when an unsupported instruction byte is fetch.
; < A = instruction byte
.proc fetch_bad
    ldx Reg::zbInstrLen
    sta Reg::zbInstrOpcode, x
    inx
    stx Reg::zbInstrLen
    lda #X86::Err::FETCH_FUNC
    jmp X86::panic
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; get a byte from the MMU which is assumed to be pointing at CS + IP.
; increment the MMU's address.
; increment the instruction pointer.
; Mmu::set_address should have been called at least once before this.
; changes: A, Y
.proc get_ip_byte
    jsr Mmu::get_byte
    tay ; save A for later
    jsr Mmu::inc_address
    ; increment the instruction pointer
    inc Reg::zwIP
    bne done
    inc Reg::zwIP+1
done:
    tya
    rts
.endproc
