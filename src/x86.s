
.include "ppu.inc"
.include "x86.inc"
.include "x86/decode.inc"
.include "x86/execute.inc"
.include "x86/fetch.inc"
.include "x86/interrupt.inc"
.include "x86/io.inc"
.include "x86/reg.inc"
.include "x86/write.inc"

; setting this flag will bypass the fetch, decode, execute, and write stages of the CPU.
; this flag is set by the HLT instruction.
; this flag is cleared each time an interrupt is triggered.
.exportzp zbHalt

.export x86
.export step
.export run
.export panic

; < label = string label between raErrorMessages and raErrorMessagesEnd
.define STRING_OFFSET(label) <(label - raErrorMessages)

.segment "ZEROPAGE"

zbHalt: .res 1

.segment "RODATA"

rsErrorHeader:
.asciiz "NES86: "

; keep error messages to 25 characters or less so they fit on one line.
raErrorMessages:
FetchError:
.asciiz "fetch error"
DecodeError:
.asciiz "decode error"
ExecuteError:
.asciiz "execute error"
WriteError:
.asciiz "write error"
IoError:
.asciiz "I/O error"
UnknownError:
.asciiz "unknown error"
raErrorMessagesEnd:

ERROR_STRING_BYTES = raErrorMessagesEnd - raErrorMessages
.assert ERROR_STRING_BYTES <= 256, error, "error string data is too large"

raErrorOffset:
.byte STRING_OFFSET FetchError
.byte STRING_OFFSET DecodeError
.byte STRING_OFFSET ExecuteError
.byte STRING_OFFSET WriteError
.byte STRING_OFFSET IoError
.byte STRING_OFFSET UnknownError
raErrorOffsetEnd:

ERROR_OFFSET_BYTES = raErrorOffsetEnd - raErrorOffset
.assert ERROR_OFFSET_BYTES = X86::eErr::ERROR_COUNT, error, "incorrect error offset size"

.segment "CODE"

; initialize x86 components.
.proc x86
    jsr Reg::reg
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


; halt the emulator and print an error message.
; an effort is made to change the system state as little as reasonably possible.
; that should make it easier to debug the system after the error.
; < A = error number. see X86::eErr.
.proc panic
    ; check if we were given a valid error number.
    ; if not change the error number to indicate an unknown error.
    ; we need to do this since the error number is used to lookup an error message.
    cmp #X86::eErr::ERROR_COUNT
    bcc known_error
    lda #X86::eErr::UNKNOWN_ERROR
known_error:
    ; save the error number for later.
    pha

    ; we'll write the error message at the top of nametable 0.
    ; this may not be to top of the screen because we don't account for scrolling.
    ; the error should still be visible somewhere on screen though.
    lda #<Ppu::NAMETABLE_0
    ldx #>Ppu::NAMETABLE_0
    jsr Ppu::initialize_write

    ; write a header string for the error message.
    ; this is done to tell the user that the error is coming from the emulator itself.
    ldy #0
    lda rsErrorHeader, y
write_header:
    jsr Ppu::write_bytes
    iny
    lda rsErrorHeader, y
    bne write_header

    ; lookup the error message and write out.
    pla
    tay
    lda raErrorOffset, y
    tay
    lda raErrorMessages, y
write_message:
    jsr Ppu::write_bytes
    iny
    lda raErrorMessages, y
    bne write_message

    ; close the write buffer.
    ; the error message will be drawn to the screen after the next NMI.
    jsr Ppu::finalize_write

    ; do nothing forever.
    ; we can't easily recover from errors.
loop:
    jmp loop
    ; [tail_jump]
.endproc
