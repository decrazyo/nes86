
; This module is responsible for performing arithmetic and logic operations
; on temporary registers.
; This module must not access the x86 address space nor registers other then
; temporary registers and the flags register.
; This module may simply move values between temporary registers to facilitate
; code reuse in the "decode" and "write" stages.
;
; changes:
;   Reg::zbFlags
;   Reg::zbS0
;   Reg::zbS1
;   Reg::zbD0

.include "x86/execute.inc"
.include "x86/fetch.inc"
.include "x86/decode.inc"
.include "x86/write.inc"
.include "x86/mem.inc"
.include "x86/reg.inc"
.include "x86/alu.inc"
.include "x86/util.inc"
.include "x86/io.inc"
.include "x86/interrupt.inc"
.include "x86.inc"
.include "mmc5.inc"

.include "const.inc"
.include "tmp.inc"

.export execute

.export get_carry_flag
.export set_carry_flag
.export clear_carry_flag

.export get_parity_flag
.export set_parity_flag
.export clear_parity_flag

.export get_auxiliary_flag
.export set_auxiliary_flag
.export clear_auxiliary_flag

.export get_zero_flag
.export set_zero_flag
.export clear_zero_flag

.export get_sign_flag
.export set_sign_flag
.export clear_sign_flag

.export get_trap_flag
.export set_trap_flag
.export clear_trap_flag

.export get_interrupt_flag
.export set_interrupt_flag
.export clear_interrupt_flag

.export get_direction_flag
.export set_direction_flag
.export clear_direction_flag

.export get_overflow_flag
.export set_overflow_flag
.export clear_overflow_flag


.segment "RODATA"

; map instruction types to their execution functions.
rbaExecuteFuncLo:
.byte <(execute_nop-1)
.byte <(execute_mov_8-1)
.byte <(execute_mov_16-1)
.byte <(execute_push-1)
.byte <(execute_pop-1)
.byte <(execute_xchg_8-1)
.byte <(execute_xchg_16-1)
.byte <(execute_in_8-1)
.byte <(execute_in_16-1)
.byte <(execute_out_8-1)
.byte <(execute_out_16-1)
.byte <(execute_mov_32-1)
.byte <(execute_add_8_8-1)
.byte <(execute_add_16_16-1)
.byte <(execute_adc_8_8-1)
.byte <(execute_adc_16_16-1)
.byte <(execute_inc_8-1)
.byte <(execute_inc_16-1)
.byte <(execute_aaa-1)
.byte <(execute_daa-1)
.byte <(execute_sub_8_8-1)
.byte <(execute_sub_16_16-1)
.byte <(execute_sbb_8_8-1)
.byte <(execute_sbb_16_16-1)
.byte <(execute_dec_8-1)
.byte <(execute_dec_16-1)
.byte <(execute_aas-1)
.byte <(execute_das-1)
.byte <(execute_aam-1)
.byte <(execute_aad-1)
.byte <(execute_cbw-1)
.byte <(execute_cwd-1)
.byte <(execute_and_8_8-1)
.byte <(execute_and_16_16-1)
.byte <(execute_or_8_8-1)
.byte <(execute_or_16_16-1)
.byte <(execute_xor_8_8-1)
.byte <(execute_xor_16_16-1)
.byte <(execute_rep_repnz-1)
.byte <(execute_repz_repnz-1)
.byte <(execute_call_rel_near-1)
.byte <(execute_call_far-1)
.byte <(execute_jmp_short-1)
.byte <(execute_jmp_rel_near-1)
.byte <(execute_jmp_far-1)
.byte <(execute_ret_near-1)
.byte <(execute_ret_far-1)
.byte <(execute_ret_near_adjust_sp-1)
.byte <(execute_ret_far_adjust_sp-1)
.byte <(execute_jz-1)
.byte <(execute_jl-1)
.byte <(execute_jng-1)
.byte <(execute_jb-1)
.byte <(execute_jna-1)
.byte <(execute_jpe-1)
.byte <(execute_jo-1)
.byte <(execute_js-1)
.byte <(execute_jnz-1)
.byte <(execute_jnl-1)
.byte <(execute_jg-1)
.byte <(execute_jae-1)
.byte <(execute_ja-1)
.byte <(execute_jpo-1)
.byte <(execute_jno-1)
.byte <(execute_jns-1)
.byte <(execute_loop-1)
.byte <(execute_loopz-1)
.byte <(execute_loopnz-1)
.byte <(execute_jcxz-1)
.byte <(execute_int-1)
.byte <(execute_int3-1)
.byte <(execute_into-1)
.byte <(execute_iret-1)
.byte <(execute_clc-1)
.byte <(execute_cmc-1)
.byte <(execute_stc-1)
.byte <(execute_cld-1)
.byte <(execute_std-1)
.byte <(execute_cli-1)
.byte <(execute_sti-1)
.byte <(execute_hlt-1)
.byte <(execute_wait-1)
.byte <(execute_esc-1)
.byte <(execute_nop-1)
.byte <(execute_group1a-1)
.byte <(execute_group1b-1)
.byte <(execute_group2a-1)
.byte <(execute_group2b-1)
.byte <(execute_group3a-1)
.byte <(execute_group3b-1)
.byte <(execute_group4a-1)
.byte <(execute_group4b-1)
.byte <(execute_bad-1)
rbaExecuteFuncHi:
.byte >(execute_nop-1)
.byte >(execute_mov_8-1)
.byte >(execute_mov_16-1)
.byte >(execute_push-1)
.byte >(execute_pop-1)
.byte >(execute_xchg_8-1)
.byte >(execute_xchg_16-1)
.byte >(execute_in_8-1)
.byte >(execute_in_16-1)
.byte >(execute_out_8-1)
.byte >(execute_out_16-1)
.byte >(execute_mov_32-1)
.byte >(execute_add_8_8-1)
.byte >(execute_add_16_16-1)
.byte >(execute_adc_8_8-1)
.byte >(execute_adc_16_16-1)
.byte >(execute_inc_8-1)
.byte >(execute_inc_16-1)
.byte >(execute_aaa-1)
.byte >(execute_daa-1)
.byte >(execute_sub_8_8-1)
.byte >(execute_sub_16_16-1)
.byte >(execute_sbb_8_8-1)
.byte >(execute_sbb_16_16-1)
.byte >(execute_dec_8-1)
.byte >(execute_dec_16-1)
.byte >(execute_aas-1)
.byte >(execute_das-1)
.byte >(execute_aam-1)
.byte >(execute_aad-1)
.byte >(execute_cbw-1)
.byte >(execute_cwd-1)
.byte >(execute_and_8_8-1)
.byte >(execute_and_16_16-1)
.byte >(execute_or_8_8-1)
.byte >(execute_or_16_16-1)
.byte >(execute_xor_8_8-1)
.byte >(execute_xor_16_16-1)
.byte >(execute_rep_repnz-1)
.byte >(execute_repz_repnz-1)
.byte >(execute_call_rel_near-1)
.byte >(execute_call_far-1)
.byte >(execute_jmp_short-1)
.byte >(execute_jmp_rel_near-1)
.byte >(execute_jmp_far-1)
.byte >(execute_ret_near-1)
.byte >(execute_ret_far-1)
.byte >(execute_ret_near_adjust_sp-1)
.byte >(execute_ret_far_adjust_sp-1)
.byte >(execute_jz-1)
.byte >(execute_jl-1)
.byte >(execute_jng-1)
.byte >(execute_jb-1)
.byte >(execute_jna-1)
.byte >(execute_jpe-1)
.byte >(execute_jo-1)
.byte >(execute_js-1)
.byte >(execute_jnz-1)
.byte >(execute_jnl-1)
.byte >(execute_jg-1)
.byte >(execute_jae-1)
.byte >(execute_ja-1)
.byte >(execute_jpo-1)
.byte >(execute_jno-1)
.byte >(execute_jns-1)
.byte >(execute_loop-1)
.byte >(execute_loopz-1)
.byte >(execute_loopnz-1)
.byte >(execute_jcxz-1)
.byte >(execute_int-1)
.byte >(execute_int3-1)
.byte >(execute_into-1)
.byte >(execute_iret-1)
.byte >(execute_clc-1)
.byte >(execute_cmc-1)
.byte >(execute_stc-1)
.byte >(execute_cld-1)
.byte >(execute_std-1)
.byte >(execute_cli-1)
.byte >(execute_sti-1)
.byte >(execute_hlt-1)
.byte >(execute_wait-1)
.byte >(execute_esc-1)
.byte >(execute_nop-1)
.byte >(execute_group1a-1)
.byte >(execute_group1b-1)
.byte >(execute_group2a-1)
.byte >(execute_group2b-1)
.byte >(execute_group3a-1)
.byte >(execute_group3b-1)
.byte >(execute_group4a-1)
.byte >(execute_group4b-1)
.byte >(execute_bad-1)
rbaExecuteFuncEnd:

.assert (rbaExecuteFuncHi - rbaExecuteFuncLo) = (rbaExecuteFuncEnd - rbaExecuteFuncHi), error, "incomplete execute function"

