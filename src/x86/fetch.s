
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
;   Fetch::zbInstrLen
;   Fetch::zbPrefixSegment
;   Fetch::zbInstrOpcode
;   Fetch::zaInstrOperands

.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86.inc"

.include "tmp.inc"
.include "const.inc"

.exportzp zbPrefixSegment
.exportzp zbPrefixOther

.exportzp zbInstrLen
.exportzp zbInstrBuffer
.exportzp zbInstrOpcode
.exportzp zaInstrOperands

.export fetch

.segment "ZEROPAGE"

; segment prefix
; CS, DS, ES, SS
zbPrefixSegment: .res 1

; other mutually exclusive prefixes
; LOCK, REPZ, REPNZ
zbPrefixOther: .res 1

; instruction buffer length
; opcode + operands
; does not include prefixes
zbInstrLen: .res 1

; instruction buffer
zbInstrBuffer:
zbInstrOpcode: .res 1
zaInstrOperands: .res 6

.segment "RODATA"

; map instruction encodings to their decoding functions.
rbaFetchFuncLo:
.byte <(fetch_bad-1)
.byte <(fetch_len_1-1)
.byte <(fetch_len_2-1)
.byte <(fetch_len_3-1)
.byte <(fetch_len_4-1)
.byte <(fetch_len_5-1)
.byte <(fetch_modrm_reg-1)
.byte <(fetch_modrm_ext_1-1)
.byte <(fetch_modrm_ext_2-1)
.byte <(fetch_segment_prefix-1)
.byte <(fetch_other_prefix-1)
rbaFetchFuncHi:
.byte >(fetch_bad-1)
.byte >(fetch_len_1-1)
.byte >(fetch_len_2-1)
.byte >(fetch_len_3-1)
.byte >(fetch_len_4-1)
.byte >(fetch_len_5-1)
.byte >(fetch_modrm_reg-1)
.byte >(fetch_modrm_ext_1-1)
.byte >(fetch_modrm_ext_2-1)
.byte >(fetch_segment_prefix-1)
.byte >(fetch_other_prefix-1)
rbaFetchFuncEnd:

.assert (rbaFetchFuncHi - rbaFetchFuncLo) = (rbaFetchFuncEnd - rbaFetchFuncHi), error, "incomplete fetch function"

; instruction lengths
.enum
    BAD ; used for unimplemented or non-existent instructions
    F01 ; 1 byte instruction
    F02 ; 2 byte instruction
    F03 ; 3 byte instruction
    F04 ; 4 byte instruction
    F05 ; 5 byte instruction
    F06 ; instruction with a ModR/M byte
    F07 ; instruction with a ModR/M byte and 8-bit immediate
    F08 ; instruction with a ModR/M byte and 16-bit immediate
    F09 ; instruction segment prefix
    F10 ; instruction other prefix
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

.assert (rbaFetchFuncHi - rbaFetchFuncLo) = FUNC_COUNT, error, "fetch function count"

; map opcodes to instruction length
rbaInstrFetch:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,BAD ; 0_
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,F01 ; 1_
.byte F06,F06,F06,F06,F02,F03,F09,F01,F06,F06,F06,F06,F02,F03,F09,F01 ; 2_
.byte F06,F06,F06,F06,F02,F03,F09,F01,F06,F06,F06,F06,F02,F03,F09,F01 ; 3_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 4_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02 ; 7_
.byte F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,BAD,F06,BAD ; 8_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F05,BAD,F01,F01,F01,F01 ; 9_
.byte F03,F03,F03,F03,BAD,BAD,BAD,BAD,F02,F03,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F03,F03,F03,F03,F03,F03,F03,F03 ; B_
.byte BAD,BAD,F03,F01,BAD,BAD,BAD,BAD,BAD,BAD,F03,F01,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,F03,F03,F05,F02,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,F01,BAD,BAD,F01,F01,F01,F01,F01,F01,BAD,BAD ; F_

rbaModRMFuncLo:
.byte <(modrm_rm_mode_0-1)
.byte <(modrm_rm_mode_1-1)
.byte <(modrm_rm_mode_2-1)
.byte <(modrm_rm_mode_3-1)
rbaModRMFuncHi:
.byte >(modrm_rm_mode_0-1)
.byte >(modrm_rm_mode_1-1)
.byte >(modrm_rm_mode_2-1)
.byte >(modrm_rm_mode_3-1)
rbaModRMFuncEnd:

.assert (rbaModRMFuncHi - rbaModRMFuncLo) = (rbaModRMFuncEnd - rbaModRMFuncHi), error, "incomplete ModR/M function"

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction bytes into the instruction buffer.
; changes: A, X, Y
; calls fetch handlers with
; < A = instruction byte
; < X = instruction length
; < Y = function index
.proc fetch
    ; reset the instruction length and prefix
    lda #0
    sta Fetch::zbInstrLen
    sta Fetch::zbPrefixSegment

