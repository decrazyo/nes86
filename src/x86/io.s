
; TODO: update ca65 and use "--feature line_continuations"
.linecont +

.include "keyboard.inc"
.include "list.inc"
.include "mmc5.inc"
.include "tmp.inc"
.include "x86.inc"
.include "x86/io.inc"
.include "x86/reg.inc"
.include "x86/uart.inc"

.export io

.export in
.export out

.segment "ZEROPAGE"

; =============================================================================
; public interface
; =============================================================================

.segment "CODE"

; initialize I/O
.proc io
    jsr Uart::uart
    rts
.endproc


; call an I/O handler, indexed by S0X, to receive data.
; this function is expected to be called by IN instruction handlers.
; < S0X = I/O port
; > A = low byte received from an I/O handler.
; > X = high byte received from an I/O handler.
;       only valid for 16-bit IN instructions.
; changes: A, X, Y
.proc in
    jsr get_handler_index

    ; push the address of the I/O handler onto the stack.
    lda rbaIoInFuncHi, x
    pha
    lda rbaIoInFuncLo, x
    pha

    ; call the I/O handler.
    rts
.endproc


; call an I/O handler, indexed by S0X, to transmit data.
; this function is expected to be called by OUT instruction handlers.
; < S0X = I/O port
; < S1L = low byte to send to an I/O handler.
; < S1H = high byte to send to an I/O handler.
;         only valid for 16-bit OUT instructions.
; changes: A, X, Y
.proc out
    jsr get_handler_index

    ; push the address of the I/O handler onto the stack.
    lda rbaIoOutFuncHi, x
    pha
    lda rbaIoOutFuncLo, x
    pha

    ; load the data that should be passed to the I/O handler.
    lda Reg::zwS1X
    ldx Reg::zwS1X+1

    ; call the I/O handler.
    rts
.endproc


; =============================================================================
; private interface
; =============================================================================

BANK_MASK = %11000000_00000000

; determine the index of the I/O handler that should be called for a given I/O port.
; upon return, the table of I/O handlers will be accessible in Mmc5::WINDOW_1
; < S0X = I/O port
; > X = index of an I/O handler function
.proc get_handler_index
    ; extract an MMC5 bank number from the I/O port
    lda Reg::zwS0X+1
    lsr
    lsr
    lsr
    lsr
    lsr
    clc
    adc #<.bank(rbaIoFuncIndex) | Mmc5::ROM
    ; select the bank in window 1
    sta Mmc5::WINDOW_1_CTRL

    ; extract an offset from the I/O port
    ; and convert the offset into a pointer to an MMC5 window.
    clc
    lda Reg::zwS0X
    sta Tmp::zw1
    lda Reg::zwS0X+1
    and #>~BANK_MASK
    adc #>Mmc5::WINDOW_1
    sta Tmp::zw1+1

    ; lookup the index of an I/O handler
    ldx #0
    lda (Tmp::zw1, x)
    tax

    ; select the bank containing the I/O handler table
    lda #<.bank(rbaIoInFuncLo) | Mmc5::ROM
    sta Mmc5::WINDOW_1_CTRL

    ; the caller can now use X to index tables found in Mmc5::WINDOW_1
    rts
.endproc


; handle expected I/O IN requests to ports with no associated device.
; this allows x86 processes to probe I/O ports for devices and find nothing.
; > A = $FF
; > X = $FF
.proc io_in_none
    ; returning $FF since an ISA bus with no device connected would default to a high state.
    lda #$ff
    tax
    ; [fall_through]
.endproc

; handle expected I/O OUT requests to ports with no associated device.
; this allows x86 processes to probe I/O ports for devices and find nothing.
.proc io_out_none
    rts
.endproc


; handle unexpected I/O requests to ports with no associated device.
; if an x86 processes tries to access an I/O port that we aren't expecting
; then we want the emulator to panic and tell us about it.
; then we can decide to emulate the device or let "io_none" handle it.
; this is mostly for debugging.
.proc io_error
    lda #X86::eErr::IO_ERROR
    jmp X86::panic
    ; [tail_jump]
.endproc


; =============================================================================
; I/O handler function pointer tables
; =============================================================================