; instruction types
.enum
    E00 ; execute_nop
    E01 ; execute_mov_8
    E02 ; execute_mov_16
    E03 ; execute_push
    E04 ; execute_pop
    E05 ; execute_xchg_8
    E06 ; execute_xchg_16
    E07 ; execute_in_8
    E08 ; execute_in_16
    E09 ; execute_out_8
    E10 ; execute_out_16
    E11 ; execute_mov_32
    E12 ; execute_add_8_8
    E13 ; execute_add_16_16
    E14 ; execute_adc_8_8
    E15 ; execute_adc_16_16
    E16 ; execute_inc_8
    E17 ; execute_inc_16
    E18 ; execute_aaa
    E19 ; execute_daa
    E20 ; execute_sub_8_8
    E21 ; execute_sub_16_16
    E22 ; execute_sbb_8_8
    E23 ; execute_sbb_16_16
    E24 ; execute_dec_8
    E25 ; execute_dec_16
    E26 ; execute_aas
    E27 ; execute_das
    E28 ; execute_aam
    E29 ; execute_aad
    E30 ; execute_cbw
    E31 ; execute_cwd
    E32 ; execute_and_8_8
    E33 ; execute_and_16_16
    E34 ; execute_or_8_8
    E35 ; execute_or_16_16
    E36 ; execute_xor_8_8
    E37 ; execute_xor_16_16
    E38 ; execute_rep_repnz
    E39 ; execute_repz_repnz
    E40 ; execute_call_rel_near
    E41 ; execute_call_far
    E42 ; execute_jmp_short
    E43 ; execute_jmp_rel_near
    E44 ; execute_jmp_far
    E45 ; execute_ret_near
    E46 ; execute_ret_far
    E47 ; execute_ret_near_adjust_sp
    E48 ; execute_ret_far_adjust_sp
    E49 ; execute_jz
    E50 ; execute_jl
    E51 ; execute_jng
    E52 ; execute_jb
    E53 ; execute_jna
    E54 ; execute_jpe
    E55 ; execute_jo
    E56 ; execute_js
    E57 ; execute_jnz
    E58 ; execute_jnl
    E59 ; execute_jg
    E60 ; execute_jae
    E61 ; execute_ja
    E62 ; execute_jpo
    E63 ; execute_jno
    E64 ; execute_jns
    E65 ; execute_loop
    E66 ; execute_loopz
    E67 ; execute_loopnz
    E68 ; execute_jcxz
    E69 ; execute_int
    E70 ; execute_int3
    E71 ; execute_into
    E72 ; execute_iret
    E73 ; execute_clc
    E74 ; execute_cmc
    E75 ; execute_stc
    E76 ; execute_cld
    E77 ; execute_std
    E78 ; execute_cli
    E79 ; execute_sti
    E80 ; execute_hlt
    E81 ; execute_wait
    E82 ; execute_esc
    E83 ; execute_nop
    E84 ; execute_group1a
    E85 ; execute_group1b
    E86 ; execute_group2a
    E87 ; execute_group2b
    E88 ; execute_group3a
    E89 ; execute_group3b
    E90 ; execute_group4a
    E91 ; execute_group4b

    BAD ; used for unimplemented or non-existent instructions
    FUNC_COUNT ; used to check function table size at compile-time
.endenum

.assert (rbaExecuteFuncHi - rbaExecuteFuncLo) = FUNC_COUNT, error, "execute function count"

; map opcodes to instruction types.
rbaInstrExecute:
;      _0  _1  _2  _3  _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte E12,E13,E12,E13,E12,E13,E03,E04,E34,E35,E34,E35,E34,E35,E03,BAD ; 0_
.byte E14,E15,E14,E15,E14,E15,E03,E04,E22,E23,E22,E23,E22,E23,E03,E04 ; 1_
.byte E32,E33,E32,E33,E32,E33,BAD,E19,E20,E21,E20,E21,E20,E21,BAD,E27 ; 2_
.byte E36,E37,E36,E37,E36,E37,BAD,E18,E20,E21,E20,E21,E20,E21,BAD,E26 ; 3_
.byte E17,E17,E17,E17,E17,E17,E17,E17,E25,E25,E25,E25,E25,E25,E25,E25 ; 4_
.byte E03,E03,E03,E03,E03,E03,E03,E03,E04,E04,E04,E04,E04,E04,E04,E04 ; 5_
.byte BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD,BAD ; 6_
.byte E55,E63,E52,E60,E49,E57,E53,E61,E56,E64,E54,E62,E50,E58,E51,E59 ; 7_
.byte E84,E85,BAD,E85,E32,E33,E05,E06,E01,E02,E01,E02,E02,E02,E02,E04 ; 8_
.byte E83,E06,E06,E06,E06,E06,E06,E06,E30,E31,E41,E81,E03,E04,E01,E01 ; 9_
.byte E01,E02,E01,E02,E38,E38,E39,E39,E32,E33,E38,E38,E38,E38,E39,E39 ; A_
.byte E01,E01,E01,E01,E01,E01,E01,E01,E02,E02,E02,E02,E02,E02,E02,E02 ; B_
.byte BAD,BAD,E47,E45,E11,E11,E01,E02,BAD,BAD,E48,E46,E70,E69,E71,E72 ; C_
.byte E86,E87,E86,E87,E28,E29,BAD,E01,E82,E82,E82,E82,E82,E82,E82,E82 ; D_
.byte E67,E66,E65,E68,E07,E08,E09,E10,E40,E43,E44,E42,E07,E08,E09,E10 ; E_
.byte BAD,BAD,BAD,BAD,E80,E74,E88,E89,E73,E75,E78,E79,E76,E77,E90,E91 ; F_

.segment "CODE"

; TODO: document things

; ==============================================================================
; public interface
; ==============================================================================

; execute the current instruction.
.proc execute
    ldx Fetch::zbInstrOpcode
    ldy rbaInstrExecute, x

skip_lookup:
    lda rbaExecuteFuncHi, y
    pha
    lda rbaExecuteFuncLo, y
    pha
    rts
.endproc

; ==============================================================================
; extended instruction handlers
; ==============================================================================

; NOTE: these function tables could be eliminated.
;       we would just need to properly arranging the main function table.
;       that doesn't seem necessary unless we run out of ROM space.

; TODO: fill out the tables with panics so invalid code doesn't crash the emulator.

.segment "RODATA"

rbaGroup1aFuncLo:
.byte <(execute_add_8_8-1)
.byte <(execute_or_8_8-1)
.byte <(execute_adc_8_8-1)
.byte <(execute_sbb_8_8-1)
.byte <(execute_and_8_8-1)
.byte <(execute_sub_8_8-1)
.byte <(execute_xor_8_8-1)
.byte <(execute_sub_8_8-1) ; CMP
rbaGroup1aFuncHi:
.byte >(execute_add_8_8-1)
.byte >(execute_or_8_8-1)
.byte >(execute_adc_8_8-1)
.byte >(execute_sbb_8_8-1)
.byte >(execute_and_8_8-1)
.byte >(execute_sub_8_8-1)
.byte >(execute_xor_8_8-1)
.byte >(execute_sub_8_8-1) ; CMP
rbaGroup1aFuncEnd:

.assert (rbaGroup1aFuncHi - rbaGroup1aFuncLo) = (rbaGroup1aFuncEnd - rbaGroup1aFuncHi), error, "incomplete group 1a address function"

.segment "CODE"

.proc execute_group1a
    ldx Decode::zbExt

    lda rbaGroup1aFuncHi, x
    pha
    lda rbaGroup1aFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup1bFuncLo:
.byte <(execute_add_16_16-1)
.byte <(execute_or_16_16-1)
.byte <(execute_adc_16_16-1)
.byte <(execute_sbb_16_16-1)
.byte <(execute_and_16_16-1)
.byte <(execute_sub_16_16-1)
.byte <(execute_xor_16_16-1)
.byte <(execute_sub_16_16-1) ; CMP
rbaGroup1bFuncHi:
.byte >(execute_add_16_16-1)
.byte >(execute_or_16_16-1)
.byte >(execute_adc_16_16-1)
.byte >(execute_sbb_16_16-1)
.byte >(execute_and_16_16-1)
.byte >(execute_sub_16_16-1)
.byte >(execute_xor_16_16-1)
.byte >(execute_sub_16_16-1) ; CMP
rbaGroup1bFuncEnd:

.assert (rbaGroup1bFuncHi - rbaGroup1bFuncLo) = (rbaGroup1bFuncEnd - rbaGroup1bFuncHi), error, "incomplete group 1b address function"

.segment "CODE"

.proc execute_group1b
    ldx Decode::zbExt

    lda rbaGroup1bFuncHi, x
    pha
    lda rbaGroup1bFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup2aFuncLo:
.byte <(execute_rol_8_8-1)
.byte <(execute_ror_8_8-1)
.byte <(execute_rcl_8_8-1)
.byte <(execute_rcr_8_8-1)
.byte <(execute_shl_8_8-1)
.byte <(execute_shr_8_8-1)
.byte <(execute_bad-1)
.byte <(execute_sar_8_8-1)
rbaGroup2aFuncHi:
.byte >(execute_rol_8_8-1)
.byte >(execute_ror_8_8-1)
.byte >(execute_rcl_8_8-1)
.byte >(execute_rcr_8_8-1)
.byte >(execute_shl_8_8-1)
.byte >(execute_shr_8_8-1)
.byte >(execute_bad-1)
.byte >(execute_sar_8_8-1)
rbaGroup2aFuncEnd:

.assert (rbaGroup2aFuncHi - rbaGroup2aFuncLo) = (rbaGroup2aFuncEnd - rbaGroup2aFuncHi), error, "incomplete group 2a address function"

.segment "CODE"

.proc execute_group2a
    ldx Decode::zbExt

    lda rbaGroup2aFuncHi, x
    pha
    lda rbaGroup2aFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup2bFuncLo:
