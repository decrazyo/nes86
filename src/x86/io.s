
; TODO: update ca65 and use "--feature line_continuations"
.linecont +

.include "x86.inc"
.include "x86/io.inc"
.include "x86/reg.inc"
.include "x86/uart.inc"
.include "mmc5.inc"
.include "tmp.inc"
.include "keyboard.inc"

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
.proc io_bad
    lda #X86::Err::IO_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc

.proc read_keybaord
    jsr Keyboard::get_key
    bcs read_keybaord
    rts
.endproc


; =============================================================================
; I/O handler function pointer tables
; =============================================================================

.segment "IO_FUNC"

; we can have a maximum of 256 IN and OUT handlers.
TABLE_SIZE = 256

.enum eIoFunc
    BAD
    NONE
    COM1_DATA
    COM1_IER
    COM1_IIR_FCR
    COM1_LCR
    COM1_MCR
    COM1_LSR
    COM1_MSR
    COM1_SR
    KB_DATA
    FUNC_COUNT
.endenum

; handlers that send data from I/O devices to the CPU.
.define IoInFunc \
    io_bad-1, \
    io_in_none-1, \
    Uart::get_rbr-1, \
    Uart::get_ier-1, \
    Uart::get_iir-1, \
    Uart::get_lcr-1, \
    io_bad-1, \
    Uart::get_lsr-1, \
    Uart::get_msr-1, \
    Uart::get_sr-1, \
    read_keybaord-1

; handlers that send data from the CPU to I/O devices.
.define IoOutFunc \
    io_bad-1, \
    io_out_none-1, \
    Uart::set_thr-1, \
    Uart::set_ier-1, \
    Uart::set_fcr-1, \
    Uart::set_lcr-1, \
    Uart::set_mcr-1, \
    io_bad-1, \
    io_bad-1, \
    Uart::set_sr-1, \
    io_out_none-1


; build function pointer tables.
; tables are filled to capacity with io_bad pointers.
; this is done to ensure proper execution even if we get an invalid function index.

rbaIoInFuncLo:
    .lobytes IoInFunc
rbaIoInFuncLoMid:
    .assert rbaIoInFuncLoMid - rbaIoInFuncLo <= TABLE_SIZE, error, "too many IN handlers"
    .repeat TABLE_SIZE - (rbaIoInFuncLoMid - rbaIoInFuncLo)
        .byte <(io_bad-1)
    .endrepeat
rbaIoInFuncLoEnd:

rbaIoInFuncHi:
    .hibytes IoInFunc
rbaIoInFuncHiMid:
    .repeat TABLE_SIZE - (rbaIoInFuncHiMid - rbaIoInFuncHi)
        .byte <(io_bad-1)
    .endrepeat
rbaIoInFuncHiEnd:


rbaIoOutFuncLo:
    .lobytes IoOutFunc
rbaIoOutFuncLoMid:
    .assert rbaIoOutFuncLoMid - rbaIoOutFuncLo <= TABLE_SIZE, error, "too many OUT handlers"
    .repeat TABLE_SIZE - (rbaIoOutFuncLoMid - rbaIoOutFuncLo)
        .byte <(io_bad-1)
    .endrepeat
rbaIoOutFuncLoEnd:

rbaIoOutFuncHi:
    .hibytes IoOutFunc
rbaIoOutFuncHiMid:
    .repeat TABLE_SIZE - (rbaIoOutFuncHiMid - rbaIoOutFuncHi)
        .byte <(io_bad-1)
    .endrepeat
rbaIoOutFuncHiEnd:

; check that we have the same number of input and output handlers.
.assert rbaIoOutFuncLoMid - rbaIoOutFuncLo = rbaIoOutFuncLoMid - rbaIoOutFuncLo, error, \
    "I/O table size mismatch"

; check that each I/O handler has an associated enum value.
.assert rbaIoOutFuncLoMid - rbaIoOutFuncLo = eIoFunc::FUNC_COUNT, error, \
    "I/O table sise does not match enum size"

; =============================================================================
; I/O port to handler function index table
; =============================================================================

.segment "IO_PORT"

current_port .set 0

; map a port to an I/O handler function index.
; < port = I/O port address to associate with a function index.
; < func = eIoFunc function index to associate with "port".
; < fill = eIoFunc function index to fill the table with until "port" is reached.
;          this parameter is options.
;          defaults to eIoFunc::BAD
.macro map_port port, func, fill
    .if current_port > port
        .error  "ports must be mapped sequentially"
    .endif

    .repeat port - current_port
        .ifblank fill
            .byte eIoFunc::BAD ; default fill value
        .else
            .byte fill ; explicit fill value
        .endif
    .endrepeat

    .byte func

    current_port .set port + 1
.endmacro


; map functions to I/O ports.
rbaIoFuncIndex:
    map_port $0020, eIoFunc::NONE ; TODO: PIC Interrupt Command Register
    map_port $0021, eIoFunc::NONE ; TODO: PIC Interrupt Mask Register

    map_port $0040, eIoFunc::NONE ; TODO: PIT Counter 0 Data Port
    map_port $0043, eIoFunc::NONE ; TODO: PIT Control Word Register

    map_port $0060, eIoFunc::KB_DATA ; read keyboard data

    map_port $0080, eIoFunc::NONE ; delay

    ; COM4
    map_port $02e9, eIoFunc::NONE ; COM4_IER

    ; COM2
    map_port $02f9, eIoFunc::NONE ; COM2_IER

    ; COM3
    map_port $03e9, eIoFunc::NONE ; COM3_IER

    ; COM1
    map_port $03f8, eIoFunc::COM1_DATA
    ; map_port $03f9, eIoFunc::COM1_IER
    map_port $03f9, eIoFunc::NONE ; COM3_IER
    ; map_port $03fa, eIoFunc::COM1_IIR_FCR
    ; map_port $03fb, eIoFunc::COM1_LCR
    ; map_port $03fc, eIoFunc::COM1_MCR
    ; map_port $03fd, eIoFunc::COM1_LSR
    map_port $03fd, eIoFunc::NONE ; COM1_LSR
    ; map_port $03fe, eIoFunc::COM1_MSR
    ; map_port $03ff, eIoFunc::COM1_SR

    ; not sure what these are used for but ELKS accesses them.
    map_port $0510, eIoFunc::NONE
    map_port $0511, eIoFunc::NONE

    ; the linker should fill the rest of the table with zeros.
    ; i.e. eIoFunc::BAD
    ; this is faster than using .repeat to fill the table
rbaIoFuncIndexEnd:

; NOTE: don't put anything else in this segment!
