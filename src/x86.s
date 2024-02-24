
.include "x86.inc"
.include "tmp.inc"
.include "con.inc"
.include "nmi.inc"

.export x86
.export x86_print
.export x86_panic
.export x86_fetch
.export x86_decode
.export x86_execute
.export x86_write
.export x86_step

.segment "ZEROPAGE"

; main registers:
; accumulator register
zwAX:
zbAH: .res 1
zbAL: .res 1
; base register
zwBX:
zbBH: .res 1
zbBL: .res 1
; count register
zwCX:
zbCH: .res 1
zbCL: .res 1
; data register
zwDX:
zbDH: .res 1
zbDL: .res 1

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
; code segment register
zwCS: .res 2
; data segment register
zwDS: .res 2
; extra segment register
zwES: .res 2
; stack segment register
zwSS: .res 2

; status register
zwFlags:
zwFlagsHi: .res 1
zwFlagsLo: .res 1
;          FEDCBA9876543210
;         %1000000000000000 ; RESERVED
;         %0100000000000000 ; RESERVED
;         %0010000000000000 ; RESERVED
;         %0001000000000000 ; RESERVED
FLAG_OF = %0000100000000000 ; overflow flag
FLAG_DF = %0000010000000000 ; direction flag
FLAG_IF = %0000001000000000 ; interrupt flag
FLAG_TF = %0000000100000000 ; trap flag
;          FEDCBA9876543210
FLAG_SF = %0000000010000000 ; sign flag
FLAG_ZF = %0000000001000000 ; zero flag
;         %0000000000100000 ; RESERVED
FLAG_AF = %0000000000010000 ; auxiliary carry flag
;         %0000000000001000 ; RESERVED
FLAG_PF = %0000000000000100 ; parity flag
;         %0000000000000010 ; RESERVED
FLAG_CF = %0000000000000001 ; carry flag

; pseudo-registers used when executing instructions.
; source registers
zwWorkSrc1X:
zbWorkSrc1H: .res 1
zbWorkSrc1L: .res 1
zwWorkSrc2X:
zbWorkSrc2H: .res 1
zbWorkSrc2L: .res 1
; destination register
zwWorkDstX:
zbWorkDstH: .res 1
zbWorkDstL: .res 1

; instruction encoding.
zbInstrEnc: .res 1
; length of the instruction in the instruction buffer.
zbInstrLen: .res 1

; instruction buffer
; TODO: divide this buffer into meaningful parts.
;       prefix, opcode, operand 1, operand 2, etc...
zaInstrBufBegin:
zbInstrPrefix: .res 1
zbInstrOpcode: .res 1
zbInstrOperands: .res 4
zaInstrBufEnd:

.segment "RODATA"

; invalid/unimplemented instruction
BAD = <-1
; special cases
SP0 = $80 | $00
SP1 = $80 | $01
SP2 = $80 | $02
; instruction encodings
EN0 = $00 ; single byte instruction with reg in bits 0-2 (INC reg16)
EN1 = $01 ; single byte instruction with seg reg in bits 3-5 (POP segreg)
EN2 = $02 ; single byte instruction with w flag in bit 0 (STOS)
EN3 = $03 ; multi-byte instruction with reg in bits 0-2 and w flag in bit 3 (MOV reg, immed)
EN4 = $04 ; 

; map x86 opcodes to their encoding scheme.
; the encoding scheme is used, in part, to determine the length of the instruction
; and how it should be decoded.
rbaOpcodeEncoding:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN1,BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN1 ; 0_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN1,BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN1 ; 1_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 2_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 3_
.byte EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 4_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 8_
.byte EN0,EN0,EN0,EN0,EN0,EN0,EN0,EN0,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 9_
.byte BAD,BAD,BAD,BAD,BAD,BAD,EN2,EN2,BAD,BAD,EN2,EN2,BAD,BAD,BAD,BAD ; A_
.byte EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3,EN3 ; B_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; F_

; map instruction encodings to instruction lengths.
rbaEncodingLength:
.byte $01,$01,$01

; map encodings to their decoding functions.
rbaDecodeFuncLo:
.byte <(decode_inc_reg16-1)
rbaDecodeFuncHi:
.byte >(decode_inc_reg16-1)

; map instructions, not opcodes, to their execution functions.
rbaExecuteFuncLo:
.byte <(execute_inc_reg16-1)
rbaExecuteFuncHi:
.byte >(execute_inc_reg16-1)