.segment "IO_FUNC"

; handlers that send data from I/O devices to the CPU.
.define IO_IN_FUNCS \
io_error, \
io_in_none, \
Keyboard::get_key, \
Keyboard::status, \
Uart::get_rbr, \
Uart::get_ier, \
Uart::get_iir, \
Uart::get_lcr, \
io_error, \
Uart::get_lsr, \
Uart::get_msr, \
Uart::get_sr

; handlers that send data from the CPU to I/O devices.
.define IO_OUT_FUNCS \
io_error, \
io_out_none, \
io_out_none, \
io_out_none, \
Uart::set_thr, \
Uart::set_ier, \
Uart::set_fcr, \
Uart::set_lcr, \
Uart::set_mcr, \
io_error, \
io_error, \
Uart::set_sr

; I/O IN function jump table
rbaIoInFuncLo:
lo_return_bytes {IO_IN_FUNCS}
rbaIoInFuncHi:
hi_return_bytes {IO_IN_FUNCS}

; I/O OUT function jump table
rbaIoOutFuncLo:
lo_return_bytes {IO_OUT_FUNCS}
rbaIoOutFuncHi:
hi_return_bytes {IO_OUT_FUNCS}

; =============================================================================
; I/O port to handler function index table
; =============================================================================

.segment "IO_PORT"

; combine the lists of IN and OUT handler functions.
; we'll use this to define function indices.
zip_lists IO_FUNCS, {IO_IN_FUNCS}, {IO_OUT_FUNCS}

.ifdef DEBUG
    ; if this is a debug build then we want to be alerted to unexpected I/O.
    .define FILL_FUNC io_error io_error
.else
    ; if this isn't a debug build then we will ignore unexpected I/O.
    .define FILL_FUNC io_in_none io_out_none
.endif

; map I/O ports to jump table indices
size .set 0
rbaIoFuncIndex:
; programmable interrupt controller (PIC)
; interrupt command register
index_byte_at size, $0020, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC
; interrupt mask register
index_byte_at size, $0021, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; programmable interrupt timer (PIT)
; counter 0 data port
index_byte_at size, $0040, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC 
; control word register
index_byte_at size, $0043, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC 

; keyboard
; data
index_byte_at size, $0060, {IO_FUNCS}, Keyboard::get_key io_out_none, FILL_FUNC
; status
index_byte_at size, $0064, {IO_FUNCS}, Keyboard::status io_out_none, FILL_FUNC

; delay
index_byte_at size, $0080, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; COM4
index_byte_at size, $02e9, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; COM2
index_byte_at size, $02f9, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; COM3
index_byte_at size, $03e9, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; COM1
index_byte_at size, $03f8, {IO_FUNCS}, Uart::get_rbr Uart::set_thr, FILL_FUNC
; index_byte_at size, $03f9, {IO_FUNCS}, Uart::get_ier Uart::set_ier, FILL_FUNC
index_byte_at size, $03f9, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC ; COM1_IER
; index_byte_at size, $03fa, {IO_FUNCS}, Uart::get_iir Uart::set_fcr, FILL_FUNC
; index_byte_at size, $03fb, {IO_FUNCS}, Uart::get_lcr Uart::set_lcr, FILL_FUNC
; index_byte_at size, $03fc, {IO_FUNCS}, io_error Uart::set_mcr, FILL_FUNC
; index_byte_at size, $03fd, {IO_FUNCS}, Uart::get_lsr io_error, FILL_FUNC
index_byte_at size, $03fd, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC
; index_byte_at size, $03fe, {IO_FUNCS}, Uart::get_msr io_error, FILL_FUNC
; index_byte_at size, $03ff, {IO_FUNCS}, Uart::get_sr Uart::set_sr, FILL_FUNC

; ; not sure what these are used for but ELKS accesses them.
index_byte_at size, $0510, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC
index_byte_at size, $0511, {IO_FUNCS}, io_in_none io_out_none, FILL_FUNC

; fill out the rest of the table
index_byte_fill size, $ffff, {IO_FUNCS}, FILL_FUNC
.assert size = $10000, error, "incorrect table size"
