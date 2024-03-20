
; This module is responsible for reading x86 instructions from RAM or ROM
; into an instruction buffer.
; This module must only read the x86 address space though the MMU's dedicated
; instruction fetching interface.
; This module must not write to the x86 address space at all.
; This module must only write to the x86 instruction buffer.
;
; uses:
;   Mmu::get_ip_byte
; changes:
;   Reg::zbInstrLen
;   Reg::zbInstrPrefix
;   Reg::zbInstrOpcode
;   Reg::zaInstrOperands

.include "x86/fetch.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.export fetch

.segment "RODATA"

; instruction lengths
.enum
    BAD ; used for unimplemented or non-existent instructions
    ; opcode directly determines the instruction length
    F01 ; 1 byte instruction
    F02 ; 2 byte instruction
    F03 ; 3 byte instruction
    F04 ; 4 byte instruction
    F05 ; 5 byte instruction
    F06 ; instruction with a ModR/M byte
    F07 ; instruction segment prefix
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; map instruction encodings to their decoding functions.
rbaFetchFuncLo:
.byte <(fetch_bad-1)
.byte <(fetch_len-1)
.byte <(fetch_len-1)
.byte <(fetch_len-1)
.byte <(fetch_len-1)
.byte <(fetch_len-1)
.byte <(fetch_modrm-1)
.byte <(fetch_seg_pre-1)
rbaFetchFuncHi:
.byte >(fetch_bad-1)
.byte >(fetch_len-1)
.byte >(fetch_len-1)
.byte >(fetch_len-1)
.byte >(fetch_len-1)
.byte >(fetch_len-1)
.byte >(fetch_modrm-1)
.byte >(fetch_seg_pre-1)
rbaFetchFuncEnd:

.assert (rbaFetchFuncHi - rbaFetchFuncLo) = (rbaFetchFuncEnd - rbaFetchFuncHi), error, "incomplete fetch function"
.assert (rbaFetchFuncHi - rbaFetchFuncLo) = FUNC_COUNT, error, "fetch function count"

; map opcodes to instruction length
rbaInstrLength:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,BAD ; 0_
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,F01 ; 1_
.byte F06,F06,F06,F06,F02,F03,F07,F01,F06,F06,F06,F06,F02,F03,F07,F01 ; 2_
.byte F06,F06,F06,F06,F02,F03,F07,F01,F06,F06,F06,F06,F02,F03,F07,F01 ; 3_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 4_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02 ; 7_
.byte F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,BAD,F06,BAD ; 8_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F05,BAD,BAD,BAD,BAD,BAD ; 9_
.byte F03,F03,F03,F03,BAD,BAD,BAD,BAD,F02,F03,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F03,F03,F03,F03,F03,F03,F03,F03 ; B_
.byte BAD,BAD,F03,F01,BAD,BAD,BAD,BAD,BAD,BAD,F03,F01,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,F03,F03,F05,F02,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,F01,BAD,BAD,F01,F01,F01,F01,F01,F01,BAD,BAD ; F_

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc fetch
    ; reset the instruction length
    lda #0
    sta Reg::zbInstrLen
    sta Reg::zbInstrPrefix

next:
    ; get a byte from memory
    jsr Mmu::get_ip_byte

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
    jsr Mmu::get_ip_byte
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


; handle fixed length instruction
; < A = instruction byte
; < Y = number of bytes to read
.proc fetch_len
    ldx Reg::zbInstrLen
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
    jsr Mmu::get_ip_byte
    tay ; save A for later
    and #Const::MODRM_MOD_MASK
    bne check_displacement
    ; mod = 00
    ; check if we are dealing with a direct address
    tya
    and #Const::MODRM_RM_MASK
    cmp #%00000110
    bne register_index ; branch if R/M is a register index
    beq operand16 ; branch if R/M is followed by a direct address

check_displacement:
    eor #Const::MODRM_MOD_MASK
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


; handle instruction segment prefix
; < A = segment prefix byte
.proc fetch_seg_pre
    sta Reg::zbInstrPrefix
    jmp fetch::next
.endproc