; map encodings to their write-back functions.
rbaWriteFuncLo:
.byte <(write_inc_reg16-1)
rbaWriteFuncHi:
.byte >(write_inc_reg16-1)


rbaRegMapsBegin:
; map register numbers to their emulated 16-bit segment register addresses.
rbaSegRegEncoding:
.byte zwES, zwCS, zwSS, zwDS

; these tables are used for instructions with implied register or with ModR/M mode %11

; map register numbers to their emulated 8-bit register addresses.
rbaReg8Encoding:
.byte zbAL, zbCL, zbDL, zbBL, zbAH, zbCH, zbDH, zbBH

; map register numbers to their emulated 16-bit register addresses.
rbaReg16Encoding:
.byte zwAX, zwCX, zwDX, zwBX, zwSP, zwBP, zwSI, zwDI

; these tables are used to calculate memory addresses with ModR/M modes %00, %01, and %10

; map register numbers to their emulated 16-bit register addresses.
rbaMem1Encoding:
.byte zwBX, zwBX, zwBP, zwBP, zwSI, zwDI, zwBP, zwBX

; used with the above table for indices 0-3.
rbaMem2Encoding:
.byte zwSI, zwDI, zwSI, zwDI
rbaRegMapsEnd:

; x86 code to execute.
raCode:
.incbin "x86_code.com"
raCodeLen:
.byte <(raCodeLen - raCode)
.byte >(raCodeLen - raCode)


.segment "CODE"

; initialize the module.
.proc x86
    ; TODO: setup translations between registers and real addresses

    lda #$ff
    sta zwAX
    lda #$fe
    sta zwAX+1

    lda #$7f
    sta zwBX
    lda #$fe
    sta zwBX+1

    lda #$00
    sta zwCX
    lda #$00
    sta zwCX+1

    lda #$ff
    sta zwCS
    sta zwCS+1
    rts
.endproc


; instruction fetch
; read instruction opcode and operands into the instruction buffer.
; changes: A, X, Y
.proc x86_fetch
    lda #0
    sta zbInstrLen

    ; read a byte of code.
    ; probably an opcode but maybe a prefix or unsupported instruction.
    jsr get_ip_byte

    ; if they byte is an opcode then this will give us its encoding.
    tax
    lda rbaOpcodeEncoding, x

    ; check for an unsupported instruction.
    cmp #BAD
    bne not_bad
    jsr x86_panic
not_bad:

    ; TODO: check for special cases like a prefix byte.

    stx zbInstrOpcode
    inc zbInstrLen

    ; use the encoding to determine the length of the instruction.
    sta zbInstrEnc
    tax
    lda rbaEncodingLength, x

    ; TODO: check for special cases like the length depending on the opcode.

    ; TODO: copy the operands into the instruction buffer.

    rts
.endproc

; analyze the instruction buffer.
; determine which instruction should be executed.
; move data into temporary working memory.
.proc x86_decode
    ldx zbInstrEnc
    lda rbaDecodeFuncHi, x
    pha
    lda rbaDecodeFuncLo, x
    pha
    rts
.endproc


; execute the decoded instruction.
.proc x86_execute
    ldx zbInstrEnc
    lda rbaExecuteFuncHi, x
    pha
    lda rbaExecuteFuncLo, x
    pha
    rts
.endproc


; write data back to memory or registers after execution.
.proc x86_write
    ldx zbInstrEnc
    lda rbaWriteFuncHi, x
    pha
    lda rbaWriteFuncLo, x
    pha
    rts
.endproc


; execute a single instruction.
.proc x86_step
    jsr x86_fetch
    jsr x86_decode
    jsr x86_execute
    jsr x86_write
    rts
.endproc


; read a byte pointed to by the instruction pointer.
; increment the instruction pointer
; > A = instruction byte
.proc get_ip_byte
    ; TODO: implement this better.
    ; this is a quick hack to use the low byte of the instruction pointer.
    stx gzbTmp0
    ldx zwIP+1
    ; check that the instruction pointer is still pointing at code.
    cpx raCodeLen
    bcc no_panic
    jsr x86_panic
no_panic:
    lda raCode, x
    inc zwIP+1
    ldx gzbTmp0
    rts
.endproc


