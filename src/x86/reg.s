
.include "x86/reg.inc"
.include "x86.inc"

.include "chr.inc"
.include "tmp.inc"
.include "nmi.inc"

.exportzp zwAX
.exportzp zbAL
.exportzp zbAH

.exportzp zwBX
.exportzp zbBL
.exportzp zbBH

.exportzp zwCX
.exportzp zbCL
.exportzp zbCH

.exportzp zwDX
.exportzp zbDL
.exportzp zbDH

.exportzp zwSI
.exportzp zwDI
.exportzp zwBP
.exportzp zwSP

.exportzp zwIP

.exportzp zwES
.exportzp zwCS
.exportzp zwSS
.exportzp zwDS

.exportzp zwFlags
.exportzp zbFlagsLo
.exportzp zbFlagsHi

.exportzp zwS0X
.exportzp zbS0L
.exportzp zbS0H
.exportzp zwS1X
.exportzp zbS1L
.exportzp zbS1H
.exportzp zwS2X
.exportzp zbS2L
.exportzp zbS2H

.exportzp zwD0X
.exportzp zbD0L
.exportzp zbD0H
.exportzp zwD1X
.exportzp zbD1L
.exportzp zbD1H
.exportzp zwD2X
.exportzp zbD2L
.exportzp zbD2H

.exportzp rzbaRegMapsBegin
.exportzp rzbaSegRegMap
.exportzp rzbaReg8Map
.exportzp rzbaReg16Map
.exportzp rzbaMem0Map
.exportzp rzbaMem1Map
.exportzp rzbaRegMapsEnd

.export reg

.export set_flag_lo
.export clear_flag_lo
.export set_flag_hi
.export clear_flag_hi

.segment "ZEROPAGE"

; main registers:
; accumulator register
zwAX:
zbAL: .res 1
zbAH: .res 1
; base register
zwBX:
zbBL: .res 1
zbBH: .res 1
; count register
zwCX:
zbCL: .res 1
zbCH: .res 1
; data register
zwDX:
zbDL: .res 1
zbDH: .res 1

; index registers:
; source index register
zwSI: .res 2
; destination index register
zwDI: .res 2
; base pointer register
zwBP: .res 2
; stack pointer register
zwSP: .res 2

; instruction pointer register
zwIP: .res 2

; segment registers:
; segments are 16-bit shifted left by 4 bits to make calculations easier.
; like the other registers, data is stored little-endian
; low byte              high byte
; 7654 3210  7654 3210  7654 3210
; ssss 0000  ssss ssss  0000 ssss
; extra segment register
zwES: .res 3
; code segment register
zwCS: .res 3
; stack segment register
zwSS: .res 3
; data segment register
zwDS: .res 3

; pseudo-registers:
; mainly used by the ALU.
; source registers
zwS0X:
zbS0L: .res 1
zbS0H: .res 1
zwS1X:
zbS1L: .res 1
zbS1H: .res 1
zwS2X:
zbS2L: .res 1
zbS2H: .res 1
; destination registers
zwD0X:
zbD0L: .res 1
zbD0H: .res 1
zwD1X:
zbD1L: .res 1
zbD1H: .res 1
zwD2X:
zbD2L: .res 1
zbD2H: .res 1

; status register
zwFlags:
zbFlagsLo: .res 1
zbFlagsHi: .res 1

; register maps get copied here from ROM to save on access time
rzbaRegMapsBegin:
rzbaSegRegMap: .res 4
rzbaReg8Map: .res 8
rzbaReg16Map: .res 8
rzbaMem0Map: .res 8
rzbaMem1Map: .res 4
rzbaRegMapsEnd:

.segment "RODATA"

; NOTE: registers could be arranged to eliminate the need for some (all?) of these tables
;       and that may save a few cycles.
;       the tables make the code more readable imo so i'm keeping them for now.

rbaRegMapsBegin:
; map register numbers to their emulated 16-bit segment register addresses.
rbaSegRegMap:
.byte zwES, zwCS, zwSS, zwDS

; these tables are used for instructions with implied register or with ModR/M mode %11

; map register numbers to their emulated 8-bit register addresses.
rbaReg8Map:
.byte zbAL, zbCL, zbDL, zbBL, zbAH, zbCH, zbDH, zbBH

; map register numbers to their emulated 16-bit register addresses.
rbaReg16Map:
.byte zwAX, zwCX, zwDX, zwBX, zwSP, zwBP, zwSI, zwDI

; these tables are used to calculate memory addresses with ModR/M modes %00, %01, and %10

; map register numbers to their emulated 16-bit register addresses.
rbaMem0Map:
.byte zwBX, zwBX, zwBP, zwBP, zwSI, zwDI, zwBP, zwBX

; used with the above table for indices 0-3.
rbaMem1Map:
.byte zwSI, zwDI, zwSI, zwDI
rbaRegMapsEnd:

.assert (rbaRegMapsEnd - rbaRegMapsBegin) = (rzbaRegMapsEnd - rzbaRegMapsBegin), error, "register map size mismatch"

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; initialize the register module
; changes: A, X
.proc reg
    ; copy the register maps into zero-page so they can be accessed faster.
    ldx #((rbaRegMapsEnd - rbaRegMapsBegin) - 1)
loop:
    lda rbaRegMapsBegin, x
    sta rzbaRegMapsBegin, x
    dex
    bpl loop

    ; the reset state of an 8086 sets CS to $ffff and all other registers to 0.
    ; we should only need to explicitly initialize CS.
    CS_RESET = $ffff
    lda #<CS_RESET
    sta zwCS
    lda #>CS_RESET
    sta zwCS+1

    ; FLAGS_RESET = $f000
    ; lda #>FLAGS_RESET
    ; sta zwFlags+1

    rts
.endproc


; set one or more bits in the low byte of the flag register.
; < A = bits to set
; changes: A
.proc set_flag_lo
    ora zbFlagsLo
    sta zbFlagsLo
    rts
.endproc


; clear one or more bits in the low byte of the flag register.
; < A = bitwise negation of bits to clear
; changes: A
.proc clear_flag_lo
    and zbFlagsLo
    sta zbFlagsLo
    rts
.endproc


; set one or more bits in the high byte of the flag register.
; < A = bits to set
; changes: A
.proc set_flag_hi
    ora zbFlagsHi
    sta zbFlagsHi
    rts
.endproc


; clear one or more bits in the high byte of the flag register.
; < A = bitwise negation of bits to clear
; changes: A
.proc clear_flag_hi
    and zbFlagsHi
    sta zbFlagsHi
    rts
.endproc