next:
    ; get a byte from memory
    jsr Mmu::get_ip_byte

    ; lookup the appropriate handler
    tax
    ldy rbaInstrFetch, x

    ; call the fetch handler
    lda rbaFetchFuncHi, y
    pha
    lda rbaFetchFuncLo, y
    pha
    txa
    ldx Fetch::zbInstrLen
    rts
.endproc

; ==============================================================================
; fetch handlers.
; ==============================================================================
; see "fetch" for argument descriptions

; called when an unsupported instruction byte is fetch.
.proc fetch_bad
    sta Fetch::zbInstrBuffer, x
    inx
    stx Fetch::zbInstrLen
    lda #X86::Err::FETCH_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc


; handle fixed length 5 byte instruction.
.proc fetch_len_5
    sta Fetch::zbInstrBuffer, x
    inx
    jsr Mmu::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 4 byte instruction.
.proc fetch_len_4
    sta Fetch::zbInstrBuffer, x
    inx
    jsr Mmu::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 3 byte instruction.
.proc fetch_len_3
    sta Fetch::zbInstrBuffer, x
    inx
    jsr Mmu::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 2 byte instruction.
.proc fetch_len_2
    sta Fetch::zbInstrBuffer, x
    inx
    jsr Mmu::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 1 byte instruction.
.proc fetch_len_1
    sta Fetch::zbInstrBuffer, x
    inx
    stx Fetch::zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes a register
; or an opcode extension that doesn't need anything special.
.proc fetch_modrm_reg
    jsr modrm_rm_mode
    stx Fetch::zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 1 byte immediate value.
.proc fetch_modrm_ext_1
    jsr modrm_rm_mode
    jsr modrm_rm_mode_1
    stx Fetch::zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 2 byte immediate value.
.proc fetch_modrm_ext_2
    jsr modrm_rm_mode
    jsr modrm_rm_mode_2
    stx Fetch::zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 1 byte immediate value.
.proc fetch_modrm_ext_1_opt
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jsr modrm_rm_mode_1
done:
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 2 byte immediate value.
.proc fetch_modrm_ext_2_opt
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jsr modrm_rm_mode_2
done:
    rts
.endproc


; fetch segment prefix
.proc fetch_segment_prefix
    sta Fetch::zbPrefixSegment
    jmp fetch::next
    ; [tail_jump]
.endproc


; fetch other prefix
.proc fetch_other_prefix
    sta Fetch::zbPrefixOther
    jmp fetch::next
    ; [tail_jump]
.endproc

; ==============================================================================
; ModR/M mode specific handlers.
; ==============================================================================

; read a ModR/M byte and any additional bytes indicated by the Mod and R/M fields.
.proc modrm_rm_mode
    ; store the instruction byte
    sta Fetch::zbInstrBuffer, x
    inx

    ; store the ModR/M byte
    jsr Mmu::get_ip_byte
    sta Fetch::zbInstrBuffer, x
    inx

    ; move the Mod field into the 2 lowest bits.
    and #Decode::MODRM_MOD_MASK
    asl
    rol
    rol

    ; other CPU stages will probably need this data.
    ; we'll store it so it doesn't need to be computed again later
    ; even though this doesn't really fit the purpose of the "fetch" stage.
    sta Decode::zbMode

    ; use the mode to index a function pointer.
    tay
    lda rbaModRMFuncHi, y
    pha
    lda rbaModRMFuncLo, y
    pha

    ; call ModR/M mode specific handler.
    ; A = garbage
    ; X = instruction length
    ; Y = ModR/M mode
    rts
.endproc


; handle ModR/M mode 0
; possibly fetch 2 more bytes depending on the R/M field value.
.proc modrm_rm_mode_0
    ; grab the ModR/M byte
    lda Fetch::zbInstrBuffer-1, x

    ; assess the R/M field.
    and #Decode::MODRM_RM_MASK
    cmp #Decode::MODRM_RM_DIRECT
    bne modrm_rm_mode_3 ; branch if the R/M field refers to registers.
    ; the R/M field refers to a direct address that we need to fetch.
    ; [tail_branch]
.endproc

; handle ModR/M mode 2
; 16-bit signed offset
; read 2 more byte
.proc modrm_rm_mode_2
    jsr Mmu::get_ip_byte
    sta Fetch::zbInstrBuffer, x
    inx
    ; [fall_through]
.endproc

; handle ModR/M mode 1
; 8-bit signed offset
; read 1 more byte
.proc modrm_rm_mode_1
    jsr Mmu::get_ip_byte
    sta Fetch::zbInstrBuffer, x
    inx
    ; [fall_through]
.endproc

; handle ModR/M mode 3
; the R/M field contains a register index.
; nothing more to do.
.proc modrm_rm_mode_3
    rts
.endproc