; < Y = bits to set
.proc set_flag_lo
    tya
    ora zwFlagsLo
    sta zwFlagsLo
    rts
.endproc


; < Y = bits to clear
.proc clear_flag_lo
    tya
    eor #$ff
    and zwFlagsLo
    sta zwFlagsLo
    rts
.endproc


; < Y = bits to set
.proc set_flag_hi
    tya
    ora zwFlagsHi
    sta zwFlagsHi
    rts
.endproc


; < Y = bits to clear
.proc clear_flag_hi
    tya
    eor #$ff
    and zwFlagsHi
    sta zwFlagsHi
    rts
.endproc


.proc reg16_ptr
    tay
    lda rbaReg16Encoding, y
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    rts
.endproc


; copy a 16-bit register to the source pseudo-register.
; < A = register index
; changes: A, Y
.proc copy_reg16_to_src1
    jsr reg16_ptr
    ldy #0
loop:
    lda (gzwTmp0), y
    sta zwWorkSrc1X, y
    iny
    cpy #2
    bne loop
    rts
.endproc


.proc copy_dst_to_reg16
    jsr reg16_ptr
    ldy #0
loop:
    lda zwWorkDstX, y
    sta (gzwTmp0), y
    iny
    cpy #2
    bne loop
    rts
.endproc


; set the parity flag based the result of an execution.
; only considers the lowest 8 bits
.proc set_parity_flag
    ldy #<FLAG_PF

    lda zbWorkDstL
    ldx #0
    ; count the number of set bits
loop:
    cmp #0
    beq done
    lsr a
    bcc loop
    inx
    bne loop
done:
    ; check if the number of set bits is odd or even
    txa
    lsr
    ; set or clear the parity flag accordingly
    bcc set_flag ; branch if even number of bits
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the auxiliary carry flag if addition caused a carry in the low nibble.
.proc set_auxiliary_flag_add
    ldy #<FLAG_AF

    lda zbWorkDstL
    and #$0f
    beq set_flag ; branch if carry happened
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the zero flag if an execution resulted in an output of 0.
.proc set_zero_flag_8
    ldy #<FLAG_ZF
    lda zbWorkDstL
    beq set_flag
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the zero flag if an execution resulted in an output of 0.
.proc set_zero_flag_16
    ldy #<FLAG_ZF
    lda zbWorkDstL
    ora zbWorkDstH
    beq set_flag
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_8
    ldy #<FLAG_SF

    lda zbWorkDstL
    bmi set_flag ; branch if negative
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_16
    ldy #<FLAG_SF

    lda zbWorkDstH
    bmi set_flag ; branch if negative
    jmp clear_flag_lo ; jsr rts -> jmp
set_flag:
    jmp set_flag_lo ; jsr rts -> jmp
.endproc


; set the overflow flag if addition caused an arithmetic overflow.
.proc set_overflow_flag_add_16
    ldy #>FLAG_OF

    lda zbWorkSrc1H
    eor zbWorkSrc2H
    bmi clear_flag ; branch if source registers have different signs

    lda zbWorkSrc1H
    eor zbWorkDstH
    bpl clear_flag ; branch if sources and destination have the same sign

    jmp set_flag_hi ; jsr rts -> jmp
clear_flag:
    jmp clear_flag_hi ; jsr rts -> jmp
.endproc


; decode INC reg16
.proc decode_inc_reg16
    lda zbInstrOpcode
    ; isolate the register bits
    and #%00000111
    jsr copy_reg16_to_src1
    ; setting source 2 to 0x0001.
    ; this is just for setting flags after execution.
    ; it's kinda wasteful.
    ldx #1
    stx zbWorkSrc2L
    dex
    stx zbWorkSrc2H
    rts
.endproc


; execute INC reg16
.proc execute_inc_reg16
    sec
    ldx #2
loop:
    dex
    bmi done
    lda zwWorkSrc1X, x
    adc #0
    sta zwWorkDstX, x
    jmp loop
done:

    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jmp set_overflow_flag_add_16 ; jsr rts -> jmp
.endproc


; execute INC reg16
.proc write_inc_reg16
    lda zbInstrOpcode
    ; isolate the register bits
    and #%00000111
    jmp copy_dst_to_reg16 ; jsr rts -> jmp
.endproc








.segment "RODATA"

rsPanic:
.byte "Panic!", 0
rsLoHi:
.byte "\n\tH L", 0

