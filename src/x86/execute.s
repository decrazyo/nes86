
.include "x86/execute.inc"
.include "x86/mmu.inc"
.include "x86/reg.inc"
.include "x86.inc"

.include "tmp.inc"

.export execute

.segment "RODATA"

; instruction types
.enum
    E00 ; NOP
    E01 ; INC 16
    E02 ; DEC 16
    E03 ; ADD 8
    E04 ; ADD 16
    E05 ; SUB 8
    E06 ; SUB 16
    E07 ; MOV 8
    E08 ; MOV 16
    ; begin conditional jumps
    E09 ; JO
    E10 ; JNO
    E11 ; JB
    E12 ; JNB
    E13 ; JZ
    E14 ; JNZ
    E15 ; JBE
    E16 ; JA
    E17 ; JS
    E18 ; JNS
    E19 ; JPE
    E20 ; JPO
    E21 ; JL
    E22 ; JGE
    E23 ; JLE
    E24 ; JG
    ; end conditional jumps
    E25 ; AND 8
    E26 ; AND 16
    E27 ; OR 8
    E28 ; OR 16
    E29 ; XOR 8
    E30 ; XOR 16
    E31 ; ADC 8
    E32 ; ADC 16
    E33 ; SBB 8
    E34 ; SBB 16
    E35 ; MOV r/m, seg
    E36 ; MOV seg, r/m
    ; begin flag instructions
    E37 ; CMC
    E38 ; CLC
    E39 ; STC
    E40 ; CLI
    E41 ; STI
    E42 ; CLD
    E43 ; STD
    ; end flag instructions
    E44 ; PUSH reg
    E45 ; PUSH seg
    E46 ; POP reg
    E47 ; POP seg
    E48 ; JMP 8
    E49 ; JMP 16
    E50 ; CALL 16
    E51 ; RET imm16
    E52 ; RET
    E53 ; RETF imm16
    E54 ; RETF

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

; TODO: optimize this a bit

; map instruction types to their execution functions.
rbaExecuteFuncLo:
.byte <(execute_nop-1)
.byte <(execute_inc_16-1)
.byte <(execute_dec_16-1)
.byte <(execute_add_8-1)
.byte <(execute_add_16-1)
.byte <(execute_sub_8-1)
.byte <(execute_sub_16-1)
.byte <(execute_mov_8-1)
.byte <(execute_mov_16-1)
.byte <(execute_jo-1)
.byte <(execute_jno-1)
.byte <(execute_jb-1)
.byte <(execute_jnb-1)
.byte <(execute_jz-1)
.byte <(execute_jnz-1)
.byte <(execute_jbe-1)
.byte <(execute_ja-1)
.byte <(execute_js-1)
.byte <(execute_jns-1)
.byte <(execute_jpe-1)
.byte <(execute_jpo-1)
.byte <(execute_jl-1)
.byte <(execute_jge-1)
.byte <(execute_jle-1)
.byte <(execute_jg-1)
.byte <(execute_and_8-1)
.byte <(execute_and_16-1)
.byte <(execute_or_8-1)
.byte <(execute_or_16-1)
.byte <(execute_xor_8-1)
.byte <(execute_xor_16-1)
.byte <(execute_adc_8-1)
.byte <(execute_adc_16-1)
.byte <(execute_sbb_8-1)
.byte <(execute_sbb_16-1)
.byte <(execute_mov_rm_seg-1)
.byte <(execute_mov_seg_rm-1)
.byte <(execute_cmc-1)
.byte <(execute_clc-1)
.byte <(execute_stc-1)
.byte <(execute_cli-1)
.byte <(execute_sti-1)
.byte <(execute_cld-1)
.byte <(execute_std-1)
.byte <(execute_push_reg-1)
.byte <(execute_push_seg-1)
.byte <(execute_pop_reg-1)
.byte <(execute_pop_seg-1)
.byte <(execute_jmp8-1)
.byte <(execute_jmp16-1)
.byte <(execute_call16-1)
.byte <(execute_ret_imm16-1)
.byte <(execute_ret-1)
.byte <(execute_retf_imm16-1)
.byte <(execute_retf-1)
.byte <(execute_bad-1)
rbaExecuteFuncHi:
.byte >(execute_nop-1)
.byte >(execute_inc_16-1)
.byte >(execute_dec_16-1)
.byte >(execute_add_8-1)
.byte >(execute_add_16-1)
.byte >(execute_sub_8-1)
.byte >(execute_sub_16-1)
.byte >(execute_mov_8-1)
.byte >(execute_mov_16-1)
.byte >(execute_jo-1)
.byte >(execute_jno-1)
.byte >(execute_jb-1)
.byte >(execute_jnb-1)
.byte >(execute_jz-1)
.byte >(execute_jnz-1)
.byte >(execute_jbe-1)
.byte >(execute_ja-1)
.byte >(execute_js-1)
.byte >(execute_jns-1)
.byte >(execute_jpe-1)
.byte >(execute_jpo-1)
.byte >(execute_jl-1)
.byte >(execute_jge-1)
.byte >(execute_jle-1)
.byte >(execute_jg-1)
.byte >(execute_and_8-1)
.byte >(execute_and_16-1)
.byte >(execute_or_8-1)
.byte >(execute_or_16-1)
.byte >(execute_xor_8-1)
.byte >(execute_xor_16-1)
.byte >(execute_adc_8-1)
.byte >(execute_adc_16-1)
.byte >(execute_sbb_8-1)
.byte >(execute_sbb_16-1)
.byte >(execute_mov_rm_seg-1)
.byte >(execute_mov_seg_rm-1)
.byte >(execute_cmc-1)
.byte >(execute_clc-1)
.byte >(execute_stc-1)
.byte >(execute_cli-1)
.byte >(execute_sti-1)
.byte >(execute_cld-1)
.byte >(execute_std-1)
.byte >(execute_push_reg-1)
.byte >(execute_push_seg-1)
.byte >(execute_pop_reg-1)
.byte >(execute_pop_seg-1)
.byte >(execute_jmp8-1)
.byte >(execute_jmp16-1)
.byte >(execute_call16-1)
.byte >(execute_ret_imm16-1)
.byte >(execute_ret-1)
.byte >(execute_retf_imm16-1)
.byte >(execute_retf-1)
.byte >(execute_bad-1)
rbaExecuteFuncEnd:

