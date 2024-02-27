
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
.byte <rsReg
.byte <rsMmu
.byte <rsFetch
.byte <rsDecode
.byte <rsExecute
.byte <rsWrite
.byte <rsPanic
rsErrorsHi:
.byte >rsReg
.byte >rsMmu
.byte >rsFetch
.byte >rsDecode
.byte >rsExecute
.byte >rsWrite
.byte >rsPanic

rsReg:
.byte "Error in reg\n", 0
rsMmu:
.byte "Error in mmu\n", 0
rsFetch:
.byte "Error in fetch\n", 0
rsDecode:
.byte "Error in decode\n", 0
rsExecute:
.byte "Error in execute\n", 0
rsWrite:
.byte "Error in write\n", 0
rsPanic:
.byte "Panic!\n", 0

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
