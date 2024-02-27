
.include "x86.inc"
.include "x86/reg.inc"
.include "x86/mmu.inc"
.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/execute.inc"
.include "x86/write.inc"

.include "chr.inc"
.include "con.inc"
.include "nmi.inc"
.include "tmp.inc"

.export x86
.export step
.export run
.export panic

.segment "RODATA"

rsErrorsLo:
.byte <rsRegIndex
.byte <rsCodeEnd
.byte <rsFetchBad
.byte <rsFetchLen
.byte <rsDecodeFunc
.byte <rsExecuteBad
.byte <rsExecuteFunc
.byte <rsWriteFunc
.byte <rsUnknown
rsErrorsHi:
.byte >rsRegIndex
.byte >rsCodeEnd
.byte >rsFetchBad
.byte >rsFetchLen
.byte >rsDecodeFunc
.byte >rsExecuteBad
.byte >rsExecuteFunc
.byte >rsWriteFunc
.byte >rsUnknown

rsRegIndex:
.byte "Register index out of range\n", 0
rsCodeEnd:
.byte "End of code\n", 0
rsFetchBad:
.byte "Fetched bad instruction\n", 0
rsFetchLen:
.byte "No instruction length\n", 0
rsDecodeFunc:
.byte "No decode function\n", 0
rsExecuteBad:
.byte "Executed bad instruction\n", 0
rsExecuteFunc:
.byte "No execute function\n", 0
rsWriteFunc:
.byte "No write function\n", 0
rsUnknown:
.byte "Unknown error\n", 0

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; initialize x86 components.
.proc x86
    jsr Reg::reg
    jsr Mmu::mmu
    rts
.endproc


; execute a single x86 instruction.
.proc step
    jsr Fetch::fetch
    jsr Decode::decode
    jsr Execute::execute
    jmp Write::write ; jsr rts -> jmp
.endproc


; execute x86 instructions forever.
.proc run
    jsr step
    jmp run
.endproc


; halt the emulator and print debug info if debugging is enabled.
; < A = error number
.proc panic
    tay
    cpy #X86::Err::UNKNOWN
    bcc valid_error
    ldy #X86::Err::UNKNOWN
valid_error:
    ; get error message
    lda rsErrorsLo, y
    ldx rsErrorsHi, y
    jsr Tmp::set_ptr0

    jsr Con::csr_home
    jsr Con::print_str

    .ifdef DEBUG
    jsr debug_x86
    .endif
loop:
    jmp loop
.endproc


; print the state of the x86 emulator.
.ifdef DEBUG
.export debug_x86
.proc debug_x86
    jsr Con::csr_home

    ; make space for an error message.
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Reg::debug_reg
    rts
.endproc
.endif