.assert (rbaExecuteFuncHi - rbaExecuteFuncLo) = (rbaExecuteFuncEnd - rbaExecuteFuncHi), error, "incomplete execute function"
.assert (rbaExecuteFuncHi - rbaExecuteFuncLo) = FUNC_COUNT, error, "execute function count"

; map opcodes to instruction types.
rbaInstrExecute:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte E03,E04,E03,E04,E03,E04,E45,E47,E27,E28,E27,E28,E27,E28,E45,BAD ; 0_
.byte E31,E32,E31,E32,E31,E32,E45,E47,E33,E34,E33,E34,E33,E34,E45,E47 ; 1_
.byte E25,E26,E25,E26,E25,E26,BAD,BAD,E05,E06,E05,E06,E05,E06,BAD,BAD ; 2_
.byte E29,E30,E29,E30,E29,E30,BAD,BAD,E05,E06,E05,E06,E05,E06,BAD,BAD ; 3_
.byte E01,E01,E01,E01,E01,E01,E01,E01,E02,E02,E02,E02,E02,E02,E02,E02 ; 4_
.byte E44,E44,E44,E44,E44,E44,E44,E44,E46,E46,E46,E46,E46,E46,E46,E46 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte E09,E10,E11,E12,E13,E14,E15,E16,E17,E18,E19,E20,E21,E22,E23,E24 ; 7_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,E07,E08,E07,E08,E35,BAD,E36,BAD ; 8_
.byte E00,E00,E00,E00,E00,E00,E00,E00,BAD,BAD,E00,BAD,BAD,BAD,BAD,BAD ; 9_
.byte E07,E08,E07,E08,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; A_
.byte E07,E07,E07,E07,E07,E07,E07,E07,E08,E08,E08,E08,E08,E08,E08,E08 ; B_
.byte BAD,BAD,E51,E52,BAD,BAD,BAD,BAD,BAD,BAD,E53,E54,BAD,BAD,BAD,BAD ; C_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; D_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,E50,E49,E00,E48,BAD,BAD,BAD,BAD ; E_
.byte BAD,BAD,BAD,BAD,BAD,E37,BAD,BAD,E38,E39,E40,E41,E42,E43,BAD,BAD ; F_

.segment "CODE"

; TODO: document things

