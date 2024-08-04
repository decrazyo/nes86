
; This module is responsible for reading x86 instructions from RAM or ROM
; into an instruction buffer.
; This module must only read the x86 address space though the MMU's dedicated
; instruction fetching interface.
; This module must not write to the x86 address space at all.
; This module must only write to the x86 instruction buffer.
;
; uses:
;   Mem::get_ip_byte
; changes:
;   Fetch::zbInstrLen
;   Fetch::zbPrefixSegment
;   Fetch::zbInstrOpcode
;   Fetch::zaInstrOperands

.include "x86/reg.inc"
.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/mem.inc"
.include "x86.inc"

.include "chr.inc"
.include "tmp.inc"
.include "nmi.inc"

.exportzp zbPrefixSegment
.exportzp zbPrefixRepeat
.exportzp zbPrefixLock

.exportzp zbInstrLen
.exportzp zbInstrBuffer
.exportzp zbInstrOpcode
.exportzp zaInstrOperands

.export fetch

.segment "ZEROPAGE"

; segment prefix
; CS, DS, ES, SS
zbPrefixSegment: .res 1

; repeat prefix
; LOCK, REPZ, REPNZ
zbPrefixRepeat: .res 1

; lock prefix
; LOCK
zbPrefixLock: .res 1

; instruction buffer length
; opcode + operands
; does not include prefixes
zbInstrLen: .res 1

; instruction buffer
zbInstrBuffer:
zbInstrOpcode: .res 1
zaInstrOperands: .res Fetch::BUFFER_LEN

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
.byte <(fetch_modrm_ext_imm8-1)
.byte <(fetch_modrm_ext_imm16-1)
.byte <(fetch_modrm_ext_opt_imm8-1)
.byte <(fetch_modrm_ext_opt_imm16-1)
.byte <(fetch_modrm_ext_opt_ptr16-1)
.byte <(fetch_segment_prefix-1)
.byte <(fetch_repeat_prefix-1)
.byte <(fetch_lock_prefix-1)
rbaFetchFuncHi:
.byte >(fetch_bad-1)
.byte >(fetch_len_1-1)
.byte >(fetch_len_2-1)
.byte >(fetch_len_3-1)
.byte >(fetch_len_4-1)
.byte >(fetch_len_5-1)
.byte >(fetch_modrm_reg-1)
.byte >(fetch_modrm_ext_imm8-1)
.byte >(fetch_modrm_ext_imm16-1)
.byte >(fetch_modrm_ext_opt_imm8-1)
.byte >(fetch_modrm_ext_opt_imm16-1)
.byte >(fetch_modrm_ext_opt_ptr16-1)
.byte >(fetch_segment_prefix-1)
.byte >(fetch_repeat_prefix-1)
.byte >(fetch_lock_prefix-1)
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
    F07 ; instruction with a ModR/M byte and an 8-bit immediate
    F08 ; instruction with a ModR/M byte and a 16-bit immediate
    F09 ; instruction with a ModR/M byte and optionally an 8-bit immediate
    F10 ; instruction with a ModR/M byte and optionally a 16-bit immediate
    F11 ; instruction with a ModR/M byte and optionally a 16-bit pointer
    F12 ; segment prefix
    F13 ; repeat prefix
    F14 ; lock prefix

    FUNC_COUNT ; used to check function table size at compile-time
.endenum

.assert (rbaFetchFuncHi - rbaFetchFuncLo) = FUNC_COUNT, error, "fetch function count"

; map opcodes to instruction length
rbaInstrFetch:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,BAD ; 0_
.byte F06,F06,F06,F06,F02,F03,F01,F01,F06,F06,F06,F06,F02,F03,F01,F01 ; 1_
.byte F06,F06,F06,F06,F02,F03,F12,F01,F06,F06,F06,F06,F02,F03,F12,F01 ; 2_
.byte F06,F06,F06,F06,F02,F03,F12,F01,F06,F06,F06,F06,F02,F03,F12,F01 ; 3_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 4_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F01 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02,F02 ; 7_
.byte F07,F08,BAD,F07,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06,F06 ; 8_
.byte F01,F01,F01,F01,F01,F01,F01,F01,F01,F01,F05,F01,F01,F01,F01,F01 ; 9_
.byte F03,F03,F03,F03,F01,F01,F01,F01,F02,F03,F01,F01,F01,F01,F01,F01 ; A_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F03,F03,F03,F03,F03,F03,F03,F03 ; B_
.byte BAD,BAD,F03,F01,F06,F06,F07,F08,BAD,BAD,F03,F01,F01,F02,F01,F01 ; C_
.byte F06,F06,F06,F06,F02,F02,BAD,F01,F06,F06,F06,F06,F06,F06,F06,F06 ; D_
.byte F02,F02,F02,F02,F02,F02,F02,F02,F03,F03,F05,F02,F01,F01,F01,F01 ; E_
.byte F14,BAD,F13,F13,F01,F01,F09,F10,F01,F01,F01,F01,F01,F01,F06,F06 ; F_

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
    ; NOTE: if a non-string instruction is given a repeat prefix
    ;       then the emulator will enter an infinite loop.
    ;       we should probably detect and prevent that condition.
    ;       see also "fetch_repeat_prefix".
    lda Fetch::zbPrefixRepeat
    bne done ; branch if there is a repeat prefix

    ; reset the instruction length and segment prefix
    sta Fetch::zbInstrLen
    sta Fetch::zbPrefixSegment

    ldx #Reg::zwCS
    jsr Mem::use_segment

