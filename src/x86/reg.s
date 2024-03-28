
.include "x86/reg.inc"
.include "x86.inc"

.include "chr.inc"
.include "con.inc"
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

; status register
zwFlags:
zbFlagsLo: .res 1
zbFlagsHi: .res 1

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

; register maps get copied here from ROM to save on access time
rzbaRegMapsBegin:
rzbaSegRegMap: .res 4
rzbaReg8Map: .res 8
rzbaReg16Map: .res 8
rzbaMem0Map: .res 8
rzbaMem1Map: .res 4
rzbaRegMapsEnd:

.segment "RODATA"

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

; initialize the reg module
; changes: A, X
.proc reg
    ; copy the register maps into zero-page
    ldx #((rbaRegMapsEnd - rbaRegMapsBegin) - 1)
loop:
    lda rbaRegMapsBegin, x
    sta rzbaRegMapsBegin, x
    dex
    bpl loop

    ; TODO: add an "init.inc" file.
    ;       use that to store initial register values to load at boot.
    ;       allow the values to be set on the command line at compile time too.

    ; set the CS register to the first ROM-only address
    lda #<$2000
    sta zwCS
    lda #>$2000
    sta zwCS+1

    rts
.endproc

; TODO: consider consolidating the set/clear flag functions

; set one or more bits in the low byte of the flag register.
; < A = bits to set
; changes: A
.proc set_flag_lo
    ora zbFlagsLo
    sta zbFlagsLo
    rts
.endproc


; clear one or more bits in the low byte of the flag register.
; < A = bits to clear
; changes: A
.proc clear_flag_lo
    eor #$ff
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
; < A = bits to clear
; changes: A
.proc clear_flag_hi
    eor #$ff
    and zbFlagsHi
    sta zbFlagsHi
    rts
.endproc

; ==============================================================================
; debugging
; ==============================================================================

.ifdef DEBUG
.segment "RODATA"

rsHeader:
.byte "\t H L\n", 0

rsAX:
.byte "AX:\t", 0
rsBX:
.byte "BX:\t", 0
rsCX:
.byte "CX:\t", 0
rsDX:
.byte "DX:\t", 0

rsSI:
.byte "SI:\t", 0
rsDI:
.byte "DI:\t", 0
rsBP:
.byte "BP:\t", 0
rsSP:
.byte "SP:\t", 0

rsIP:
.byte "IP:\t", 0

rsCS:
.byte "CS:\t", 0
rsDS:
.byte "DS:\t", 0
rsES:
.byte "ES:\t", 0
rsSS:
.byte "SS:\t", 0

rsFlags:
.byte "\t\t----ODITSZ-A-P-C\n"
.byte "flags:\t", 0

rsS0:
.byte "S0:\t\t", 0
rsS1:
.byte "S1:\t\t", 0
rsS2:
.byte "S2:\t\t", 0

rsD0:
.byte "D0:\t\t", 0
rsD1:
.byte "D1:\t\t", 0
rsD2:
.byte "D2:\t\t", 0

.segment "CODE"

.export debug_reg
.proc debug_reg
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsHeader
    ldx #>rsHeader
    jsr Tmp::set_ptr0
    jsr Con::print_str


    lda #<rsAX
    ldx #>rsAX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwAX
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsBX
    ldx #>rsBX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwBX
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsCX
    ldx #>rsCX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwCX
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsDX
    ldx #>rsDX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwDX
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr


    jsr Nmi::wait


    lda #<rsSI
    ldx #>rsSI
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwSI
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsCS
    ldx #>rsCS
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwCS
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsDI
    ldx #>rsDI
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwDI
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsDS
    ldx #>rsDS
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwDS
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait

    lda #<rsBP
    ldx #>rsBP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwBP
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsES
    ldx #>rsES
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwES
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsSP
    ldx #>rsSP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwSP
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsSS
    ldx #>rsSS
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwSS
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait

    lda #<rsIP
    ldx #>rsIP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwIP
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsFlags
    ldx #>rsFlags
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda zbFlagsHi
    jsr Con::print_bin
    lda zbFlagsLo
    jsr Con::print_bin

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr


    jsr Nmi::wait


    lda #<rsS0
    ldx #>rsS0
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwS0X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsD0
    ldx #>rsD0
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwD0X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsS1
    ldx #>rsS1
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwS1X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsD1
    ldx #>rsD1
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwD1X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr

    lda #<rsS2
    ldx #>rsS2
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwS2X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsD2
    ldx #>rsD2
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwD2X
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr

    jsr Nmi::wait
    rts
.endproc
.endif