; ==============================================================================
; public interface
; ==============================================================================

; execute the current instruction.
.proc execute
    ldx Reg::zbInstrOpcode
    ldy rbaInstrExecute, x
    lda rbaExecuteFuncHi, y
    pha
    lda rbaExecuteFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; execution handlers
; ==============================================================================

; TODO: rewrite these functions to improve performance.
; TODO: optimize jsr rts

.proc execute_nop
    rts
.endproc


.proc execute_inc_16
    ; write 1 to zwS1 so we can use a generic add function.
    ; this also makes setting processor flags easier.
    ldx #1
    stx Reg::zwS1
    dex
    stx Reg::zwS1+1

    clc
    ldy #2
    jsr add_with_carry

    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_add_16

    rts
.endproc


.proc execute_dec_16
    ; write 1 to zwS1 so we can use a generic subtract function.
    ; this also makes setting processor flags easier.
    ldx #1
    stx Reg::zwS1
    dex
    stx Reg::zwS1+1

    sec
    ldy #2
    jsr sub_with_borrow

    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_sub_16

    rts
.endproc


.proc execute_add_8
    clc
    ldy #1
    jsr add_with_carry

    jsr set_carry_flag_add_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_add_8

    rts
.endproc


.proc execute_add_16
    clc
    ldy #2
    jsr add_with_carry

    jsr set_carry_flag_add_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_add_16

    rts
.endproc


.proc execute_adc_8
    lda Reg::zbFlagsLo
    lsr

    ldy #1
    jsr add_with_carry

    jsr set_carry_flag_add_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_add_8

    rts
.endproc


.proc execute_adc_16
    lda Reg::zbFlagsLo
    lsr

    ldy #2
    jsr add_with_carry

    jsr set_carry_flag_add_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_add
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_add_16

    rts
.endproc


.proc execute_sub_8
    sec
    ldy #1
    jsr sub_with_borrow

    jsr set_carry_flag_sub_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_sub_8

    rts
.endproc


.proc execute_sub_16
    sec
    ldy #2
    jsr sub_with_borrow

    jsr set_carry_flag_sub_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_sub_16

    rts
.endproc


.proc execute_sbb_8
    lda Reg::zbFlagsLo
    eor #1
    lsr

    ldy #1
    jsr sub_with_borrow

    jsr set_carry_flag_sub_8
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_8
    jsr set_sign_flag_8
    jsr set_overflow_flag_sub_8

    rts
.endproc


.proc execute_sbb_16
    lda Reg::zbFlagsLo
    eor #1
    lsr

    ldy #2
    jsr sub_with_borrow

    jsr set_carry_flag_sub_16
    jsr set_parity_flag
    jsr set_auxiliary_flag_sub
    jsr set_zero_flag_16
    jsr set_sign_flag_16
    jsr set_overflow_flag_sub_16

    rts
.endproc


.proc execute_mov_8
    lda Reg::zwS1
    sta Reg::zwD0
    rts
.endproc


.proc execute_mov_16
    jsr execute_mov_8
    lda Reg::zwS1+1
    sta Reg::zwD0+1
    rts
.endproc


.proc execute_jo
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_OF
    jmp rel_jmp8_set
.endproc


.proc execute_jno
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_OF
    jmp rel_jmp8_clear
.endproc


.proc execute_jb
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_CF
    jmp rel_jmp8_set
.endproc


.proc execute_jnb
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_CF
    jmp rel_jmp8_clear
.endproc


.proc execute_jz
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_ZF
    jmp rel_jmp8_set
.endproc


.proc execute_jnz
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_ZF
    jmp rel_jmp8_clear
.endproc


.proc execute_jbe
    lda Reg::zbFlagsLo
    and #<(Reg::FLAG_CF | Reg::FLAG_ZF)
    jmp rel_jmp8_set
.endproc


.proc execute_ja
    lda Reg::zbFlagsLo
    and #<(Reg::FLAG_CF | Reg::FLAG_ZF)
    jmp rel_jmp8_clear
.endproc


.proc execute_js
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_SF
    jmp rel_jmp8_set
.endproc


.proc execute_jns
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_SF
    jmp rel_jmp8_clear
.endproc


.proc execute_jpe
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_PF
    jmp rel_jmp8_set
.endproc


.proc execute_jpo
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_PF
    jmp rel_jmp8_clear