next:
    ; get a byte from memory
    jsr Mem::get_ip_byte

    ; lookup the appropriate handler
    tax
    ldy rbaInstrFetch, x

    ; call the fetch handler
    lda rbaFetchFuncHi, y
    pha
    lda rbaFetchFuncLo, y
    pha
    txa ; instruction byte
done:
    rts
.endproc

; ==============================================================================
; fetch handlers
; see "fetch" for argument descriptions
; ==============================================================================

; called when an unsupported instruction byte is fetch.
.proc fetch_bad
    jsr buffer_ip_byte
    lda #X86::Err::FETCH_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc


; handle fixed length 5 byte instruction.
.proc fetch_len_5
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 4 byte instruction.
.proc fetch_len_4
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 3 byte instruction.
.proc fetch_len_3
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 2 byte instruction.
.proc fetch_len_2
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 1 byte instruction.
buffer_ip_byte:
.proc fetch_len_1
    ldx zbInstrLen
    sta Fetch::zbInstrBuffer, x
    inc zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes a register
; or an opcode extension that doesn't need anything special.
.proc fetch_modrm_reg
    jsr modrm_rm_mode
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 8-bit immediate value.
.proc fetch_modrm_ext_imm8
    jsr modrm_rm_mode
    jsr modrm_rm_mode_1
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 16-bit immediate value.
.proc fetch_modrm_ext_imm16
    jsr modrm_rm_mode
    jsr modrm_rm_mode_2
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 8-bit immediate value.
.proc fetch_modrm_ext_opt_imm8
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    ; cmp #Decode::MODRM_EXT_TEST ; not needed since the values is 0.
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jsr modrm_rm_mode_1
done:
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 16-bit immediate value.
.proc fetch_modrm_ext_opt_imm16
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    ; cmp #Decode::MODRM_EXT_TEST ; not needed since the values is 0.
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jsr modrm_rm_mode_2
done:
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 16-bit pointer value.
.proc fetch_modrm_ext_opt_ptr16
;     jsr modrm_rm_mode
;     lda zaInstrOperands
;     and #Decode::MODRM_EXT_MASK
;     ; move the extended instruction index in the lowest 3 bits.
;     lsr
;     lsr
;     lsr

;     ; we need to fetch an additional pointer if the extended instructions is...
;     ;   CALL 0xHHHH     - index 3
;     ;   JMP 0xHHHH      - index 5
;     ; filter for those indices in the range [0,6].
;     ; index 7 is invalid and should be handled in a later stage.
;     ; higher values aren't possible.
;     ; this is a little wasteful 8-bit operations that don't include CALL and JMP
;     lsr
;     bcc done ; branch if the index was even.
;     beq done ; branch if the index was 1.
;     jsr modrm_rm_mode_2 ; fetch the pointer.
; done:
    rts
.endproc


; fetch segment prefix
.proc fetch_segment_prefix
    sta Fetch::zbPrefixSegment
    jmp fetch::next
    ; [tail_jump]
.endproc


; fetch repeat prefix
.proc fetch_repeat_prefix
    ; store the repeat prefix.
    sta Fetch::zbPrefixRepeat

    ; fetch the instruction to be repeated.
    jsr fetch::next

    ; TODO: check the opcode of the repeated instruction.
    ;       if it isn't a string instruction then remove the prefix.

    ; check the value of CX.
    lda Reg::zwCX
    ora Reg::zwCX+1
    bne done ; branch if CX != 0

    ; CX is already zero so shouldn't execute the instruction.
    ; remove the repeat prefix to resume normal execution.
    sta Fetch::zbPrefixRepeat
    ; remove the return address to skip the current instruction.
    pla
    pla
done:
    rts
.endproc


; fetch lock prefix.
; the emulator doesn't use this prefix for anything.
; all instructions are already executed atomically.
.proc fetch_lock_prefix
    sta Fetch::zbPrefixLock
    jmp fetch::next
    ; [tail_jump]
.endproc

; ==============================================================================
; ModR/M mode specific handlers.
; ==============================================================================

; read a ModR/M byte and any additional bytes indicated by the Mod and R/M fields.
.proc modrm_rm_mode
    ; store the instruction byte
    jsr buffer_ip_byte

    ; store the ModR/M byte
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte

    ; move the Mod field into the 2 lowest bits.
    and #Decode::MODRM_MOD_MASK
    asl
    rol
    rol

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
    ldx zbInstrLen
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
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte
    ; [fall_through]
.endproc

; handle ModR/M mode 1
; 8-bit signed offset
; read 1 more byte
.proc modrm_rm_mode_1
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte
    ; [fall_through]
.endproc

; handle ModR/M mode 3
; the R/M field contains a register index.
; nothing more to do.
.proc modrm_rm_mode_3
    rts
.endproc