.byte <(execute_rol_16_8-1)
.byte <(execute_ror_16_8-1)
.byte <(execute_rcl_16_8-1)
.byte <(execute_rcr_16_8-1)
.byte <(execute_shl_16_8-1)
.byte <(execute_shr_16_8-1)
.byte <(execute_bad-1)
.byte <(execute_sar_16_8-1)
rbaGroup2bFuncHi:
.byte >(execute_rol_16_8-1)
.byte >(execute_ror_16_8-1)
.byte >(execute_rcl_16_8-1)
.byte >(execute_rcr_16_8-1)
.byte >(execute_shl_16_8-1)
.byte >(execute_shr_16_8-1)
.byte >(execute_bad-1)
.byte >(execute_sar_16_8-1)
rbaGroup2bFuncEnd:

.assert (rbaGroup2bFuncHi - rbaGroup2bFuncLo) = (rbaGroup2bFuncEnd - rbaGroup2bFuncHi), error, "incomplete group 2b address function"

.segment "CODE"

.proc execute_group2b
    ldx Decode::zbExt

    lda rbaGroup2bFuncHi, x
    pha
    lda rbaGroup2bFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup3aFuncLo:
.byte <(execute_and_8_8-1) ; TEST
.byte <(execute_bad-1)
.byte <(execute_not_8-1)
.byte <(execute_neg_8-1)
.byte <(execute_mul_8_8-1)
.byte <(execute_imul_8_8-1)
.byte <(execute_div_16_8-1)
.byte <(execute_idiv_16_8-1)
rbaGroup3aFuncHi:
.byte >(execute_and_8_8-1) ; TEST
.byte >(execute_bad-1)
.byte >(execute_not_8-1)
.byte >(execute_neg_8-1)
.byte >(execute_mul_8_8-1)
.byte >(execute_imul_8_8-1)
.byte >(execute_div_16_8-1)
.byte >(execute_idiv_16_8-1)
rbaGroup3aFuncEnd:

.assert (rbaGroup3aFuncHi - rbaGroup3aFuncLo) = (rbaGroup3aFuncEnd - rbaGroup3aFuncHi), error, "incomplete group 3a address function"

.segment "CODE"

.proc execute_group3a
    ldx Decode::zbExt

    lda rbaGroup3aFuncHi, x
    pha
    lda rbaGroup3aFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup3bFuncLo:
.byte <(execute_and_16_16-1) ; TEST
.byte <(execute_bad-1)
.byte <(execute_not_16-1)
.byte <(execute_neg_16-1)
.byte <(execute_mul_16_16-1)
.byte <(execute_imul_16_16-1)
.byte <(execute_div_32_16-1)
.byte <(execute_idiv_32_16-1)
rbaGroup3bFuncHi:
.byte >(execute_and_16_16-1) ; TEST
.byte >(execute_bad-1)
.byte >(execute_not_16-1)
.byte >(execute_neg_16-1)
.byte >(execute_mul_16_16-1)
.byte >(execute_imul_16_16-1)
.byte >(execute_div_32_16-1)
.byte >(execute_idiv_32_16-1)
rbaGroup3bFuncEnd:

.assert (rbaGroup3bFuncHi - rbaGroup3bFuncLo) = (rbaGroup3bFuncEnd - rbaGroup3bFuncHi), error, "incomplete group 3b address function"

.segment "CODE"

.proc execute_group3b
    ldx Decode::zbExt

    lda rbaGroup3bFuncHi, x
    pha
    lda rbaGroup3bFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup4aFuncLo:
.byte <(execute_inc_8-1)
.byte <(execute_dec_8-1)
; .byte <(execute_bad-1)
; .byte <(execute_bad-1)
; .byte <(execute_bad-1)
; .byte <(execute_bad-1)
; .byte <(execute_bad-1)
; .byte <(execute_bad-1)
rbaGroup4aFuncHi:
.byte >(execute_inc_8-1)
.byte >(execute_dec_8-1)
; .byte >(execute_bad-1)
; .byte >(execute_bad-1)
; .byte >(execute_bad-1)
; .byte >(execute_bad-1)
; .byte >(execute_bad-1)
; .byte >(execute_bad-1)
rbaGroup4aFuncEnd:

.assert (rbaGroup4aFuncHi - rbaGroup4aFuncLo) = (rbaGroup4aFuncEnd - rbaGroup4aFuncHi), error, "incomplete group 4a address function"

.segment "CODE"

.proc execute_group4a
    ldx Decode::zbExt

    lda rbaGroup4aFuncHi, x
    pha
    lda rbaGroup4aFuncLo, x
    pha
    rts
.endproc

.segment "RODATA"

rbaGroup4bFuncLo:
.byte <(execute_inc_16-1)
.byte <(execute_dec_16-1)
.byte <(execute_call_abs_near-1)
.byte <(execute_call_far-1)
.byte <(execute_jmp_abs_near-1)
.byte <(execute_jmp_far-1)
.byte <(execute_push-1)
.byte <(execute_bad-1)
rbaGroup4bFuncHi:
.byte >(execute_inc_16-1)
.byte >(execute_dec_16-1)
.byte >(execute_call_abs_near-1)
.byte >(execute_call_far-1)
.byte >(execute_jmp_abs_near-1)
.byte >(execute_jmp_far-1)
.byte >(execute_push-1)
.byte >(execute_bad-1)
rbaGroup4bFuncEnd:

.assert (rbaGroup4bFuncHi - rbaGroup4bFuncLo) = (rbaGroup4bFuncEnd - rbaGroup4bFuncHi), error, "incomplete group 4b address function"

.segment "CODE"

.proc execute_group4b
    ldx Decode::zbExt

    lda rbaGroup4bFuncHi, x
    pha
    lda rbaGroup4bFuncLo, x
    pha
    rts
.endproc


; ==============================================================================
; repeat handlers
; ==============================================================================

.segment "RODATA"

; this gives us an index for "execute" to use
rbaStrInstrExecute:
;      _4  _5  _6  _7  _8  _9  _A  _B  _C  _D  _E  _F
.byte E01,E02,E20,E21,BAD,BAD,E01,E02,E01,E02,E20,E21 ; A_

.segment "CODE"

STR_INSTR_OFFSET = $A4
REPNZ_PREFIX = $F2

; execute MOVS/STOS/LODS with or without a repeat prefix
.proc execute_rep_repnz
    ; lookup the handler function index for this instruction
    ; X still holds the instruction opcode
    ldy rbaStrInstrExecute - STR_INSTR_OFFSET, x

    ; check if the instruction has a prefix.
    lda Fetch::zbPrefixRepeat
    beq execute::skip_lookup ; branch if there is no prefix.

    ; check which prefix is being used.
    cmp #REPNZ_PREFIX
    beq execute_repnz ; branch if the prefix is REPNZ
    ; assume prefix is REP
    ; [fall_through]
.endproc

; repeat string instruction as long as CX != 0
.proc execute_rep
    ; execute the string instruction handler
    jsr execute::skip_lookup

    ; check if the instruction needs to be repeated.
    jsr decrement_cx
    beq clear_repeat_prefix ; branch if CX == 0

    rts
.endproc


; execute CMPS/SCAS with or without a repeat prefix
.proc execute_repz_repnz
    ; lookup the handler function index for this instruction
    ; X still holds the instruction opcode
    ldy rbaStrInstrExecute - STR_INSTR_OFFSET, x

    ; check if the instruction has a prefix.
    lda Fetch::zbPrefixRepeat
    beq execute::skip_lookup ; branch if there is no prefix.

    ; check which prefix is being used.
    cmp #REPNZ_PREFIX
    beq execute_repnz ; branch if the prefix is REPNZ
    ; assume prefix is REPZ
    ; [fall_through]
.endproc

; repeat string instruction as long as CX != 0 and ZF == 1.
.proc execute_repz
    ; execute the string instruction handler
    jsr execute::skip_lookup

    ; check if the instruction needs to be repeated.
    jsr decrement_cx
    beq clear_repeat_prefix ; branch if CX == 0

    jsr get_zero_flag
    beq clear_repeat_prefix ; branch if ZF == 0

    rts
.endproc


; repeat string instruction as long as CX != 0 and ZF == 0.
.proc execute_repnz
    ; execute the string instruction handler
    jsr execute::skip_lookup

    ; check if the instruction needs to be repeated.
    jsr decrement_cx
    beq clear_repeat_prefix ; branch if CX == 0

    jsr get_zero_flag
    bne clear_repeat_prefix ; branch if ZF == 1

    rts
.endproc


; clear the repeat prefix to resume normal execution.
.proc clear_repeat_prefix
    lda #0
    sta Fetch::zbPrefixRepeat
    rts
.endproc



; ==============================================================================
; extended execution handlers
; ==============================================================================

.proc execute_ext
    rts
.endproc

; ==============================================================================
; execution handlers
; ==============================================================================

; ----------------------------------------
; data transfer handlers
; ----------------------------------------

; move a 32-bit value.
; < S0X = value to move to D0X
; < S1X = value to move to D1X
; > D0X
; > D1X
; changes: A
.proc execute_mov_32
    lda Reg::zwS1X
    sta Reg::zwD1X
    lda Reg::zwS1X+1
    sta Reg::zwD1X+1
    ; [fall_through]
.endproc

; move a 16-bit value.
; < S0X = value to move to D0X
; > D0X
; changes: A
.proc execute_mov_16
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; move an 8-bit value.
; < S0L = value to move to D0L
; > D0L
; changes: A
.proc execute_mov_8
    lda Reg::zbS0L
    sta Reg::zbD0L
    rts
.endproc


; push a 16-bit value onto the stack.
; < S0X = value to push to the stack.
; changes: A, X, Y
.proc execute_push
    ldx #Reg::zwSS
    jsr Mem::use_segment

    lda Reg::zwS0X
    ldx Reg::zwS0X+1
    jmp Mem::push_word
    ; [tail_jump]
.endproc


.segment "ZEROPAGE"

fuckup: .res 3

.segment "CODE"