.endproc


.proc execute_jl
    jsr cmp_cf_of
    jmp rel_jmp8_set
.endproc


.proc execute_jge
    jsr cmp_cf_of
    jmp rel_jmp8_clear
.endproc


execute_jle:
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_ZF
    bne rel_jmp8_set_do_jump ; branch if x86 zero flag is set
    jsr cmp_cf_of
; i'm SO fucking sick of fighting the assembler to make this shit work .proc
; so i'm just using normal labels with stupidly long names :s
rel_jmp8_set:
    bne rel_jmp8_set_do_jump
    jmp copy_s0_to_d0 ; jsr rts -> jmp
rel_jmp8_set_do_jump:
    jmp rel_jmp8 ; jsr rts -> jmp


execute_jg:
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_ZF
    bne rel_jmp8_clear_no_jump ; branch if x86 zero flag is set
    jsr cmp_cf_of
rel_jmp8_clear:
    beq rel_jmp8_clear_do_jump
rel_jmp8_clear_no_jump:
    jmp copy_s0_to_d0 ; jsr rts -> jmp
rel_jmp8_clear_do_jump:
    jmp rel_jmp8 ; jsr rts -> jmp


.proc execute_and_8
    ldy #1
    jsr and_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_8
    jsr set_sign_flag_8

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


.proc execute_and_16
    ldy #2
    jsr and_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_16
    jsr set_sign_flag_16

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


.proc execute_or_8
    ldy #1
    jsr or_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_8
    jsr set_sign_flag_8

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


.proc execute_or_16
    ldy #2
    jsr or_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_16
    jsr set_sign_flag_16

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


.proc execute_xor_8
    ldy #1
    jsr xor_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_8
    jsr set_sign_flag_8

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


.proc execute_xor_16
    ldy #2
    jsr xor_y_bytes

    lda #<Reg::FLAG_CF
    jsr Reg::clear_flag_lo

    jsr set_parity_flag
    jsr set_zero_flag_16
    jsr set_sign_flag_16

    lda #>Reg::FLAG_OF
    jsr Reg::clear_flag_hi

    rts
.endproc


; move a segment register into a register or memory
; zwS1 will be shifted right by 4 bits
.proc execute_mov_rm_seg
    ; assemble the first byte
    lda Reg::zwS1
    sta Reg::zwD0
    lda Reg::zwS1+1
    sta Reg::zwD0+1
    rts
.endproc


; move a register or memory into a segment register
; zwS1 will be shifted left by 4 bits
.proc execute_mov_seg_rm
    ; shift the first byte
    lda Reg::zwS1
    sta Reg::zwD0
    lda Reg::zwS1+1
    sta Reg::zwD0+1
    rts
.endproc


.proc execute_cmc
    lda Reg::zbFlagsLo
    eor #<Reg::FLAG_CF
    sta Reg::zbFlagsLo
    rts
.endproc


.proc execute_clc
    lda Reg::zbFlagsLo
    and #<(~Reg::FLAG_CF)
    sta Reg::zbFlagsLo
    rts
.endproc


.proc execute_stc
    lda Reg::zbFlagsLo
    ora #<Reg::FLAG_CF
    sta Reg::zbFlagsLo
    rts
.endproc


.proc execute_cli
    lda Reg::zbFlagsHi
    and #>(~Reg::FLAG_IF)
    sta Reg::zbFlagsHi
    rts
.endproc


.proc execute_sti
    lda Reg::zbFlagsHi
    ora #>Reg::FLAG_IF
    sta Reg::zbFlagsHi
    rts
.endproc


.proc execute_cld
    lda Reg::zbFlagsHi
    and #>(~Reg::FLAG_DF)
    sta Reg::zbFlagsHi
    rts
.endproc


.proc execute_std
    lda Reg::zbFlagsHi
    ora #>Reg::FLAG_DF
    sta Reg::zbFlagsHi
    rts
.endproc


; TODO: remove these
.proc execute_push_reg
    jmp execute_mov_16
.endproc

.proc execute_push_seg
    jmp execute_mov_rm_seg
.endproc

.proc execute_pop_reg
    jmp execute_mov_16
.endproc

.proc execute_pop_seg
    jmp execute_mov_seg_rm
.endproc


.proc execute_jmp8
    jmp rel_jmp8
.endproc


