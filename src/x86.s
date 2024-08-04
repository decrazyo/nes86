
.include "x86.inc"
.include "x86/reg.inc"
.include "x86/io.inc"
.include "x86/mem.inc"
.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/execute.inc"
.include "x86/interrupt.inc"
.include "x86/write.inc"

.include "chr.inc"
.include "nmi.inc"
.include "tmp.inc"

; setting this flag will bypass the fetch, decode, execute, and write stages of the CPU.
; this flag is set by the HLT instruction.
; this flag is cleared each time an interrupt is triggered.
.exportzp zbHalt

.export x86
.export step
.export run
.export panic

.segment "ZEROPAGE"

zbHalt: .res 1

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; initialize x86 components.
.proc x86
    jsr Reg::reg
    jsr Mem::mem
    jsr Io::io
    rts
.endproc


; execute a single x86 instruction.
.proc step
    lda zbHalt
    bne halted
    jsr Fetch::fetch
    jsr Decode::decode
    jsr Execute::execute
    jsr Write::write
halted:
    jmp Interrupt::interrupt
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
loop:
    jmp loop
    ; [tail_jump]
.endproc