; pop a 16-bit value off of the stack.
; > D0X = value popped from the stack.
; changes: A, X, Y
.proc execute_pop

    lda Mem::zaSegment
    sta fuckup
    lda Mem::zaSegment+1
    sta fuckup+1
    lda Mem::zaSegment+2
    sta fuckup+2

    ldx #Reg::zwSS
    jsr Mem::use_segment

    jsr Mem::pop_word
    sta Reg::zwD0X
    stx Reg::zwD0X+1

    lda fuckup
    sta Mem::zaSegment
    lda fuckup+1
    sta Mem::zaSegment+1
    lda fuckup+2
    sta Mem::zaSegment+2

    rts
.endproc


; exchange 2 16-bit values.
; < S0X = value to move to D1X
; < S1X = value to move to D0X
; > D0X
; > D1X
.proc execute_xchg_16
    lda Reg::zwS0X+1
    sta Reg::zwD1X+1

    lda Reg::zwS1X+1
    sta Reg::zwD0X+1
    ; [fall_through]
.endproc

; exchange 2 8-bit values.
; < S0L = value to move to D1L
; < S1L = value to move to D0L
; > D0L
; > D1L
.proc execute_xchg_8
    lda Reg::zbS0L
    sta Reg::zbD1L

    lda Reg::zbS1L
    sta Reg::zbD0L
    rts
.endproc

; TODO: implement IN and OUT instructions.
;       we'll do this once it's needed.

.proc execute_in_16
    jsr Io::in
    sta Reg::zbD0L
    rts
.endproc

.proc execute_in_8
    jsr Io::in
    sta Reg::zwD0X
    stx Reg::zwD0X+1
    rts
.endproc

.proc execute_out_16
    jmp Io::out
.endproc

.proc execute_out_8
    jmp Io::out
.endproc

; ----------------------------------------
; arithmetic handlers
; ----------------------------------------

; 16-bit addition.
; < S0X = addend
; < S1X = addend
; > D0X = sum
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_add_16_16
    jsr Alu::add_16_16
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_add_16
    ; [tail_jump]
.endproc


; 8-bit addition.
; < S0L = addend
; < S1L = addend
; > D0L = sum
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_add_8_8
    jsr Alu::add_8_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_add_8
    ; [tail_jump]
.endproc


; 16-bit addition with carry.
; < S0X = addend
; < S1X = addend
; > D0X = sum
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_adc_16_16
    jsr load_carry_flag
    jsr Alu::adc_16_16
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_add_16
    ; [tail_jump]
.endproc


; 8-bit addition with carry.
; < S0L = addend
; < S1L = addend
; > D0L = sum
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_adc_8_8
    jsr load_carry_flag
    jsr Alu::adc_8_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_add_8
    ; [tail_jump]
.endproc


; 16-bit increment.
; < S0X
; > D0X
; flags: PF, AF, ZF, SF, OF
.proc execute_inc_16
    jsr Alu::inc_16
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_inc_16
    ; [tail_jump]
.endproc


; 8-bit increment.
; < S0L
; > D0L
; flags: PF, AF, ZF, SF, OF
.proc execute_inc_8
    jsr Alu::inc_8
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_inc_8
    ; [tail_jump]
.endproc


; ASCII adjust after addition.
; adjusts the sum of two unpacked BCD values to create an unpacked BCD result.
; TODO: optimize away copying AX in the decode stage?
; < S0X = AX
; > D0X
; flags: CF, AF
.proc execute_aaa
    jsr get_auxiliary_flag
    bne do_adjust ; branch if auxiliary flag is set

    lda Reg::zbS0L
    and #$0f
    cmp #9+1
    bcs do_adjust ; branch if ((S0L & $0f) > 9)

    sta Reg::zbD0L
    lda Reg::zbS0H
    sta Reg::zbD0H

    jsr clear_carry_flag
    jmp clear_auxiliary_flag
    ; [tail_jump]

do_adjust:
    AAA_ADJUST = $0106
    lda #<AAA_ADJUST
    sta Reg::zwS1X
    lda #>AAA_ADJUST
    sta Reg::zwS1X+1

    jsr Alu::add_16_16

    lda Reg::zbD0L
    and #$0f
    sta Reg::zbD0L

    jsr set_carry_flag
    jmp set_auxiliary_flag
    ; [tail_jump]
.endproc


; decimal adjust after addition.
; adjusts the sum of two packed BCD values to create a packed BCD result.
; i'm not 100% sure if that this implementation is correct but it should be close.
; this instruction probably isn't used for anything critical so i'm not too worried.
; TODO: optimize away copying AL in the decode stage?
; NOTE: the 8086 documentation provides conflicting information about the state of OF.
;       it is unclear if it should be set according to the result or undefined.
;       i'm leaving it unchanged.
; < S0L = AL
; > D0L
; flags: CF, PF, AF, ZF, SF, OF?
.proc execute_daa
    DAA_ADJUST_LO = $06
    DAA_ADJUST_HI = $60

    jsr get_auxiliary_flag
    bne do_adjust_lo ; branch if auxiliary flag is set

    lda Reg::zbS0L
    and #$0f
    cmp #9+1
    bcs do_adjust_lo ; branch if ((S0L & $0f) > 9)

    lda Reg::zbS0L
    sta Reg::zbD0L

    jsr clear_auxiliary_flag

    jmp check_adjust_hi

do_adjust_lo:
    clc
    lda Reg::zbS0L
    adc #DAA_ADJUST_LO
    sta Reg::zbD0L

    jsr set_auxiliary_flag

check_adjust_hi:
    jsr load_carry_flag
    bcs do_adjust_hi ; branch if carry flag is set

    lda Reg::zbS0L
    cmp #$99+1
    bcs do_adjust_hi ; branch if (S0L > $99)

    jsr clear_carry_flag
    jmp calc_flags

do_adjust_hi:
    clc
    lda Reg::zbD0L
    adc #DAA_ADJUST_HI
    sta Reg::zbD0L

    jsr set_carry_flag

calc_flags:
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jmp calc_sign_flag_8
    ; [tail_jump]
.endproc


; 16-bit subtraction.
; < S0X = minuend
; < S1X = subtrahend
; > D0X = difference
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_sub_16_16
    jsr Alu::sub_16_16
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_sub_16
    ; [tail_jump]
.endproc


; 8-bit subtraction.
; < S0L = minuend
; < S1L = subtrahend
; > D0L = difference
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_sub_8_8
    jsr Alu::sub_8_8
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_sub_8
    ; [tail_jump]
.endproc


; 16-bit subtraction with borrow.
; < S0X = minuend
; < S1X = subtrahend
; > D0X = difference
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_sbb_16_16
    jsr load_not_carry_flag
    jsr Alu::sbb_16_16
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_sub_16
    ; [tail_jump]
.endproc


; 8-bit subtraction with borrow.
; < S0L = minuend
; < S1L = subtrahend
; > D0L = difference
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_sbb_8_8
    jsr load_not_carry_flag
    jsr Alu::sbb_8_8
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_sub_8
    ; [tail_jump]
.endproc


; 16-bit decrement.
; < S0X
; > D0X
; flags: PF, AF, ZF, SF, OF
.proc execute_dec_16
    jsr Alu::dec_16
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_dec_16
    ; [tail_jump]
.endproc


; 8-bit decrement.
; < S0L
; > D0L
; flags: PF, AF, ZF, SF, OF
.proc execute_dec_8
    jsr Alu::dec_8
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_dec_8
    ; [tail_jump]
.endproc


; 16-bit two's complement negation
; < S0X
; > D0X
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_neg_16
    jsr Alu::neg_16
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_neg_16
    ; [tail_jump]
.endproc


; 8-bit two's complement negation
; < S0L
; > D0L
; flags: CF, PF, AF, ZF, SF, OF
.proc execute_neg_8
    jsr Alu::neg_8
    jsr store_not_carry_flag
    jsr calc_parity_flag
    jsr calc_auxiliary_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_neg_8
    ; [tail_jump]
.endproc


; ASCII adjust after subtraction.
; adjusts the difference of two unpacked BCD values to create a unpacked BCD result.
; TODO: optimize away copying AX in the decode stage?
; < S0X = AX
; > D0X
; flags: CF, AF
.proc execute_aas
    jsr get_auxiliary_flag
    bne do_adjust ; branch if auxiliary flag is set

    lda Reg::zbS0L
    and #$0f
    cmp #9+1
    bcs do_adjust ; branch if ((S0L & $0f) > 9)

    sta Reg::zbD0L
    lda Reg::zbS0H
    sta Reg::zbD0H

    jsr clear_carry_flag
    jmp clear_auxiliary_flag
    ; [tail_jump]

do_adjust:
    AAS_ADJUST = $0106
    lda #<AAS_ADJUST
    sta Reg::zwS1X
    lda #>AAS_ADJUST
    sta Reg::zwS1X+1

    jsr Alu::sub_16_16

    lda Reg::zbD0L
    and #$0f
    sta Reg::zbD0L

    jsr set_carry_flag
    jmp set_auxiliary_flag
    ; [tail_jump]
.endproc

; decimal adjust after subtraction.
; adjusts the difference of two packed BCD values to create a packed BCD result.
; i'm not 100% sure if that this implementation is correct but it should be close.
; this instruction probably isn't used for anything critical so i'm not too worried.
; TODO: optimize away copying AL in the decode stage?
; < S0L = AL
; > D0L
; flags: CF, PF, AF, ZF, SF
.proc execute_das
    DAS_ADJUST_LO = $06
    DAS_ADJUST_HI = $60

    jsr get_auxiliary_flag
    bne do_adjust_lo ; branch if auxiliary flag is set

    lda Reg::zbS0L
    and #$0f
    cmp #9+1
    bcs do_adjust_lo ; branch if ((S0L & $0f) > 9)

    lda Reg::zbS0L
    sta Reg::zbD0L

    jsr clear_auxiliary_flag

    jmp check_adjust_hi