.proc execute_jmp16
    jmp rel_jmp16
.endproc


.proc execute_call16
    jmp rel_jmp16
.endproc


.proc execute_ret_imm16
    jsr execute_ret
pop_args:
    ; TODO: just calculate the new stack address and write it to S0.
    ;       write can handle copying S0 to SP.
    ;       no need to pop each individual value.
    ldx Reg::zwS0
    bne inner_loop

outer_loop:
    ldy Reg::zwS0+1
    beq done
    dey
    sty Reg::zwS0+1
    ; X should always be 0 here

inner_loop:
    jsr Mmu::pop_word
    dex
    bne inner_loop
    beq outer_loop

done:
    rts
.endproc


.proc execute_ret
    jsr Mmu::pop_word
    lda Tmp::zw0
    sta Reg::zwD0
    lda Tmp::zw0+1
    sta Reg::zwD0+1
    rts
.endproc


.proc execute_retf_imm16
    jsr execute_retf
    jmp execute_ret_imm16::pop_args ; jsr rts -> jmp
.endproc


.proc execute_retf
    jsr execute_ret

    ; pop cs
    jsr Mmu::pop_word
    lda Tmp::zw0
    sta Reg::zwS1
    lda Tmp::zw0+1
    sta Reg::zwS1+1
    rts
.endproc


.proc execute_bad
    lda #X86::Err::EXECUTE_FUNC
    jmp X86::panic
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; < Y = number of bytes to add
; < C = initial carry
.proc add_with_carry
    ldx #0
loop:
    lda Reg::zwS0, x
    adc Reg::zwS1, x
    sta Reg::zwD0, x
    inx
    dey
    bne loop
    rts
.endproc


; < Y = number of bytes to add
; < C = initial borrow
.proc sub_with_borrow
    ldx #0
loop:
    lda Reg::zwS0, x
    sbc Reg::zwS1, x
    sta Reg::zwD0, x
    inx
    dey
    bne loop
    rts
.endproc


; > Z = 0 if overflow flag and sign flag match
;   Z = 1 if overflow flag and sign flag don't match
.proc cmp_cf_of
    ; get the overflow flag
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_OF
    ; move the overflow flag to the position of the sign flag
    asl
    asl
    asl
    asl
    ; compare overflow flag to sign flag
    eor Reg::zbFlagsLo
    and #<Reg::FLAG_SF
    rts
.endproc



.proc rel_jmp16
    clc
    ldy #2

    ; check if we are jumping forward or backward
    lda Reg::zwS1+1
    bpl add_offset ; branch if jumping forward

    ; convert the negative number into a positive number that can be subtracted
    eor #$ff
    sta Reg::zwS1+1

    lda Reg::zwS1
sub_offset:
    eor #$ff
    sta Reg::zwS1

    jmp sub_with_borrow

add_offset:
    jmp add_with_carry
.endproc



.proc rel_jmp8
    ; we're doing 16-bit math with an 8-bit number.
    ; zero out Reg::zwS1+1 so 16-bit math is reliable.
    clc
    ldy #2

    lda #0
    sta Reg::zwS1+1

    lda Reg::zwS1
    bpl rel_jmp16::add_offset
    bmi rel_jmp16::sub_offset
.endproc



.proc copy_s0_to_d0
    lda Reg::zwS0
    sta Reg::zwD0
    lda Reg::zwS0+1
    sta Reg::zwD0+1
    rts
.endproc


; < Y = number of bytes to and
.proc and_y_bytes
    ldx #0
loop:
    lda Reg::zwS0, x
    and Reg::zwS1, x
    sta Reg::zwD0, x
    inx
    dey
    bne loop
    rts
.endproc


; < Y = number of bytes to or
.proc or_y_bytes
    ldx #0
loop:
    lda Reg::zwS0, x
    ora Reg::zwS1, x
    sta Reg::zwD0, x
    inx
    dey
    bne loop
    rts
.endproc


; < Y = number of bytes to xor
.proc xor_y_bytes
    ldx #0
loop:
    lda Reg::zwS0, x
    eor Reg::zwS1, x
    sta Reg::zwD0, x
    inx
    dey
    bne loop
    rts
.endproc

; ==============================================================================
; set flags based on execution result
; ==============================================================================


