
.include "x86/reg.inc"
.include "x86.inc"

.include "chr.inc"
.include "con.inc"
.include "tmp.inc"
.include "nmi.inc"

.exportzp zdEAX
.exportzp zdEBX
.exportzp zdECX
.exportzp zdEDX

.exportzp zdESI
.exportzp zdEDI
.exportzp zdEBP
.exportzp zdESP

.exportzp zdEIP

.exportzp zwCS
.exportzp zwDS
.exportzp zwES
.exportzp zwFS
.exportzp zwGS
.exportzp zwSS

.exportzp zbFlagsLo
.exportzp zbFlagsHi
.exportzp zbEFlagsLo
.exportzp zbEFlagsHi

.exportzp zdS0
.exportzp zdS1
.exportzp zdD0

.exportzp zbInstrEnc

.exportzp zbInstrLen

.exportzp zbInstrPrefix

.exportzp zbInstrOpcode
.exportzp zbInstrOperands

.export reg

.export set_flag_lo
.export clear_flag_lo
.export set_flag_hi
.export clear_flag_hi

.export reg8_to_src0
.export reg16_to_src0
.export reg8_to_src1
.export reg16_to_src1
.export dst0_to_reg8
.export dst0_to_reg16

.segment "ZEROPAGE"

; 80386 registers have been implemented so i don't have to refactor this as much later.

; main registers:
; accumulator register
zdEAX:
zwAX:
zbAL: .res 1
zbAH: .res 3
; base register
zdEBX:
zwBX:
zbBL: .res 1
zbBH: .res 3
; count register
zdECX:
zwCX:
zbCL: .res 1
zbCH: .res 3
; data register
zdEDX:
zwDX:
zbDL: .res 1
zbDH: .res 3

; index registers:
; source index register
zdESI:
zwSI: .res 4
; destination index register
zdEDI:
zwDI: .res 4
; base pointer register
zdEBP:
zwBP: .res 4
; stack pointer register
zdESP:
zwSP: .res 4

; instruction pointer register
zdEIP:
zwIP: .res 4

; segment registers:
; code segment register
zwCS: .res 2
; data segment register
zwDS: .res 2
; extra segment register
zwES: .res 2
; "F" segment register
zwFS: .res 2
; "G" segment register
zwGS: .res 2
; stack segment register
zwSS: .res 2

; status register
zbFlagsLo: .res 1
zbFlagsHi: .res 1
zbEFlagsLo: .res 1
zbEFlagsHi: .res 1

; pseudo-registers:
; source registers
zdS0: .res 4
zdS1: .res 4
; destination registers
zdD0: .res 4

; instruction encoding
zbInstrEnc: .res 1
; instruction length
; opcode + operands
; does not include prefix
zbInstrLen: .res 1

; instruction prefix
zbInstrPrefix: .res 1

; instruction buffer
zbInstrBuffer:
zbInstrOpcode: .res 1
zbInstrOperands: .res 4

; register maps get copied here from ROM to save on access time
zbaRegMapsBegin:
zbaSegRegMap: .res 4
zbaReg8Map: .res 8
zbaReg16Map: .res 8
zbaMem1Map: .res 8
zbaMem2Map: .res 4
zbaRegMapsEnd:

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
rbaMem1Map:
.byte zwBX, zwBX, zwBP, zwBP, zwSI, zwDI, zwBP, zwBX

; used with the above table for indices 0-3.
rbaMem2Map:
.byte zwSI, zwDI, zwSI, zwDI
rbaRegMapsEnd:

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
    sta zbaRegMapsBegin, x
    dex
    bpl loop

    ; initialize registers
    lda #$fe
    sta zwAX
    lda #$ff
    sta zwAX+1

    lda #$fe
    sta zwBX
    lda #$7f
    sta zwBX+1

    lda #$00
    sta zwCX
    sta zwCX+1

    sta zbFlagsHi
    sta zbFlagsLo

    lda #$ff
    sta zwCS
    sta zwCS+1
    rts
.endproc

; TODO: consider consolidating the set/clear flag functions

; set one or more bits in the low byte of the flag register.
; < Y = bits to set
; changes: A
.proc set_flag_lo
    tya
    ora zbFlagsLo
    sta zbFlagsLo
    rts
.endproc


; clear one or more bits in the low byte of the flag register.
; < Y = bits to clear
; changes: A
.proc clear_flag_lo
    tya
    eor #$ff
    and zbFlagsLo
    sta zbFlagsLo
    rts
