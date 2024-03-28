
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
.byte <rsFetchLen
.byte <rsFetchFunc
.byte <rsDecodeFunc
.byte <rsExecuteFunc
.byte <rsWriteFunc
.byte <rsModRM
.byte <rsUnknown
rsErrorsHi:
.byte >rsRegIndex
.byte >rsCodeEnd
.byte >rsFetchLen
.byte >rsFetchFunc
.byte >rsDecodeFunc
.byte >rsExecuteFunc
.byte >rsWriteFunc
.byte >rsModRM
.byte >rsUnknown

rsRegIndex:
.byte "\nRegister index out of range\n", 0
rsCodeEnd:
.byte "\nEnd of code\n", 0
rsFetchLen:
.byte "\nFetched too many bytes\n", 0
rsFetchFunc:
.byte "\nNo fetch function\n", 0
rsDecodeFunc:
.byte "\nNo decode function\n", 0
rsExecuteFunc:
.byte "\nNo execute function\n", 0
rsWriteFunc:
.byte "\nNo write function\n", 0
rsModRM:
.byte "\nUnexpected modr/m value\n", 0
rsUnknown:
.byte "\nUnknown error\n", 0

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
    jmp Write::write
    ; [tail_jump]
.endproc


; execute x86 instructions forever.
.proc run
    jsr step
    jmp run
    ; [tail_jump]
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
    jsr Nmi::wait

    .ifdef DEBUG
    jsr debug_x86
    .endif
loop:
    jmp loop
    ; [tail_jump]
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
    jsr Fetch::debug_fetch
    jsr Mmu::debug_mmu
    rts
.endproc
.endif