do_adjust_lo:
    sec
    lda Reg::zbS0L
    sbc #DAS_ADJUST_LO
    sta Reg::zbD0L

    jsr set_auxiliary_flag

check_adjust_hi:
    jsr load_carry_flag
    bcs do_adjust_hi ; branch if carry flag is set

    lda Reg::zbS0L
    cmp #$99+1
    bcs do_adjust_hi ; branch if (S0L > $99)

    jsr clear_carry_flag
    jmp calc_flags

do_adjust_hi:
    sec
    lda Reg::zbD0L
    sbc #DAS_ADJUST_HI
    sta Reg::zbD0L

    jsr set_carry_flag

calc_flags:
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jmp calc_sign_flag_8
    ; [tail_jump]
.endproc


; 16-bit multiplication
; < S0X = multiplicand
; < S1X = multiplier
; > D0X = product low word
; > D1X = product high word
.proc execute_mul_16_16
    lda Reg::zwAX
    sta Reg::zwS1X
    lda Reg::zwAX+1
    sta Reg::zwS1X+1

    jsr Alu::mul_16_16
    jsr calc_overflow_flag_mul_16
    jsr store_carry_flag

    lda Reg::zwD0X
    sta Reg::zwAX
    lda Reg::zwD0X+1
    sta Reg::zwAX+1
    lda Reg::zwD1X
    sta Reg::zwDX
    lda Reg::zwD1X+1
    sta Reg::zwDX+1
    rts
.endproc


; 8-bit multiplication
; < S0L = multiplicand
; < S1L = multiplier
; > D0X = product
.proc execute_mul_8_8
    lda Reg::zbAL
    sta Reg::zbS1L

    jsr Alu::mul_8_8
    jsr calc_overflow_flag_mul_8
    jsr store_carry_flag

    lda Reg::zwD0X
    sta Reg::zwAX
    lda Reg::zwD0X+1
    sta Reg::zwAX+1
    rts
.endproc


.proc execute_imul_16_16
    lda Reg::zwAX
    sta Reg::zwS1X
    lda Reg::zwAX+1
    sta Reg::zwS1X+1

    jsr Alu::imul_16_16
    jsr calc_overflow_flag_imul_16
    jsr store_carry_flag

    lda Reg::zwD0X
    sta Reg::zwAX
    lda Reg::zwD0X+1
    sta Reg::zwAX+1

    lda Reg::zwD1X
    sta Reg::zwDX
    lda Reg::zwD1X+1
    sta Reg::zwDX+1
    rts
.endproc


.proc execute_imul_8_8
    lda Reg::zbAL
    sta Reg::zbS1L

    jsr Alu::imul_8_8
    jsr calc_overflow_flag_imul_8
    jsr store_carry_flag

    lda Reg::zbD0L
    sta Reg::zbAL
    lda Reg::zbD0H
    sta Reg::zbAH
    rts
.endproc


; ASCII adjust after multiplication
; adjusts the product of two unpacked BCD values to create a pair of unpacked BCD values.
; < S0L = dividend (AL)
; < S1L = divisor
; > D1L = remainder (AL)
; > D1L = quotient (AX)
; flags: SF, ZF, PF
.proc execute_aam
    jsr Alu::aam_8_8
    jsr calc_sign_flag_8
    jsr calc_zero_flag_8
    jmp calc_parity_flag
    ; [tail_jump]
.endproc

; NOTE: the division functions are full of exceptions to the normal rules of the emulator.

.proc execute_div_32_16
    lda Reg::zwAX
    sta Reg::zwD0X
    lda Reg::zwAX+1
    sta Reg::zwD0X+1

    lda Reg::zwDX
    sta Reg::zwD1X
    lda Reg::zwDX+1
    sta Reg::zwD1X+1

    jsr Alu::div_32_16
    bcc success
    lda #Interrupt::DIVIDE_ERROR
    jmp Interrupt::int
success:

    lda Reg::zwS1X
    sta Reg::zwAX
    lda Reg::zwS1X+1
    sta Reg::zwAX+1

    lda Reg::zwD0X
    sta Reg::zwDX
    lda Reg::zwD0X+1
    sta Reg::zwDX+1
    rts
.endproc

.proc execute_div_16_8
    lda Reg::zwAX
    sta Reg::zwD0X
    lda Reg::zwAX+1
    sta Reg::zwD0X+1

    jsr Alu::div_16_8
    bcc success
    lda #Interrupt::DIVIDE_ERROR
    jmp Interrupt::int
success:

    lda Reg::zbS1L
    sta Reg::zbAL
    lda Reg::zbD0L
    sta Reg::zbAH
    rts
.endproc

.proc execute_idiv_32_16
    lda Reg::zwAX
    sta Reg::zwD0X
    lda Reg::zwAX+1
    sta Reg::zwD0X+1

    lda Reg::zwDX
    sta Reg::zwD1X
    lda Reg::zwDX+1
    sta Reg::zwD1X+1

    jsr Alu::idiv_32_16
    bcc success
    lda #Interrupt::DIVIDE_ERROR
    jmp Interrupt::int
success:

    lda Reg::zwS1X
    sta Reg::zwAX
    lda Reg::zwS1X+1
    sta Reg::zwAX+1

    lda Reg::zwD0X
    sta Reg::zwDX
    lda Reg::zwD0X+1
    sta Reg::zwDX+1
    rts
.endproc

.proc execute_idiv_16_8
    lda Reg::zwAX
    sta Reg::zwD0X
    lda Reg::zwAX+1
    sta Reg::zwD0X+1

    jsr Alu::idiv_16_8
    bcc success
    lda #Interrupt::DIVIDE_ERROR
    jmp Interrupt::int
success:

    lda Reg::zbS1L
    sta Reg::zbAL
    lda Reg::zbD0L
    sta Reg::zbAH
    rts
.endproc


; ASCII adjust before division
; Adjusts two unpacked BCD digits so that a division will yield a correct unpacked BCD value.
; TODO: optimize away copying fixed registers.
; < S0L = AL
; < S1L = AH
; < S2L = imm8
; > D0X = AX
; flags: SF, ZF, PF
.proc execute_aad
    lda Reg::zbS1L
    sta Mmc5::MULT_LO
    lda Reg::zbS2L
    sta Mmc5::MULT_HI

    clc
    lda Mmc5::MULT_LO
    adc Reg::zbS0L
    sta Reg::zwS0X
    lda #0
    sta Reg::zwS0X+1

    jsr calc_sign_flag_8
    jsr calc_zero_flag_8
    jmp calc_parity_flag
    ; [tail_jump]
.endproc


; convert byte to word.
; sign extend a signed 8-bit int to a signed 16-bit int.
; < S0L = byte to sign extend to a word
; > D0X = sign extended word
.proc execute_cbw
    lda Reg::zbS0L
    sta Reg::zbD0L
    jsr Util::get_extend_sign
    sta Reg::zbD0H
    rts
.endproc


; convert word to double word.
; sign extend a signed 16-bit int to a signed 32-bit int.
; < S0X = word to sign extend to a double word
; > D0X = low word of the double word
; > D1X = high word of the double word
.proc execute_cwd
    lda Reg::zwS0X
    sta Reg::zwD0X
    lda Reg::zwS0X+1
    sta Reg::zwD0X+1
    jsr Util::get_extend_sign
    sta Reg::zwD1X
    sta Reg::zwD1X+1
    rts
.endproc

; ----------------------------------------
; logic handlers
; ----------------------------------------

; 16-bit one's complement negation.
; < S0X
; > D0X
.proc execute_not_16
    jmp Alu::not_16
    ; [tail_jump]
.endproc


; 8-bit one's complement negation.
; < S0L
; > D0L
.proc execute_not_8
    jmp Alu::not_8
    ; [tail_jump]
.endproc


; 16-bit logical shift left.
; < S0X = value to shift
; < S1L = number of bits to shift
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_shl_16_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::shl_16_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit logical shift left.
; < S0L = value to shift
; < S1L = number of bits to shift
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_shl_8_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::shl_8_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit logical shift right.
; < S0X = value to shift
; < S1L = number of bits to shift
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_shr_16_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::shr_16_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit logical shift right.
; < S0L = value to shift
; < S1L = number of bits to shift
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_shr_8_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::shr_8_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit arithmetic shift right.
; < S0X = value to shift
; < S1L = number of bits to shift
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_sar_16_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::sar_16_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit arithmetic shift right.
; < S0L = value to shift
; < S1L = number of bits to shift
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_sar_8_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::sar_8_8
    jsr store_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit rotate left.
; < S0X = value to rotate
; < S1L = number of times to rotate
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rol_16_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::rol_16_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit rotate left.
; < S0L = value to rotate
; < S1L = number of times to rotate
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rol_8_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::rol_8_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit rotate right.
; < S0X = value to rotate
; < S1L = number of times to rotate
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_ror_16_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::ror_16_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit rotate right.
; < S0L = value to rotate
; < S1L = number of times to rotate
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_ror_8_8
    jsr load_carry_flag ; this is needed in case S1L == 0
    jsr Alu::ror_8_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit rotate left through CF.
; < S0X = value to rotate
; < S1L = number of times to rotate
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rcl_16_8
    jsr load_carry_flag
    jsr Alu::rcl_16_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit rotate left through CF.
; < S0L = value to rotate
; < S1L = number of times to rotate
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rcl_8_8
    jsr load_carry_flag
    jsr Alu::rcl_8_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit rotate right through CF.