.endproc


; set one or more bits in the high byte of the flag register.
; < Y = bits to set
; changes: A
.proc set_flag_hi
    tya
    ora zbFlagsHi
    sta zbFlagsHi
    rts
.endproc


; clear one or more bits in the high byte of the flag register.
; < Y = bits to clear
; changes: A
.proc clear_flag_hi
    tya
    eor #$ff
    and zbFlagsHi
    sta zbFlagsHi
    rts
.endproc


; copy an 8-bit register to source register 0.
; < A = register index (see rbaReg8Map)
; changes: A, X, Y
.proc reg8_to_src0
    jsr reg8_ptr_to_tmp0
    jsr src0_ptr_to_tmp1
    ldy #1
    jmp Tmp::memcpy
.endproc


; copy a 16-bit register to source register 0.
; < A = register index  (see rbaReg16Map)
; changes: A, X, Y
.proc reg16_to_src0
    jsr reg16_ptr_to_tmp0
    jsr src0_ptr_to_tmp1
    ldy #2
    jmp Tmp::memcpy
.endproc


; copy an 8-bit register to source register 1.
; < A = register index (see rbaReg8Map)
; changes: A, X, Y
.proc reg8_to_src1
    jsr reg8_ptr_to_tmp0
    jsr src1_ptr_to_tmp1
    ldy #1
    jmp Tmp::memcpy
.endproc


; copy a 16-bit register to source register 1.
; < A = register index  (see rbaReg16Map)
; changes: A, X, Y
.proc reg16_to_src1
    jsr reg16_ptr_to_tmp0
    jsr src1_ptr_to_tmp1
    ldy #2
    jmp Tmp::memcpy
.endproc


; copy destination register 0 to an 8-bit register
; < A = register index (see rbaReg8Map)
; changes: A, X, Y
.proc dst0_to_reg8
    jsr reg8_ptr_to_tmp1
    jsr dst0_ptr_to_tmp0
    ldy #1
    jmp Tmp::memcpy
.endproc


; copy destination register 0 to a 16-bit register
; < A = register index (see rbaReg16Map)
; changes: A, X, Y
.proc dst0_to_reg16
    jsr reg16_ptr_to_tmp1
    jsr dst0_ptr_to_tmp0
    ldy #2
    jmp Tmp::memcpy
.endproc

; ==============================================================================
; register / pseudo-register copying
; ==============================================================================

; < A = register index
.proc test_reg_index
    cmp #8
    bcc no_panic
    lda X86::Err::REG
    jsr X86::panic
no_panic:
    rts
.endproc

; find an 8-bit register's address from its index.
; copy the address into temporary address 0 so it can be used as a pointer.
; < A = index into zbaReg8Map
; > Tmp::gzw0 = pointer to a register
; changes: A, Y
.proc reg8_ptr_to_tmp0
    tay
    lda zbaReg8Map, y
    jmp Tmp::set_zp_ptr0
.endproc


; find a 16-bit register's address from its index.
; copy the address into temporary address 0 so it can be used as a pointer.
; < A = index into zbaReg16Map
; > Tmp::gzw0 = pointer to a register
; changes: A, Y
.proc reg16_ptr_to_tmp0
    tay
    lda zbaReg16Map, y
    jmp Tmp::set_zp_ptr0
.endproc


; find an 8-bit register's address from its index.
; copy the address into temporary address 1 so it can be used as a pointer.
; < A = index into zbaReg8Map
; > Tmp::gzw1 = pointer to a register
; changes: A, Y
.proc reg8_ptr_to_tmp1
    tay
    lda zbaReg8Map, y
    jmp Tmp::set_zp_ptr1
.endproc


; find a 16-bit register's address from its index.
; copy the address into temporary address 1 so it can be used as a pointer.
; < A = index into zbaReg16Map
; > Tmp::gzw1 = pointer to a register
; changes: A, Y
.proc reg16_ptr_to_tmp1
    tay
    lda zbaReg16Map, y
    jmp Tmp::set_zp_ptr1
.endproc


; copy the address of source 0 into temporary address 1 so it can be used as a pointer.
; > Tmp::gzw1 = pointer to source 0 register
; changes: A, X
.proc src0_ptr_to_tmp1
    lda #zdS0
    jmp Tmp::set_zp_ptr1