; set the carry flag based the result of an 8-bit addition.
.proc set_carry_flag_add_8
    lda Reg::zwD0
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 16-bit addition.
.proc set_carry_flag_add_16
    lda Reg::zwD0
    ora Reg::zwD0+1
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 8-bit addition.
.proc set_carry_flag_sub_8
    lda Reg::zwD0
    eor #$ff
    beq set_carry_flag
    bne clear_carry_flag
.endproc


; set the carry flag based the result of an 16-bit addition.
.proc set_carry_flag_sub_16
    lda Reg::zwD0
    ora Reg::zwD0+1
    eor #$ff
    beq set_carry_flag
    bne clear_carry_flag
.endproc


clear_carry_flag:
    lda #<Reg::FLAG_CF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_carry_flag:
    lda #<Reg::FLAG_CF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the parity flag based the result of an execution.
; only considers the lowest 8 bits
.proc set_parity_flag
    ; count the number of set bits
    ldx #0
    lda Reg::zwD0
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
    lda #<Reg::FLAG_PF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_flag:
    lda #<Reg::FLAG_PF
    jmp Reg::set_flag_lo ; jsr rts -> jmp
.endproc


; set the auxiliary carry flag if addition caused a carry in the low nibble.
.proc set_auxiliary_flag_add
    lda Reg::zwD0
    and #$0f
    beq set_auxiliary_flag
    bne clear_auxiliary_flag
.endproc


; set the auxiliary carry flag if subtraction caused a carry in the low nibble.
.proc set_auxiliary_flag_sub
    lda Reg::zwD0
    and #$0f
    eor #$0f
    beq set_auxiliary_flag
    bne clear_auxiliary_flag
.endproc


clear_auxiliary_flag:
    lda #<Reg::FLAG_AF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_auxiliary_flag:
    lda #<Reg::FLAG_AF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the zero flag if an 8-bit operation resulted in an output of 0.
.proc set_zero_flag_8
    lda Reg::zwD0
    beq set_zero_flag
    bne clear_zero_flag
.endproc


; set the zero flag if a 16-bit operation resulted in an output of 0.
.proc set_zero_flag_16
    lda Reg::zwD0
    ora Reg::zwD0+1
    beq set_zero_flag
    bne clear_zero_flag
.endproc


clear_zero_flag:
    lda #<Reg::FLAG_ZF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_zero_flag:
    lda #<Reg::FLAG_ZF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_8
    lda Reg::zwD0
    bmi set_sign_flag
    bpl clear_sign_flag
.endproc


; set the sign flag if an execution resulted in a negative output.
.proc set_sign_flag_16
    lda Reg::zwD0+1
    bmi set_sign_flag
    bpl clear_sign_flag
.endproc


clear_sign_flag:
    lda #<Reg::FLAG_SF
    jmp Reg::clear_flag_lo ; jsr rts -> jmp
set_sign_flag:
    lda #<Reg::FLAG_SF
    jmp Reg::set_flag_lo ; jsr rts -> jmp


; set the overflow flag if 8-bit addition caused an arithmetic overflow.
.proc set_overflow_flag_add_8
    lda Reg::zwS0
    eor Reg::zwS1
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zwS0
    eor Reg::zwD0
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if 16-bit addition caused an arithmetic overflow.
.proc set_overflow_flag_add_16
    lda Reg::zwS0+1
    eor Reg::zwS1+1
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zwS0+1
    eor Reg::zwD0+1
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if subtraction caused an arithmetic overflow.
.proc set_overflow_flag_sub_8
    lda Reg::zwS0
    eor Reg::zwS1
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zwS0
    eor Reg::zwD0
    bpl clear_overflow_flag ; branch if source 1 and destination have the same sign
    bmi set_overflow_flag
.endproc


; set the overflow flag if subtraction caused an arithmetic overflow.
.proc set_overflow_flag_sub_16
    lda Reg::zwS0+1
    eor Reg::zwS1+1
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zwS0+1
    eor Reg::zwD0+1
    bpl clear_overflow_flag ; branch if source 1 and destination have the same sign
    bmi set_overflow_flag ; branch if source 1 and destination have the same sign
.endproc


set_overflow_flag:
    lda #>Reg::FLAG_OF
    jmp Reg::set_flag_hi ; jsr rts -> jmp
clear_overflow_flag:
    lda #>Reg::FLAG_OF
    jmp Reg::clear_flag_hi ; jsr rts -> jmp