; < S0X = value to rotate
; < S1L = number of times to rotate
; > D0X = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rcr_16_8
    jsr load_carry_flag
    jsr Alu::rcr_16_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_16
    ; [tail_jump]
.endproc


; 8-bit rotate right through CF.
; < S0L = value to rotate
; < S1L = number of times to rotate
; > D0L = result
; flags: CF, PF, ZF, SF, OF
.proc execute_rcr_8_8
    jsr load_carry_flag
    jsr Alu::rcr_8_8
    jsr store_carry_flag
    jmp calc_overflow_flag_shift_8
    ; [tail_jump]
.endproc


; 16-bit bitwise and.
; < S0X
; < S1X
; > D0X
; flags: CF, PF, ZF, SF, OF
.proc execute_and_16_16
    jsr Alu::and_16_16
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc


; 8-bit bitwise and.
; < S0L
; < S1L
; > D0L
; flags: CF, PF, ZF, SF, OF
.proc execute_and_8_8
    jsr Alu::and_8_8
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc


; 16-bit bitwise inclusive or.
; < S0X
; < S1X
; > D0X
; flags: CF, PF, ZF, SF, OF
.proc execute_or_16_16
    jsr Alu::or_16_16
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc


; 8-bit bitwise inclusive or.
; < S0L
; < S1L
; > D0L
; flags: CF, PF, ZF, SF, OF
.proc execute_or_8_8
    jsr Alu::or_8_8
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc


; 16-bit bitwise exclusive or.
; < S0X
; < S1X
; > D0X
; flags: CF, PF, ZF, SF, OF
.proc execute_xor_16_16
    jsr Alu::xor_16_16
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_16
    jsr calc_sign_flag_16
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc


; 8-bit bitwise exclusive or.
; < S0L
; < S1L
; > D0L
; flags: CF, PF, ZF, SF, OF
.proc execute_xor_8_8
    jsr Alu::xor_8_8
    jsr clear_carry_flag
    jsr calc_parity_flag
    jsr calc_zero_flag_8
    jsr calc_sign_flag_8
    jmp clear_overflow_flag
    ; [tail_jump]
.endproc

; ----------------------------------------
; string manipulation handlers
; ----------------------------------------

; NOTE: all string instructions are handled by existing data transfer
;       and arithmetic handlers.

; ----------------------------------------
; control transfer handlers
; ----------------------------------------

; NOTE: conditional jumps need to directly modify IP because of MMU optimizations.
;       unconditional jumps, calls, returns, etc will do the same for consistency.
;       they may also directly modify CS for simplicity.

.proc execute_call_far
    ldx #Reg::zwSS
    jsr Mem::use_segment

    ; push CS
    lda Reg::zwCS
    ldx Reg::zwCS+1
    jsr Mem::push_word

    ; push IP
    lda Reg::zwIP
    ldx Reg::zwIP+1
    jsr Mem::push_word
    ; [fall_through]
.endproc

; absolute address with segment
.proc execute_jmp_far
    ; CS = S1X
    lda Reg::zwS1X
    sta Reg::zwCS
    lda Reg::zwS1X+1
    sta Reg::zwCS+1
    ; [fall_through]
.endproc

.proc execute_jmp_abs_near
    ; IP = S0X
    lda Reg::zwS0X
    sta Reg::zwIP
    lda Reg::zwS0X+1
    sta Reg::zwIP+1
    rts
.endproc


.proc execute_call_abs_near
    ldx #Reg::zwSS
    jsr Mem::use_segment

    ; push IP
    lda Reg::zwIP
    ldx Reg::zwIP+1
    jsr Mem::push_word
    ; [fall_through]

    ; IP = S0X
    lda Reg::zwS0X
    sta Reg::zwIP
    lda Reg::zwS0X+1
    sta Reg::zwIP+1
    rts
.endproc


.proc execute_call_rel_near
    ldx #Reg::zwSS
    jsr Mem::use_segment

    ; S1X = IP
    ; push IP
    lda Reg::zwIP
    sta Reg::zwS1X
    ldx Reg::zwIP+1
    stx Reg::zwS1X+1
    jsr Mem::push_word

    ; TODO: abstract this into a function for use by near CALL and near JMP
    ; IP += offset
    jsr Alu::add_16_16
    lda Reg::zwD0X
    sta Reg::zwIP
    lda Reg::zwD0X+1
    sta Reg::zwIP+1
    rts
.endproc


.proc execute_ret_far
    jsr execute_ret_near

    jsr Mem::pop_word
    sta Reg::zwCS
    stx Reg::zwCS+1
    rts
.endproc

.proc execute_ret_near
    ldx #Reg::zwSS
    jsr Mem::use_segment

    jsr Mem::pop_word
    sta Reg::zwIP
    stx Reg::zwIP+1
    rts
.endproc

.proc execute_ret_far_adjust_sp
    jsr execute_ret_far

    ; TODO: abstract this into a new function.
    lda Reg::zwSP
    sta Reg::zwS1X
    lda Reg::zwSP+1
    sta Reg::zwS1X+1

    jsr Alu::add_16_16

    lda Reg::zwD0X
    sta Reg::zwSP
    lda Reg::zwD0X+1
    sta Reg::zwSP+1
    rts
.endproc

.proc execute_ret_near_adjust_sp
    jsr execute_ret_near

    lda Reg::zwSP
    sta Reg::zwS1X
    lda Reg::zwSP+1
    sta Reg::zwS1X+1

    jsr Alu::add_16_16

    lda Reg::zwD0X
    sta Reg::zwSP
    lda Reg::zwD0X+1
    sta Reg::zwSP+1
    rts
.endproc


; SF and OF exist in different bytes of the Flags register.
; conveniently, they don't collide with anything when OR'd together.
; this could cause problems if invalid flags are set somehow.
;             MSB        LSB
; Flags Low:     SZ-A-P-C
; Flags High:    ----ODIT
; Flags OR:      SZ-AO?I?
SF_OF_MASK = <Reg::FLAG_SF | >Reg::FLAG_OF
ZF_CF_MASK = <Reg::FLAG_ZF | <Reg::FLAG_CF
SF_ZF_OF_MASK = <Reg::FLAG_SF | <Reg::FLAG_ZF | >Reg::FLAG_OF

; i hate that x86 has multiple mnemonics for the same instruction.

; jump if zero (JZ)
; jump if equal (JE)
.proc execute_jz
    jsr get_zero_flag
    bne execute_jmp_short ; branch if the zero flag is set
    rts
.endproc



; jump if less (JL)
; jump if not greater or equal (JNGE)
; jump if (SF ^ OF) == 1
.proc execute_jl
    lda Reg::zbFlagsLo
    ora Reg::zbFlagsHi
    and #SF_OF_MASK
    beq no_jump ; branch if neither flag is set
    eor #SF_OF_MASK
    bne execute_jmp_short ; branch if only 1 flag was set
no_jump:
    rts
.endproc


; jump if not greater (JNG)
; jump if less or equal (JLE)
; jump if ((SF ^ OF) | ZF) == 1
.proc execute_jng
    lda Reg::zbFlagsLo
    ora Reg::zbFlagsHi
    and #SF_ZF_OF_MASK
    beq no_jump ; branch if all flags are cleared
    eor #SF_OF_MASK
    bne execute_jmp_short
    ; fall through if only SF and OF are both set
no_jump:
    rts
.endproc


; jump if below (JB)
; jump if not above nor equal (JNAE)
; jump if carry (JC)
.proc execute_jb
    jsr get_carry_flag
    bne execute_jmp_short ; branch if the carry flag is set
    rts
.endproc

; jump if not above (JNA)
; jump if below or equal (JBE)
; jump if (ZF | CF) == 1
.proc execute_jna
    lda Reg::zbFlagsLo
    and #ZF_CF_MASK
    bne execute_jmp_short ; branch if either flag is set
    rts
.endproc


; jump if parity (JP)
; jump if parity even (JPE)
.proc execute_jpe
    jsr get_parity_flag
    bne execute_jmp_short ; branch if the parity flag is set
    rts
.endproc

; jump if overflow (JO)
.proc execute_jo
    jsr get_overflow_flag
    bne execute_jmp_short ; branch if the overflow flag is set
    rts
.endproc


; jump if sign (JS)
.proc execute_js
    jsr get_sign_flag
    bne execute_jmp_short ; branch if the sign flag is set
    rts
.endproc


; 1 byte offset
; called by conditional jumps
.proc execute_jmp_short
    lda Reg::zbS0L
    jsr Util::get_extend_sign
    sta Reg::zbS0H
    ; [fall_through]
.endproc

; 2 byte offset
.proc execute_jmp_rel_near
    lda Reg::zwIP
    sta Reg::zwS1X
    lda Reg::zwIP+1
    sta Reg::zwS1X+1

    jsr Alu::add_16_16
    lda Reg::zwD0X
    sta Reg::zwIP
    lda Reg::zwD0X+1
    sta Reg::zwIP+1
    rts
.endproc


; jump if not zero (JNZ)
; jump if not equal (JNE)
.proc execute_jnz
    jsr get_zero_flag
    beq execute_jmp_short ; branch if the zero flag is cleared
    rts
.endproc


; jump if not less (JNL)
; jump if greater or equal (JGE)
; jump if (SF ^ OF) == 0
.proc execute_jnl
    lda Reg::zbFlagsLo
    ora Reg::zbFlagsHi
    and #SF_OF_MASK
    beq execute_jmp_short ; branch if neither flag is set
    eor #SF_OF_MASK
    beq execute_jmp_short ; branch if both flags were set
    rts
.endproc