.endproc


; copy the address of source 1 into temporary address 1 so it can be used as a pointer.
; > Tmp::gzw1 = pointer to source 1 register
; changes: A, X
.proc src1_ptr_to_tmp1
    lda #zdS1
    jmp Tmp::set_zp_ptr1
.endproc


; copy the address of destination 0 into temporary address 0 so it can be used as a pointer.
; > Tmp::gzw0 = pointer to destination 0 register
; changes: A, X
.proc dst0_ptr_to_tmp0
    lda #zdD0
    jmp Tmp::set_zp_ptr0
.endproc

; ==============================================================================
; debugging
; ==============================================================================

.ifdef DEBUG
.segment "RODATA"

rsHeader:
.byte "\t\tE\tH L\n", 0

rsEAX:
.byte "EAX:\t", 0
rsEBX:
.byte "EBX:\t", 0
rsECX:
.byte "ECX:\t", 0
rsEDX:
.byte "EDX:\t", 0

rsESI:
.byte "ESI:\t", 0
rsEDI:
.byte "EDI:\t", 0
rsEBP:
.byte "EBP:\t", 0
rsESP:
.byte "ESP:\t", 0

rsEIP:
.byte "EIP:\t", 0

rsCS:
.byte "CS:\t", 0
rsDS:
.byte "DS:\t", 0
rsES:
.byte "ES:\t", 0
rsFS:
.byte "FS:\t", 0
rsGS:
.byte "\t\t\t\t\tGS:\t", 0
rsSS:
.byte "SS:\t", 0

rsFlags:
.byte "\t\t----ODITSZ-A-P-C\n"
.byte "flags:\t", 0

rsEFlags:
.byte "\t\t----------------\n"
.byte "eflags:\t", 0

rsS0:
.byte "S0:\t\t", 0
rsS1:
.byte "S1:\t\t", 0
rsD0:
.byte "D0:\t\t", 0

rsInstr:
.byte "instr:\t", 0
rsBlank:
.byte "      ", 0

.segment "CODE"

.export debug_reg
.proc debug_reg
    lda #<rsHeader
    ldx #>rsHeader
    jsr Tmp::set_ptr0
    jsr Con::print_str


    lda #<rsEAX
    ldx #>rsEAX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEAX
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsEBX
    ldx #>rsEBX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEBX
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsECX
    ldx #>rsECX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdECX
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsEDX
    ldx #>rsEDX
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEDX
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr


    jsr Nmi::wait


    lda #<rsESI
    ldx #>rsESI
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdESI
    jsr Tmp::set_zp_ptr0
    ldy #4
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


    lda #<rsEDI
    ldx #>rsEDI
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEDI
    jsr Tmp::set_zp_ptr0
    ldy #4
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


    lda #<rsEBP
    ldx #>rsEBP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEBP
    jsr Tmp::set_zp_ptr0
    ldy #4
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


    jsr Nmi::wait


    lda #<rsESP
    ldx #>rsESP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdESP
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::TAB
    jsr Con::print_chr

    lda #<rsFS
    ldx #>rsFS
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwFS
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsGS
    ldx #>rsGS
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zwGS
    jsr Tmp::set_zp_ptr0
    ldy #2
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsEIP
    ldx #>rsEIP
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdEIP
    jsr Tmp::set_zp_ptr0
    ldy #4
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


    lda #<rsEFlags
    ldx #>rsEFlags
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda zbEFlagsHi
    jsr Con::print_bin
    lda zbEFlagsLo
    jsr Con::print_bin

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

    lda #<zdS0
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsS1
    ldx #>rsS1
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdS1
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsD0
    ldx #>rsD0
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zdD0
    jsr Tmp::set_zp_ptr0
    ldy #4
    jsr Con::print_hex_arr_rev

    lda #Chr::NEW_LINE
    jsr Con::print_chr
    lda #Chr::NEW_LINE
    jsr Con::print_chr


    lda #<rsInstr
    ldx #>rsInstr
    jsr Tmp::set_ptr0
    jsr Con::print_str

    lda #<zbInstrBuffer
    jsr Tmp::set_zp_ptr0
    ldy zbInstrLen
    jsr Con::print_hex_arr_rev

    lda #<rsBlank
    ldx #>rsBlank
    jsr Tmp::set_ptr0
    jsr Con::print_str


    jsr Nmi::wait
    rts
.endproc
.endif