rsAX:
.byte "\nAX:\t", 0
rsBX:
.byte "\nBX:\t", 0
rsCX:
.byte "\nCX:\t", 0
rsDX:
.byte "\nDX:\t", 0

rsSI:
.byte "\n\nSI:\t", 0
rsDI:
.byte "\nDI:\t", 0
rsBP:
.byte "\nBP:\t", 0
rsSP:
.byte "\nSP:\t", 0

rsIP:
.byte "\n\nIP:\t", 0

rsCS:
.byte "\n\nCS:\t", 0
rsDS:
.byte "\nDS:\t", 0
rsES:
.byte "\nES:\t", 0
rsSS:
.byte "\nSS:\t", 0

rsFlags:
.byte "\n\n\t\t----ODITSZ-A-P-C"
.byte "\nflags:\t", 0

rsS1:
.byte "\n\nS1:\t", 0
rsS2:
.byte "\nS2:\t", 0
rsD1:
.byte "\nD1:\t", 0

rsInstr:
.byte "\n\ninstr:\t", 0
rsSpace:
.byte "      ", 0

.segment "CODE"

; unrecoverable errors, like invalid instructions, should call this.
; for now we'll just sit in an infinite loop.
; maybe later we'll reset the system or display some debugging info.
.proc x86_panic
    jsr con_csr_home

    lda #<rsPanic
    sta gzwTmp0
    lda #>rsPanic
    sta gzwTmp0+1
    jsr con_print_str

    jsr x86_print
loop:
    jmp loop
.endproc


; prints the state of the emulated processor
.proc x86_print
    jsr con_csr_home

    lda #<rsLoHi
    sta gzwTmp0
    lda #>rsLoHi
    sta gzwTmp0+1
    jsr con_print_str

    ; print AX
    lda #<rsAX
    sta gzwTmp0
    lda #>rsAX
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwAX
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print BX
    lda #<rsBX
    sta gzwTmp0
    lda #>rsBX
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwBX
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print CX
    lda #<rsCX
    sta gzwTmp0
    lda #>rsCX
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwCX
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print DX
    lda #<rsDX
    sta gzwTmp0
    lda #>rsDX
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwDX
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    jsr nmi_wait

    ; print SI
    lda #<rsSI
    sta gzwTmp0
    lda #>rsSI
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwSI
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print DI
    lda #<rsDI
    sta gzwTmp0
    lda #>rsDI
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwDI
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print BP
    lda #<rsBP
    sta gzwTmp0
    lda #>rsBP
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwBP
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print SP
    lda #<rsSP
    sta gzwTmp0
    lda #>rsSP
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwSP
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print IP
    lda #<rsIP
    sta gzwTmp0
    lda #>rsIP
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwIP
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    jsr nmi_wait

    ; print CS
    lda #<rsCS
    sta gzwTmp0
    lda #>rsCS
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwCS
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print DS
    lda #<rsDS
    sta gzwTmp0
    lda #>rsDS
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwDS
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print ES
    lda #<rsES
    sta gzwTmp0
    lda #>rsES
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwES
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print SS
    lda #<rsSS
    sta gzwTmp0
    lda #>rsSS
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwSS
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print Flags
    lda #<rsFlags
    sta gzwTmp0
    lda #>rsFlags
    sta gzwTmp0+1
    jsr con_print_str

    lda zwFlags
    jsr con_print_bin
    lda zwFlags+1
    jsr con_print_bin

jsr nmi_wait

    ; print S1
    lda #<rsS1
    sta gzwTmp0
    lda #>rsS1
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwWorkSrc1X
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print S2
    lda #<rsS2
    sta gzwTmp0
    lda #>rsS2
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwWorkSrc2X
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print D1
    lda #<rsD1
    sta gzwTmp0
    lda #>rsD1
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zwWorkDstX
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy #2
    jsr con_print_arr

    ; print instruction
    lda #<rsInstr
    sta gzwTmp0
    lda #>rsInstr
    sta gzwTmp0+1
    jsr con_print_str

    lda #<zaInstrBufBegin
    sta gzwTmp0
    lda #0
    sta gzwTmp0+1
    ldy zbInstrLen
    iny
    jsr con_print_arr

    lda #<rsSpace
    sta gzwTmp0
    lda #>rsSpace
    sta gzwTmp0+1
    jsr con_print_str

    rts
.endproc