; jump if greater (JG)
; jump if not less not equal (JNLE)
; jump if ((SF ^ OF) | ZF) == 0
.proc execute_jg
    lda Reg::zbFlagsLo
    ora Reg::zbFlagsHi
    and #SF_ZF_OF_MASK
    beq execute_jmp_short ; branch if all flags are cleared
    eor #SF_OF_MASK
    beq execute_jmp_short ; branch if only SF and OF are both set
    rts
.endproc

; jump if above or equal (JAE)
; jump if not below (JNB)
; jump if not carry (JNC)
.proc execute_jae
    jsr get_carry_flag
    beq execute_jmp_short ; branch if the carry flag is cleared
    rts
.endproc

; jump if above (JA)
; jump if not below nor equal (JNBE)
; jump if (ZF | CF) == 0
.proc execute_ja
    lda Reg::zbFlagsLo
    and #ZF_CF_MASK
    beq execute_jmp_short ; branch if neither flag is set
    rts
.endproc

; jump if not parity (JNP)
; jump if parity odd (JPO)
.proc execute_jpo
    jsr get_parity_flag
    beq execute_jmp_short ; branch if the parity flag is cleared
    rts
.endproc

; jump if not overflow (JNO)
.proc execute_jno
    jsr get_overflow_flag
    beq execute_jmp_short ; branch if the overflow flag is cleared
    rts
.endproc

; jump if not sign (JNS)
.proc execute_jns
    jsr get_sign_flag
    beq execute_jmp_short ; branch if the sign flag is cleared
    rts
.endproc


; NOTE: rep/repz/repnz need to decrement CX in the execute stage.
;       we'll re-use that code with loop/loopz/loopnz for consistency.

; decrement CX
; jump if CX is not 0
.proc execute_loop
    jsr decrement_cx
    bne execute_jmp_short ; branch if CX != 0
    rts
.endproc

; decrement CX
; jump if CX is not 0 and ZF is set
.proc execute_loopz
    jsr decrement_cx
    beq done ; branch if CX == 0

    jsr get_zero_flag
    bne execute_jmp_short ; branch if ZF == 1

done:
    rts
.endproc


; decrement CX
; jump if CX is not 0 and ZF is cleared
.proc execute_loopnz
    jsr decrement_cx
    beq done ; branch if CX == 0

    jsr get_zero_flag
    beq execute_jmp_short ; branch if ZF == 0

done:
    rts
.endproc


; jump if CX is 0
.proc execute_jcxz
    lda Reg::zwCX
    ora Reg::zwCX+1
    beq execute_jmp_short ; branch if CX == 0
    rts
.endproc


.proc execute_int
    lda Reg::zbS0L
    jmp Interrupt::int
    ; [tail_jump]
.endproc


.proc execute_int3
    lda #Interrupt::BREAKPOINT
    jmp Interrupt::int
    ; [tail_jump]
.endproc


.proc execute_into
    lda #Interrupt::OVERFLOW
    jmp Interrupt::int
    ; [tail_jump]
.endproc

; TODO: call Interrupt::iret directly
.proc execute_iret
    jmp Interrupt::iret
    ; [tail_jump]
.endproc

; ----------------------------------------
; processor control handlers
; ----------------------------------------

; TODO: move flag logic here to avoid jumps

.proc execute_clc
    jmp clear_carry_flag
    ; [tail_jump]
.endproc

.proc execute_cmc
    jsr get_carry_flag
    eor #<Reg::FLAG_CF
    jmp Reg::set_flag_lo
    ; [tail_jump]
.endproc

.proc execute_stc
    jmp set_carry_flag
    ; [tail_jump]
.endproc

.proc execute_cld
    jmp clear_direction_flag
    ; [tail_jump]
.endproc

.proc execute_std
    jmp set_direction_flag
    ; [tail_jump]
.endproc

.proc execute_cli
    jmp clear_interrupt_flag
    ; [tail_jump]
.endproc

.proc execute_sti
    jsr set_interrupt_flag
    jmp Interrupt::skip
    ; [tail_jump]
.endproc

; halt the processor until an interrupt or reset brings us out of the halt state.
; in the halt state, the fetch, decode, execute, and write stages will be bypassed.
.proc execute_hlt
    lda #1
    sta X86::zbHalt
    rts
.endproc

; WAIT causes the CPU to enter the wait state while the /TEST line is not active.
; i don't think we need to emulate this behavior for anything.
; we'll just return immediately as if the /TEST line is active.
.proc execute_wait
    rts
.endproc

; ESC provides a way to send instructions to an external co-processor,
; such as a floating point unit (FPU). we don't have any such co-processor.
; only the "fetch" stage will be implemented for the ESC instruction.
; all other stages will perform the same actions as NOP.
; that should be good enough to keep us from crashing if we encounter an ESC.
.proc execute_esc
    rts
.endproc

; ----------------------------------------
; other handlers
; ----------------------------------------

; no operation
.proc execute_nop
    rts
.endproc


.proc execute_bad
    lda #X86::Err::EXECUTE_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc

; ==============================================================================
; utility functions
; ==============================================================================

; extend the sign bit of S1L to fill S1X.
; < S1L
; > S1X
; changes: A
.proc extend_sign_s1l_s1x
    lda Reg::zbS1L
    jsr Util::get_extend_sign
    sta Reg::zwS1X+1
    rts
.endproc

; decrement CX and then check if it is zero.
; > Z = 1 if CX == 0
;   Z = 0 if CX != 0
.proc decrement_cx
    sec
    lda Reg::zwCX
    sbc #1
    sta Reg::zwCX
    lda Reg::zwCX+1
    sbc #0
    sta Reg::zwCX+1
    ora Reg::zwCX
    rts
.endproc

; ----------------------------------------
; flag functions
; ----------------------------------------

; TODO: optimize away unnecessary jumps/branches

; set C to the value of CF
; > C
; changes: A
.proc load_carry_flag
    lda Reg::zbFlagsLo
    lsr
    rts
.endproc


; set CF to the value of C
; < C
; changes: A
.proc store_carry_flag
    bcc clear_carry_flag
    ; [tail_branch]
.endproc

; set the carry flag (CF) to 1
; changes: A
.proc set_carry_flag
    lda #<Reg::FLAG_CF
    jmp Reg::set_flag_lo
.endproc


; set C to the value of ~CF
; > C
; changes: A
.proc load_not_carry_flag
    lda Reg::zbFlagsLo
    eor #<Reg::FLAG_CF
    lsr
    rts
.endproc


; set CF to the value of ~C
; < C
; changes: A
.proc store_not_carry_flag
    bcc set_carry_flag
    ; [tail_branch]
.endproc

; set the carry flag (CF) to 0
; changes: A
.proc clear_carry_flag
    lda #<(~Reg::FLAG_CF)
    jmp Reg::clear_flag_lo
.endproc


; calculate the new state of the parity flag (PF) based on the 8-bit value in D0L.
; PF is set if the number of set bits is even.
; otherwise, PF is cleared.
; changes: A, X
.proc calc_parity_flag
    ; count the number of set bits
    ldx #0
    lda Reg::zbD0L

loop:
    beq loop_end
loop_shift:
    lsr a
    bcc loop
    inx
    cmp #0
    bne loop_shift
loop_end:

    ; check if the number of set bits is odd or even
    txa
    lsr

    bcs clear_parity_flag ; branch if bit count is odd)
    ; [tail_branch]
.endproc

; set the parity flag (PF) to 1
; changes: A
.proc set_parity_flag
    lda #<Reg::FLAG_PF
    jmp Reg::set_flag_lo
.endproc


; set the parity flag (PF) to 0
; changes: A
.proc clear_parity_flag
    lda #<(~Reg::FLAG_PF)
    jmp Reg::clear_flag_lo
.endproc


; calculate the new state of the auxiliary carry flag (AF) based on (S0L ^ S1L ^ D0L) & (1 << 4)
; AF is set if 4-bit addition or subtraction resulted in a carry or borrow respectively.
; otherwise, AF is cleared.
; changes: A
.proc calc_auxiliary_flag
    ; calculate auxiliary carry
    lda Reg::zbD0L
    eor Reg::zbS0L
    eor Reg::zbS1L
    and #%00010000 ; isolate the auxiliary carry bit
    beq clear_auxiliary_flag ; branch if carry/borrow didn't occur
    ; [tail_branch]
.endproc

; set the auxiliary flag (AF) to 1
; changes: A
.proc set_auxiliary_flag
    lda #<Reg::FLAG_AF
    jmp Reg::set_flag_lo
.endproc


; set the auxiliary flag (AF) to 0
; changes: A
.proc clear_auxiliary_flag
    lda #<(~Reg::FLAG_AF)
    jmp Reg::clear_flag_lo
.endproc


; get the auxiliary flag (AF)
; > A = AF
.proc get_auxiliary_flag
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_AF
    rts
.endproc


; calculate the new state of the zero flag (ZF) based on the 8-bit value in D0L.
; ZF is set if D0L is zero. otherwise, ZF is cleared.
; changes: A
.proc calc_zero_flag_8
    lda Reg::zbD0L
    bne clear_zero_flag ; branch if 8-bit result is not zero
    ; [tail_branch]
.endproc

; set the zero flag (ZF) to 1
; changes: A
.proc set_zero_flag
    lda #<Reg::FLAG_ZF
    jmp Reg::set_flag_lo
.endproc


; calculate the new state of the zero flag (ZF) based on the 16-bit value in D0X.
; ZF is set if D0X is zero. otherwise, ZF is cleared.
; changes: A
.proc calc_zero_flag_16
    lda Reg::zwD0X
    ora Reg::zwD0X+1
    beq set_zero_flag ; branch if 16-bit result is zero
    ; [tail_branch]
.endproc

; set the zero flag (ZF) to 0
; changes: A
.proc clear_zero_flag
    lda #<(~Reg::FLAG_ZF)
    jmp Reg::clear_flag_lo
.endproc


; calculate the new state of the sign flag (SF) based on the 8-bit value in D0L.
; SF is set if D0L is negative. otherwise, SF is cleared.
; changes: A
.proc calc_sign_flag_8
    lda Reg::zbD0L
    bpl clear_sign_flag
    ; [tail_branch]
.endproc

; set the sign flag (SF) to 1
; changes: A
.proc set_sign_flag
    lda #<Reg::FLAG_SF
    jmp Reg::set_flag_lo
.endproc


; calculate the new state of the sign flag (SF) based on the 16-bit value in D0X.
; SF is set if D0X is negative. otherwise, SF is cleared.
; changes: A
.proc calc_sign_flag_16
    lda Reg::zwD0X+1
    bmi set_sign_flag
    ; [tail_branch]
.endproc

; set the sign flag (SF) to 0
; changes: A
.proc clear_sign_flag
    lda #<(~Reg::FLAG_SF)
    jmp Reg::clear_flag_lo
.endproc


; calculate the new state of the overflow flag (OF) after 8-bit negation.
; this is the same as setting OF after subtraction but operand 0 is assumed to be 0.
; OF is set if 0 == S0L.7 and 1 == D0L.7.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_neg_8
    lda Reg::zbS0L
    bpl clear_overflow_flag
    lda Reg::zbD0L
    bmi set_overflow_flag
    bpl clear_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 16-bit negation.
; this is the same as setting OF after subtraction but operand 0 is assumed to be 0.
; OF is set if 0 == S0L.15 and 1 == D0L.15.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_neg_16
    lda Reg::zwS0X+1
    bpl clear_overflow_flag
    lda Reg::zwD0X+1
    bmi set_overflow_flag
    bpl clear_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 8-bit increment.
; this is the same as setting OF after addition but operand 1 is assumed to be 1.
; OF is set if 0 == S0L.7 and 1 == D0L.7.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_inc_8
    lda Reg::zbS0L
    bmi clear_overflow_flag
    lda Reg::zbD0L
    bpl clear_overflow_flag
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 16-bit increment.
; this is the same as setting OF after addition but operand 1 is assumed to be 1.
; OF is set if 0 == S0X.15 and 1 == D0X.15.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_inc_16
    lda Reg::zwS0X+1
    bmi clear_overflow_flag
    lda Reg::zwD0X+1
    bpl clear_overflow_flag
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 8-bit subtraction.
; this is the same as setting OF after subtraction but operand 1 is assumed to be 1.
; OF is set if 1 == S0L.7 and 1 == D0L.7.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_dec_8
    lda Reg::zbS0L
    bpl clear_overflow_flag
    lda Reg::zbD0L
    bpl clear_overflow_flag
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 16-bit subtraction.
; this is the same as setting OF after subtraction but operand 1 is assumed to be 1.
; OF is set if 1 == S0L.15 and 1 == D0L.15.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_dec_16
    lda Reg::zwS0X+1
    bpl clear_overflow_flag
    lda Reg::zwD0X+1
    bmi set_overflow_flag
    bpl clear_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 8-bit addition.
; OF is set if S0L.7 == S1L.7 and S0L.7 != D0L.7.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_add_8
    lda Reg::zbS0L
    eor Reg::zbS1L
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zbS0L
    eor Reg::zbD0L
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 16-bit addition.
; OF is set if S0L.15 == S1L.15 and S0L.15 != D0L.15.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_add_16
    lda Reg::zwS0X+1
    eor Reg::zwS1X+1
    bmi clear_overflow_flag ; branch if source registers have different signs
    lda Reg::zwS0X+1
    eor Reg::zwD0X+1
    bpl clear_overflow_flag ; branch if sources and destination have the same sign
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 8-bit subtraction.
; OF is set if S0L.7 != S1L.7 and S0L.7 != D0L.7.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_sub_8
    lda Reg::zbS0L
    eor Reg::zbS1L
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zbS0L
    eor Reg::zbD0L
    bpl clear_overflow_flag ; branch if source 0 and destination have the same sign
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after 16-bit subtraction.
; OF is set if S0L.15 != S1L.15 and S0L.15 != D0L.15.
; otherwise, OF is cleared.
; changes: A
.proc calc_overflow_flag_sub_16
    lda Reg::zwS0X+1
    eor Reg::zwS1X+1
    bpl clear_overflow_flag ; branch if source registers have the same signs
    lda Reg::zwS0X+1
    eor Reg::zwD0X+1
    bpl clear_overflow_flag ; branch if source 0 and destination have the same sign
    ; bmi set_overflow_flag
    ; [tail_branch]
.endproc

; set the overflow flag (OF) to 1
; changes: A
.proc set_overflow_flag
    lda #>Reg::FLAG_OF
    jmp Reg::set_flag_hi
.endproc


; calculate the new state of the overflow flag (OF) after unsigned 8-bit multiplication.
; OF is set if D0H != 0.
; otherwise, OF is cleared.
; > C = new state of OF
; changes: A
.proc calc_overflow_flag_mul_8
    lda Reg::zbD0H
    ; set C if D0H is non-zero. clear C otherwise
    ; the caller will need to set CF = OF so this saves them a few cycles.
    cmp #1
    bcs set_overflow_flag
    ; bcc clear_overflow_flag
    ; [tail_branch]
.endproc

; set the overflow flag (OF) to 0
; changes: A
.proc clear_overflow_flag
    lda #>(~Reg::FLAG_OF)
    jmp Reg::clear_flag_hi
.endproc


; calculate the new state of the overflow flag (OF) after unsigned 16-bit multiplication.
; OF is set if D1X != 0.
; otherwise, OF is cleared.
; > C = new state of OF
; changes: A
.proc calc_overflow_flag_mul_16
    lda Reg::zwD1X
    ora Reg::zwD1X+1
    ; set C if D0H is non-zero. clear C otherwise
    ; the caller will need to set CF = OF so this saves them a few cycles.
    cmp #1
    bcc clear_overflow_flag
    bcs set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after signed 8-bit multiplication.
; OF is set if all bits of D0H == D0L.7
; otherwise, OF is cleared.
; > C = new state of OF
; changes: A
.proc calc_overflow_flag_imul_8
    lda Reg::zbD0L
    jsr Util::get_extend_sign
    eor Reg::zbD0H
    cmp #1
    bcs set_overflow_flag
    bcc clear_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after signed 16-bit multiplication.
; OF is set if all bits of D1X == D0X.15
; otherwise, OF is cleared.
; > C = new state of OF
; changes: A
.proc calc_overflow_flag_imul_16
    lda Reg::zwD0X+1
    jsr Util::get_extend_sign
    eor Reg::zwD1X
    cmp #1

    bcs set_overflow_flag

    lda Reg::zwD1X
    eor Reg::zwD1X+1
    cmp #1

    bcs set_overflow_flag
    bcc clear_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after a 16-bit shift.
; OF is set if the sign bit changed.
; otherwise, OF is cleared.
.proc calc_overflow_flag_shift_8
    lda Reg::zbS0L
    eor Reg::zbD0L
    bpl clear_overflow_flag
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; calculate the new state of the overflow flag (OF) after a 16-bit shift.
; OF is set if the sign bit changed.
; otherwise, OF is cleared.
.proc calc_overflow_flag_shift_16
    lda Reg::zwS0X+1
    eor Reg::zwD0X+1
    bpl clear_overflow_flag
    bmi set_overflow_flag
    ; [tail_branch]
.endproc


; set the trap flag (TF) to 1
; changes: A
.proc set_trap_flag
    lda #>Reg::FLAG_TF
    jmp Reg::set_flag_hi
.endproc


; set the trap flag (TF) to 0
; changes: A
.proc clear_trap_flag
    lda #>(~Reg::FLAG_TF)
    jmp Reg::clear_flag_hi
.endproc


; set the interrupt flag (IF) to 1
; changes: A
.proc set_interrupt_flag
    lda #>Reg::FLAG_IF
    jmp Reg::set_flag_hi
.endproc


; set the interrupt flag (IF) to 0
; changes: A
.proc clear_interrupt_flag
    lda #>(~Reg::FLAG_IF)
    jmp Reg::clear_flag_hi
.endproc


; set the direction flag (DF) to 1
; changes: A
.proc set_direction_flag
    lda #>Reg::FLAG_DF
    jmp Reg::set_flag_hi
.endproc


; set the direction flag (DF) to 0
; changes: A
.proc clear_direction_flag
    lda #>(~Reg::FLAG_DF)
    jmp Reg::clear_flag_hi
.endproc


; get the carry flag (CF)
; > A
.proc get_carry_flag
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_CF
    rts
.endproc


; get the parity flag (PF)
; > A
.proc get_parity_flag
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_PF
    rts
.endproc


; get the zero flag (ZF)
; > A
.proc get_zero_flag
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_ZF
    rts
.endproc


; get the sign flag (SF)
; > A
.proc get_sign_flag
    lda Reg::zbFlagsLo
    and #<Reg::FLAG_SF
    rts
.endproc


; get the trap flag (TF)
; > A
.proc get_trap_flag
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_TF
    rts
.endproc


; get the interrupt flag (IF)
; > A
.proc get_interrupt_flag
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_IF
    rts
.endproc


; get the direction flag (DF)
; > A
.proc get_direction_flag
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_DF
    rts
.endproc


; get the overflow flag (OF)
; > A
.proc get_overflow_flag
    lda Reg::zbFlagsHi
    and #>Reg::FLAG_OF
    rts
.endproc
