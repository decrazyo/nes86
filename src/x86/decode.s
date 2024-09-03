
; This module is responsible for copying values needed by x86 instructions
; into temporary pseudo-registers.
; This module must only read the x86 address space though the
; Mem's general-purpose memory interface and dedicated stack interface.
; This module must not write to the x86 address space at all.
; This module may only move data and must not transform it in any other way.
; If an instruction's opcode indicates that it simply moves a value to or from a fixed
; location, i.e. a specific register or the stack, then reading that
; value may be deferred until the "write" stage.
; e.g. decoding "CALL 0x1234:0x5678" may defer reading "CS" to the "write" stage
; since the opcode of the instruction (0x9A) always requires "CS" to be
; pushed onto the stack and "CS" is not needed by the "execute" stage.
; If an instruction will write to the x86 address space during the "write" stage
; then this module must configure the Mem appropriately for that write.

.linecont +

.include "const.inc"
.include "list.inc"
.include "tmp.inc"
.include "x86.inc"
.include "x86/decode.inc"
.include "x86/fetch.inc"
.include "x86/mem.inc"
.include "x86/opcode.inc"
.include "x86/reg.inc"
.include "x86/util.inc"

.exportzp zbMod

.exportzp zbExt
.exportzp zbSeg
.exportzp zbReg

.exportzp zbRM

.export decode

.segment "ZEROPAGE"

; ModR/M Mod field
; populated by the fetch stage
zbMod: .res 1

; ModR/M reg field and aliases
zbExt: ; opcode extension index
zbSeg: ; segment register index
zbReg: .res 1 ; register index

; ModR/M R/M field
zbRM: .res 1

.segment "RODATA"

.define DECODE_FUNCS \
decode_nothing, \
decode_s0l_modrm_reg8_d0l_modrm_rm8, \
decode_s0x_modrm_reg16_d0x_modrm_rm16, \
decode_s0l_modrm_rm8_d0l_modrm_reg8, \
decode_s0x_modrm_rm16_d0x_modrm_reg16, \
decode_s0l_imm8_d0l_modrm_rm8, \
decode_s0x_imm16_d0x_modrm_rm16, \
decode_s0l_imm8_d0l_embed_reg8, \
decode_s0x_imm16_d0x_embed_reg16, \
decode_s0l_mem8_imm16, \
decode_s0x_mem16_imm16, \
decode_s0l_al_d0l_mem8, \
decode_s0x_ax_d0x_mem16, \
decode_s0x_modrm_seg16_d0x_modrm_rm16, \
decode_s0x_embed_reg16, \
decode_s0x_embed_seg16, \
decode_d0x_modrm_rm, \
decode_d0x_embed_reg16, \
decode_d0x_embed_seg16, \
decode_s0l_modrm_reg8_s1l_modrm_rm8, \
decode_s0x_modrm_reg16_s1x_modrm_rm16, \
decode_s0x_embed_reg16_s1x_ax, \
decode_s0x_imm8, \
decode_s0x_dx, \
decode_s0l_mem8_bx_al, \
decode_s0x_modrm_m_addr, \
decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi, \
decode_s0l_flags_lo, \
decode_s0l_ah, \
decode_s0x_flags, \
decode_s0l_modrm_rm8_s1l_modrm_reg8, \
decode_s0x_modrm_rm16_s1x_modrm_reg16, \
decode_s0l_al_s1l_imm8, \
decode_s0x_ax_s1x_imm16, \
decode_s0x_embed_reg16_d0x_embed_reg16, \
decode_s0x_ax, \
decode_s0l_al, \
decode_s0l_al_s1l_ah_s2l_imm8, \
decode_s0l_mem8_si, \
decode_s0x_mem16_si, \
decode_s0l_mem8_si_s1l_mem8_di, \
decode_s0x_mem16_si_s1x_mem16_di, \
decode_s0x_al_s1x_mem8_di, \
decode_s0x_ax_s1x_mem16_di, \
decode_s0l_imm8, \
decode_s0x_imm16, \
decode_s0x_imm16_s1x_imm16, \
decode_s0l_modrm_rm8_s1l_imm8, \
decode_s0x_modrm_rm16_s1x_imm16, \
decode_s0x_modrm_rm16_s1x_imm8, \
decode_s0l_modrm_rm8_s1l_1, \
decode_s0x_modrm_rm16_s1l_1, \
decode_s0l_modrm_rm8_s1l_cl, \
decode_s0x_modrm_rm16_s1l_cl, \
decode_s0l_modrm_rm8_opt_s1l_imm8, \
decode_s0x_modrm_rm16_opt_s1x_imm16, \
decode_s0l_modrm_rm8, \
decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi, \
decode_s0l_al_d0l_mem8_di, \
decode_s0x_ax_d0x_mem16_di, \
decode_s0l_mem8_si_d0l_mem8_di, \
decode_s0x_mem16_si_d0x_mem16_di, \
decode_s0x_imm8_s1l_al, \
decode_s0x_imm8_s1x_ax, \
decode_s0x_dx_s1l_al, \
decode_s0x_dx_s1x_ax, \
decode_error

; decode function jump table
rbaDecodeFuncLo:
lo_return_bytes {DECODE_FUNCS}
rbaDecodeFuncHi:
hi_return_bytes {DECODE_FUNCS}

; map opcodes to jump table indices
size .set 0
rbaDecodeFuncIndex:
index_byte_at size, Opcode::ADD_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::ADD_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::ADD_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::ADD_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::ADD_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::ADD_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::PUSH_ES,    {DECODE_FUNCS}, decode_s0x_embed_seg16
index_byte_at size, Opcode::POP_ES,     {DECODE_FUNCS}, decode_d0x_embed_seg16
index_byte_at size, Opcode::OR_Eb_Gb,   {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::OR_Ev_Gv,   {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::OR_Gb_Eb,   {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::OR_Gv_Ev,   {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::OR_AL_Ib,   {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::OR_AX_Iv,   {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::PUSH_CS,    {DECODE_FUNCS}, decode_s0x_embed_seg16
index_byte_at size, Opcode::NONE_0Fh,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::ADC_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::ADC_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::ADC_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::ADC_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::ADC_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::ADC_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::PUSH_SS,    {DECODE_FUNCS}, decode_s0x_embed_seg16
index_byte_at size, Opcode::POP_SS,     {DECODE_FUNCS}, decode_d0x_embed_seg16
index_byte_at size, Opcode::SBB_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::SBB_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::SBB_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::SBB_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::SBB_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::SBB_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::PUSH_DS,    {DECODE_FUNCS}, decode_s0x_embed_seg16
index_byte_at size, Opcode::POP_DS,     {DECODE_FUNCS}, decode_d0x_embed_seg16
index_byte_at size, Opcode::AND_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::AND_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::AND_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::AND_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::AND_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::AND_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::ES,         {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::DAA,        {DECODE_FUNCS}, decode_s0l_al
index_byte_at size, Opcode::SUB_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::SUB_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::SUB_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::SUB_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::SUB_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::SUB_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::CS,         {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::DAS,        {DECODE_FUNCS}, decode_s0l_al
index_byte_at size, Opcode::XOR_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::XOR_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::XOR_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::XOR_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::XOR_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::XOR_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::SS,         {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::AAA,        {DECODE_FUNCS}, decode_s0x_ax
index_byte_at size, Opcode::CMP_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_modrm_reg8
index_byte_at size, Opcode::CMP_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_modrm_reg16
index_byte_at size, Opcode::CMP_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::CMP_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::CMP_AL_Ib,  {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::CMP_AX_Iv,  {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::DS,         {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::AAS,        {DECODE_FUNCS}, decode_s0x_ax
index_byte_at size, Opcode::INC_AX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_CX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_DX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_BX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_SP,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_BP,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_SI,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::INC_DI,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_AX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_CX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_DX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_BX,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_SP,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_BP,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_SI,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::DEC_DI,     {DECODE_FUNCS}, decode_s0x_embed_reg16_d0x_embed_reg16
index_byte_at size, Opcode::PUSH_AX,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_CX,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_DX,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_BX,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_SP,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_BP,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_SI,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::PUSH_DI,    {DECODE_FUNCS}, decode_s0x_embed_reg16
index_byte_at size, Opcode::POP_AX,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_CX,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_DX,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_BX,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_SP,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_BP,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_SI,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::POP_DI,     {DECODE_FUNCS}, decode_d0x_embed_reg16
index_byte_at size, Opcode::NONE_60h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_61h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_62h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_63h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_64h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_65h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_66h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_67h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_68h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_69h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Ah,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Bh,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Ch,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Dh,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Eh,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_6Fh,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::JO_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNO_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JB_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JAE_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JZ_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNZ_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNA_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JA_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JS_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNS_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JPE_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JPO_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JL_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNL_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JNG_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JG_Jb,      {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::GRP1_Eb_Ib, {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_imm8
index_byte_at size, Opcode::GRP1_Ev_Iv, {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_imm16
index_byte_at size, Opcode::GRP1_82h,   {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_imm8
index_byte_at size, Opcode::GRP1_Ev_Ib, {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1x_imm8
index_byte_at size, Opcode::TEST_Gb_Eb, {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::TEST_Gv_Ev, {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::XCHG_Gb_Eb, {DECODE_FUNCS}, decode_s0l_modrm_reg8_s1l_modrm_rm8
index_byte_at size, Opcode::XCHG_Gv_Ev, {DECODE_FUNCS}, decode_s0x_modrm_reg16_s1x_modrm_rm16
index_byte_at size, Opcode::MOV_Eb_Gb,  {DECODE_FUNCS}, decode_s0l_modrm_reg8_d0l_modrm_rm8
index_byte_at size, Opcode::MOV_Ev_Gv,  {DECODE_FUNCS}, decode_s0x_modrm_reg16_d0x_modrm_rm16
index_byte_at size, Opcode::MOV_Gb_Eb,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_d0l_modrm_reg8
index_byte_at size, Opcode::MOV_Gv_Ev,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_d0x_modrm_reg16
index_byte_at size, Opcode::MOV_Ew_Sw,  {DECODE_FUNCS}, decode_s0x_modrm_seg16_d0x_modrm_rm16
index_byte_at size, Opcode::LEA_Gv_M,   {DECODE_FUNCS}, decode_s0x_modrm_m_addr
index_byte_at size, Opcode::MOV_Sw_Ew,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_d0x_modrm_reg16
index_byte_at size, Opcode::POP_Ev,     {DECODE_FUNCS}, decode_d0x_modrm_rm
index_byte_at size, Opcode::NOP,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::XCHG_CX_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_DX_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_BX_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_SP_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_BP_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_SI_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::XCHG_DI_AX, {DECODE_FUNCS}, decode_s0x_embed_reg16_s1x_ax
index_byte_at size, Opcode::CBW,        {DECODE_FUNCS}, decode_s0l_al
index_byte_at size, Opcode::CWD,        {DECODE_FUNCS}, decode_s0x_ax
index_byte_at size, Opcode::CALL_Ap,    {DECODE_FUNCS}, decode_s0x_imm16_s1x_imm16
index_byte_at size, Opcode::WAIT,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::PUSHF,      {DECODE_FUNCS}, decode_s0x_flags
index_byte_at size, Opcode::POPF,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::SAHF,       {DECODE_FUNCS}, decode_s0l_ah
index_byte_at size, Opcode::LAHF,       {DECODE_FUNCS}, decode_s0l_flags_lo
index_byte_at size, Opcode::MOV_AL_Ob,  {DECODE_FUNCS}, decode_s0l_mem8_imm16
index_byte_at size, Opcode::MOV_AX_Ov,  {DECODE_FUNCS}, decode_s0x_mem16_imm16
index_byte_at size, Opcode::MOV_Ob_AL,  {DECODE_FUNCS}, decode_s0l_al_d0l_mem8
index_byte_at size, Opcode::MOV_Ov_AX,  {DECODE_FUNCS}, decode_s0x_ax_d0x_mem16
index_byte_at size, Opcode::MOVSB,      {DECODE_FUNCS}, decode_s0l_mem8_si_d0l_mem8_di
index_byte_at size, Opcode::MOVSW,      {DECODE_FUNCS}, decode_s0x_mem16_si_d0x_mem16_di
index_byte_at size, Opcode::CMPSB,      {DECODE_FUNCS}, decode_s0l_mem8_si_s1l_mem8_di
index_byte_at size, Opcode::CMPSW,      {DECODE_FUNCS}, decode_s0x_mem16_si_s1x_mem16_di
index_byte_at size, Opcode::TEST_AL_Ib, {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::TEST_AX_Iv, {DECODE_FUNCS}, decode_s0x_ax_s1x_imm16
index_byte_at size, Opcode::STOSB,      {DECODE_FUNCS}, decode_s0l_al_d0l_mem8_di
index_byte_at size, Opcode::STOSW,      {DECODE_FUNCS}, decode_s0x_ax_d0x_mem16_di
index_byte_at size, Opcode::LODSB,      {DECODE_FUNCS}, decode_s0l_mem8_si
index_byte_at size, Opcode::LODSW,      {DECODE_FUNCS}, decode_s0x_mem16_si
index_byte_at size, Opcode::SCASB,      {DECODE_FUNCS}, decode_s0x_al_s1x_mem8_di
index_byte_at size, Opcode::SCASW,      {DECODE_FUNCS}, decode_s0x_ax_s1x_mem16_di
index_byte_at size, Opcode::MOV_AL_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_CL_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_DL_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_BL_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_AH_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_CH_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_DH_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_BH_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_embed_reg8
index_byte_at size, Opcode::MOV_AX_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_CX_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_DX_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_BX_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_SP_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_BP_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_SI_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::MOV_DI_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_embed_reg16
index_byte_at size, Opcode::NONE_C0h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_C1h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::RET_Iw,     {DECODE_FUNCS}, decode_s0x_imm16
index_byte_at size, Opcode::RET,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::LES_Gv_Mp,  {DECODE_FUNCS}, decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi
index_byte_at size, Opcode::LDS_Gv_Mp,  {DECODE_FUNCS}, decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi
index_byte_at size, Opcode::MOV_Eb_Ib,  {DECODE_FUNCS}, decode_s0l_imm8_d0l_modrm_rm8
index_byte_at size, Opcode::MOV_Ev_Iv,  {DECODE_FUNCS}, decode_s0x_imm16_d0x_modrm_rm16
index_byte_at size, Opcode::NONE_C8h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_C9h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::RETF_Iw,    {DECODE_FUNCS}, decode_s0x_imm16
index_byte_at size, Opcode::RETF,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::INT3,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::INT_Ib,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::INTO,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::IRET,       {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::GRP2_Eb_1,  {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_1
index_byte_at size, Opcode::GRP2_Ev_1,  {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1l_1
index_byte_at size, Opcode::GRP2_Eb_CL, {DECODE_FUNCS}, decode_s0l_modrm_rm8_s1l_cl
index_byte_at size, Opcode::GRP2_Ev_CL, {DECODE_FUNCS}, decode_s0x_modrm_rm16_s1l_cl
index_byte_at size, Opcode::AAM_I0,     {DECODE_FUNCS}, decode_s0l_al_s1l_imm8
index_byte_at size, Opcode::AAD_I0,     {DECODE_FUNCS}, decode_s0l_al_s1l_ah_s2l_imm8
index_byte_at size, Opcode::NONE_D6h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::XLAT,       {DECODE_FUNCS}, decode_s0l_mem8_bx_al
index_byte_at size, Opcode::NONE_D8h,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_D9h,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DAh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DBh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DCh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DDh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DEh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::NONE_DFh,   {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::LOOPNZ_Jb,  {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::LOOPZ_Jb,   {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::LOOP_Jb,    {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::JCXZ_Jb,    {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::IN_AL_Ib,   {DECODE_FUNCS}, decode_s0x_imm8
index_byte_at size, Opcode::IN_AX_Ib,   {DECODE_FUNCS}, decode_s0x_imm8
index_byte_at size, Opcode::OUT_Ib_AL,  {DECODE_FUNCS}, decode_s0x_imm8_s1l_al
index_byte_at size, Opcode::OUT_Ib_AX,  {DECODE_FUNCS}, decode_s0x_imm8_s1x_ax
index_byte_at size, Opcode::CALL_Jv,    {DECODE_FUNCS}, decode_s0x_imm16
index_byte_at size, Opcode::JMP_Jv,     {DECODE_FUNCS}, decode_s0x_imm16
index_byte_at size, Opcode::JMP_Ap,     {DECODE_FUNCS}, decode_s0x_imm16_s1x_imm16
index_byte_at size, Opcode::JMP_Jb,     {DECODE_FUNCS}, decode_s0l_imm8
index_byte_at size, Opcode::IN_AL_DX,   {DECODE_FUNCS}, decode_s0x_dx
index_byte_at size, Opcode::IN_AX_DX,   {DECODE_FUNCS}, decode_s0x_dx
index_byte_at size, Opcode::OUT_DX_AL,  {DECODE_FUNCS}, decode_s0x_dx_s1l_al
index_byte_at size, Opcode::OUT_DX_AX,  {DECODE_FUNCS}, decode_s0x_dx_s1x_ax
index_byte_at size, Opcode::LOCK,       {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::NONE_F1h,   {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::REPNZ,      {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::REPZ,       {DECODE_FUNCS}, decode_error
index_byte_at size, Opcode::HLT,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::CMC,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::GRP3_Eb,    {DECODE_FUNCS}, decode_s0l_modrm_rm8_opt_s1l_imm8
index_byte_at size, Opcode::GRP3_Ev,    {DECODE_FUNCS}, decode_s0x_modrm_rm16_opt_s1x_imm16
index_byte_at size, Opcode::CLC,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::STC,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::CLI,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::STI,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::CLD,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::STD,        {DECODE_FUNCS}, decode_nothing
index_byte_at size, Opcode::GRP4_Eb,    {DECODE_FUNCS}, decode_s0l_modrm_rm8
index_byte_at size, Opcode::GRP4_Ev,    {DECODE_FUNCS}, \
decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi
.assert size = 256, error, "incorrect table size"

.define MODRM_FUNCS \
get_modrm_m_mode_0, \
get_modrm_m_mode_1, \
get_modrm_m_mode_2, \
get_modrm_r16

rbaModRMAddrFuncLo:
lo_return_bytes {MODRM_FUNCS}
rbaModRMAddrFuncHi:
hi_return_bytes {MODRM_FUNCS}

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; determine which registers/memory needs to be accessed.
; move data into pseudo-registers.
; set any public values that might be useful for later steps.
; calls decode handlers with
; < A = garbage
; < X = instruction opcode
; < Y = function index
.proc decode
    ldx Fetch::zbInstrOpcode
    ldy rbaDecodeFuncIndex, x
    lda rbaDecodeFuncHi, y
    pha
    lda rbaDecodeFuncLo, y
    pha
    rts
.endproc


; ==============================================================================
; decode handlers
; see "decode" for argument descriptions
; ==============================================================================

; the instruction needs no inputs nor outputs or all inputs and outputs are static.
; return immediately without performing any actions.
; e.g.
;   NOP
;   CBW
.proc decode_nothing
    rts
.endproc


;    reg -> rm
;    rm -> reg
.proc decode_s0x_modrm_reg16_d0x_modrm_rm16
    jsr parse_modrm
    jsr use_modrm_pointer
    jsr get_modrm_reg16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_modrm_reg8_d0l_modrm_rm8
    jsr parse_modrm
    jsr use_modrm_pointer
    jsr get_modrm_reg8
    sta Reg::zbS0L
    rts
.endproc


; extended CALL, JMP, PUSH
decode_s0x_modrm_rm16: ; [code_label]
; extended INC, DEC
decode_s0x_modrm_rm16_d0x_modrm_rm16: ; [code_label]
.proc decode_s0x_modrm_rm16_d0x_modrm_reg16
    jsr parse_modrm
    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_modrm_rm8_d0l_modrm_reg8
    jsr parse_modrm
    jsr get_modrm_rm8
    sta Reg::zbS0L
    rts
.endproc


;    imm -> rm
.proc decode_s0x_imm16_d0x_modrm_rm16
    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS0X

    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS0X+1

    jsr parse_modrm
    jsr use_modrm_pointer
    rts
.endproc


.proc decode_s0l_imm8_d0l_modrm_rm8
    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS0L

    jsr parse_modrm
    jsr use_modrm_pointer
    rts
.endproc


;    imm -> reg
.proc decode_s0x_imm16_d0x_embed_reg16
    lda Fetch::zaInstrOperands+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_imm8_d0l_embed_reg8
    lda Fetch::zaInstrOperands
    sta Reg::zbS0L

    ; determine the register that the "write" stage needs
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg

    rts
.endproc


;    mem -> acc
;    acc -> mem
.proc decode_s0x_mem16_imm16
    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jsr Mem::use_pointer

    jsr Mem::get_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_mem8_imm16
    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jsr Mem::use_pointer

    jsr Mem::get_byte
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_ax_d0x_mem16
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_d0l_mem8
    lda Reg::zbAL
    sta Reg::zbS0L

    jsr use_prefix_or_ds_segment

    lda Fetch::zaInstrOperands
    ldx Fetch::zaInstrOperands+1
    jmp Mem::use_pointer
    ; [tail_jump]
.endproc


;    seg -> rm
;    rm -> seg
.proc decode_s0x_modrm_seg16_d0x_modrm_rm16
    jsr parse_modrm
    jsr get_modrm_seg
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    jmp use_modrm_pointer
    ; [tail_jump]
.endproc


; changes: A, X, Y
.proc decode_s0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc


; changes: A, X, Y
.proc decode_s0x_embed_seg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_SEG_MASK
    lsr
    lsr
    lsr
    tay

    ldx Reg::rzbaSegRegMap, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_d0x_modrm_rm
    jsr parse_modrm
    jmp use_modrm_pointer
    ; [tail_jump]
.endproc


; changes: A, X, Y
.proc decode_d0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg
    rts
.endproc


; changes: A, X, Y
.proc decode_d0x_embed_seg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_SEG_MASK
    lsr
    lsr
    lsr
    sta zbSeg
    rts
.endproc


;    reg -> rm
;    rm -> reg
.proc decode_s0x_modrm_reg16_s1x_modrm_rm16
    jsr parse_modrm

    jsr get_modrm_reg16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr get_modrm_rm16
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0l_modrm_reg8_s1l_modrm_rm8
    jsr parse_modrm

    jsr get_modrm_reg8
    sta Reg::zbS0L

    jsr get_modrm_rm8
    sta Reg::zbS1L
    rts
.endproc


; changes: A, X, Y
.proc decode_s0x_embed_reg16_s1x_ax
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta zbReg
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1

    lda Reg::zwAX
    sta Reg::zwS1X
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_imm8_s1x_ax
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_imm8_s1l_al
    lda Reg::zbAL
    sta Reg::zbS1L
    ; [fall_through]
.endproc

.proc decode_s0x_imm8
    lda Fetch::zaInstrOperands
    sta Reg::zwS0X
    ; convert the 8-bit unsigned int to a 16-bit unsigned int
    lda #0
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0x_dx_s1x_ax
    lda Reg::zwAX+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_dx_s1l_al
    lda Reg::zbAL
    sta Reg::zbS1L
    ; [fall_through]
.endproc

.proc decode_s0x_dx
    lda Reg::zwDX
    sta Reg::zwS0X
    lda Reg::zwDX+1
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_mem8_bx_al
    jsr use_prefix_or_ds_segment

    clc

    lda Reg::zwBX
    adc Reg::zbAL
    pha

    lda Reg::zwBX+1
    adc #0
    tax
    pla

    jsr Mem::use_pointer

    jsr Mem::get_byte
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_m_addr
    jsr parse_modrm
    jsr get_modrm_m
    lda Tmp::zw0
    sta Reg::zwS0X
    lda Tmp::zw0+1
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    jsr parse_modrm

modrm_parsed:

    jsr use_modrm_pointer

    jsr Mem::get_dword_lo
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr Mem::get_dword_hi
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_flags
    lda Reg::zwFlags+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_flags_lo
    lda Reg::zbFlagsLo
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0l_ah
    lda Reg::zbAH
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_modrm_reg16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    jsr get_modrm_reg16
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0l_modrm_rm8_s1l_modrm_reg8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    jsr get_modrm_reg8
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_ax_s1x_imm16
    lda Reg::zwAX+1
    sta Reg::zwS0X+1

    lda Fetch::zaInstrOperands+1
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_s1l_imm8
    lda Reg::zbAL
    sta Reg::zbS0L

    lda Fetch::zaInstrOperands
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_embed_reg16_d0x_embed_reg16
    lda Fetch::zbInstrOpcode
    and #Decode::EMBED_REG_MASK
    sta Decode::zbReg
    tay

    ldx Reg::rzbaReg16Map, y
    lda Const::ZERO_PAGE, x
    sta Reg::zwS0X
    lda Const::ZERO_PAGE+1, x
    sta Reg::zwS0X+1
    rts
.endproc


.proc decode_s0x_ax
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al
    lda Reg::zbAL
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0l_al_s1l_ah_s2l_imm8
    lda Reg::zbAL
    sta Reg::zbS0L

    lda Reg::zbAH
    sta Reg::zbS1L

    lda Fetch::zaInstrOperands
    sta Reg::zbS2L
    rts
.endproc


.proc decode_s0x_mem16_si
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


.proc decode_s0l_mem8_si
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_byte
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_mem16_si_s1x_mem16_di
    jsr use_prefix_or_ds_segment

    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_word
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0l_mem8_si_s1l_mem8_di
    jsr use_prefix_or_ds_segment

    jsr Mem::get_si_byte
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_byte
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_ax_s1x_mem16_di
    lda Reg::zwAX
    sta Reg::zwS0X
    lda Reg::zwAX+1
    sta Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_word
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_al_s1x_mem8_di
    lda Reg::zbAL
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment

    jsr Mem::get_di_byte
    sta Reg::zwS1X
    stx Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_imm16_s1x_imm16
    lda Fetch::zaInstrOperands+2
    sta Reg::zwS1X
    lda Fetch::zaInstrOperands+3
    sta Reg::zwS1X+1
    ; [fall_through]
.endproc

.proc decode_s0x_imm16
    lda Fetch::zaInstrOperands+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_imm8
    lda Fetch::zaInstrOperands
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_ax_d0x_mem16_di
    lda Reg::zwAX+1
    sta Reg::zwS0X+1
    ; [fall_through]
.endproc

.proc decode_s0l_al_d0l_mem8_di
    lda Reg::zbAL
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc


.proc decode_s0x_mem16_si_d0x_mem16_di
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_word
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc


.proc decode_s0l_mem8_si_d0l_mem8_di
    jsr use_prefix_or_ds_segment
    jsr Mem::get_si_byte
    sta Reg::zbS0L

    ldx #Reg::zwES
    jsr Mem::use_segment
    rts
.endproc


; =============================================================================
; decode extended instructions
; =============================================================================

; ----------------------------------------
; group 1
; ----------------------------------------

.proc decode_s0l_modrm_rm8_s1l_imm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_imm16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS1X
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X+1
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1x_imm8
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X
    jsr Util::get_extend_sign
    sta Reg::zwS1X+1
    rts
.endproc


; ----------------------------------------
; group 2
; ----------------------------------------

.proc decode_s0l_modrm_rm8_s1l_1
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda #1
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1l_1
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda #1
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0l_modrm_rm8_s1l_cl
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda Reg::zbCL
    sta Reg::zbS1L
    rts
.endproc


.proc decode_s0x_modrm_rm16_s1l_cl
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda Reg::zbCL
    sta Reg::zbS1L
    rts
.endproc


; ----------------------------------------
; group 3
; ----------------------------------------

.proc decode_s0l_modrm_rm8_opt_s1l_imm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L

    lda zbExt
    bne done ; branch if the instruction is not TEST.

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zbS1L

done:
    rts
.endproc


.proc decode_s0x_modrm_rm16_opt_s1x_imm16
    jsr parse_modrm

    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1

    lda zbExt
    bne done ; branch if the instruction is not TEST.

    ldx Fetch::zbInstrLen
    lda Fetch::zbInstrBuffer-2, x
    sta Reg::zwS1X
    lda Fetch::zbInstrBuffer-1, x
    sta Reg::zwS1X+1

done:
    rts
.endproc


; ----------------------------------------
; group 4
; ----------------------------------------

.proc decode_s0l_modrm_rm8
    jsr parse_modrm

    jsr get_modrm_rm8
    sta Reg::zbS0L
    rts
.endproc


.proc decode_s0x_modrm_rm16_or_s0x_modrm_m32_lo_s1x_modrm_m32_hi
    jsr parse_modrm

    ; we need to get a segment and pointer from memory if the extended instruction is...
    ;   CALL DWORD PTR [pointer]    - index 3
    ;   JMP DWORD PTR [pointer]     - index 5
    ; index 7 is illegal.
    lda zbExt
    lsr

    bcc s0x_modrm_rm16 ; branch if the index was even.
    beq s0x_modrm_rm16 ; branch if the index was 1.
    jmp decode_s0x_modrm_m32_lo_s1x_modrm_m32_hi::modrm_parsed

s0x_modrm_rm16:
    jsr get_modrm_rm16
    sta Reg::zwS0X
    stx Reg::zwS0X+1
    rts
.endproc


; called when an unsupported opcode is decoded
.proc decode_error
    lda #X86::eErr::DECODE_ERROR
    jmp X86::panic
    ; [tail_jump]
.endproc


; ==============================================================================
; utility functions
; ==============================================================================

; get the segment for the current instruction.
; if the instruction has a segment prefix then the indicated segment will be used.
; otherwise, the default segment in X will be used.
; < X = default segment register zero-page address.
; > X = segment register zero-page address.
; get the segment in preparation for calling ""
; if the instruction has a segment prefix then the indicated segment will be used.
; otherwise, the default segment in X will be used.
; < X = default segment register zero-page address.
; > Tmp::zb2 = segment register zero-page address.
; changes: A, X, Y

.proc use_prefix_or_ds_segment
    ldx #Reg::zwDS
    lda Fetch::zbPrefixSegment
    beq use_segment ; branch if there is no segment prefix

    ; get segment register index
    and #Decode::PREFIX_SEG_MASK
    lsr
    lsr
    lsr

    ; get segment register address
    tay
    ldx Reg::rzbaSegRegMap, y

use_segment:
    jmp Mem::use_segment
    ; [tail_jump]
.endproc


; extract the Mod, reg, and R/M fields of a ModR/M byte.
; the fetch stage already set zbMod but callers should act as though it didn't.
; that should make any future changes easier to implement.
; > zbMod = ModR/M Mod field (not actually changed)
; > zbReg, zbSeg, zbExt = ModR/M reg field
; > zbRM = ModR/M R/M field
; changes: A, C
.proc parse_modrm
    lda Fetch::zaInstrOperands
    and #Decode::MODRM_RM_MASK
    sta zbRM

    lda Fetch::zaInstrOperands
    and #Decode::MODRM_REG_MASK
    lsr
    lsr
    lsr
    sta zbReg

    lda Fetch::zaInstrOperands
    and #Decode::MODRM_MOD_MASK
    asl
    rol
    rol
    sta zbMod
    rts
.endproc


; calculate a memory address from a ModR/M byte and relevant operands.
; < zbMod
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m
    ldx zbMod
    lda rbaModRMAddrFuncHi, x
    pha
    lda rbaModRMAddrFuncLo, x
    pha
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 0.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_0
    ldy zbRM
    cpy #Decode::MODRM_RM_DIRECT
    beq get_modrm_m_direct ; branch if we need to handle a direct 16-bit address.
    ; [tail_branch]
.endproc

; calculate a indirect memory address from 1 or more registers
; indicated by the R/M field of a ModR/M byte.
; < Y = zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
; see also:
;   Reg::rzbaMem0Map
;   Reg::rzbaMem1Map
.proc get_modrm_m_indirect
    ; get register address
    ldx Reg::rzbaMem0Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    sta Tmp::zw0
    lda Const::ZERO_PAGE+1, x
    sta Tmp::zw0+1

    ; check if we need to add the value of another register.
    cpy #Decode::MODRM_RM_MAP
    bcs done

    ; get register address
    ldx Reg::rzbaMem1Map, y

    ; add register value
    clc
    lda Const::ZERO_PAGE, x
    adc Tmp::zw0
    sta Tmp::zw0
    lda Const::ZERO_PAGE+1, x
    adc Tmp::zw0+1
    sta Tmp::zw0+1

done:
    rts
.endproc


; copy a direct memory address operand.
; > Tmp::zw0 = direct memory address
; changes: A
.proc get_modrm_m_direct
    lda Fetch::zaInstrOperands+1
    sta Tmp::zw0
    lda Fetch::zaInstrOperands+2
    sta Tmp::zw0+1
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 1.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_1
    ldy zbRM
    jsr get_modrm_m_indirect

    ; sign extend the 8-bit offset and store the high byte in X for later.
    lda Fetch::zaInstrOperands+1
    jsr Util::get_extend_sign
    tax

    ; add the offset to the address
    clc
    lda Fetch::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    txa
    adc Tmp::zw0+1
    sta Tmp::zw0+1
    rts
.endproc


; calculate a memory address from a ModR/M byte in mode 2.
; < zbRM
; > Tmp::zw0 = calculated address
; changes: A, X, Y
.proc get_modrm_m_mode_2
    ldy zbRM
    jsr get_modrm_m_indirect

    ; add the 16-bit unsigned offset to the address
    clc
    lda Fetch::zaInstrOperands+1
    adc Tmp::zw0
    sta Tmp::zw0
    lda Fetch::zaInstrOperands+2
    adc Tmp::zw0+1
    sta Tmp::zw0+1
    rts
.endproc


; set the  to a memory address indicated by a ModR/M byte.
; if the ModR/M byte indicates that a register should be used then nothing is done.
; < X = default segment register zero-page address.
; > Tmp::zw0 = memory address calculated from a ModR/M byte.
; > Tmp::zb2 = segment register zero-page address.
; changes: A, X, Y
.proc use_modrm_pointer
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq done ; branch if R/M value points to a register, not memory

    ; this is an alternative entry point.
    ; it assumes that the ModR/M byte doesn't indicate a register access.
skip_reg_check:
    jsr use_prefix_or_ds_segment
    jsr get_modrm_m
    lda Tmp::zw0
    ldx Tmp::zw0+1
    jsr Mem::use_pointer

done:
    rts
.endproc


; get a 16-bit value from a register or memory
; depending on the state of a ModR/M byte.
; < X = default segment register zero-page address.
; < zbMod
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_rm16
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq get_modrm_r16 ; branch if the value comes from a register, not memory
    ; [tail_branch]
.endproc

; get a 16-bit value from memory.
; < X = default segment register zero-page address.
; < zbMod
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_m16
    jsr use_modrm_pointer::skip_reg_check
    jmp Mem::get_word
    ; [tail_jump]
.endproc


; get a 16-bit value from a register indicated by the R/M field of a ModR/M byte.
; this is also used by "get_modrm_m" as a fail-safe of sorts.
; < zbRM
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_r16
    ; get register index
    ldx zbRM

    ; get register address
    ldy Reg::rzbaReg16Map, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc


; get a 8-bit value from a register or memory
; depending on the state of a ModR/M byte.
; < X = default segment register zero-page address.
; < zbMod
; > A
; changes: A, X, Y
.proc get_modrm_rm8
    lda zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    beq get_modrm_r8 ; branch if the value comes from a register, not memory
    ; [tail_branch]
.endproc

; get a 8-bit value from memory
; < X = default segment register zero-page address.
; < zbMod
; > A
; changes: A, X, Y
.proc get_modrm_m8
    jsr use_modrm_pointer::skip_reg_check
    jmp Mem::get_byte
    ; [tail_jump]
.endproc


; get a 8-bit value from a register indicated by the R/M field of a ModR/M byte.
; < zbRM
; > A
; changes: A, X, Y
.proc get_modrm_r8
    ; get register index
    ldy zbRM

    ; get register address
    ldx Reg::rzbaReg8Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    rts
.endproc


; get a 16-bit value from a register indicated by the reg field of a ModR/M byte.
; < zbReg
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_reg16
    ; get register index
    ldx zbReg

    ; get register address
    ldy Reg::rzbaReg16Map, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc


; get a 8-bit value from a register indicated by the reg field of a ModR/M byte.
; < zbReg
; > A
; changes: A, X, Y
.proc get_modrm_reg8
    ; get register index
    ldy zbReg

    ; get register address
    ldx Reg::rzbaReg8Map, y

    ; get register value
    lda Const::ZERO_PAGE, x
    rts
.endproc


; get a 16-bit value from a segment register indicated by the reg field of a ModR/M byte.
; this function can cause some unintended behavior if ModR/M bit 5 is set.
; compilers/assemblers should generate well formed code that don't set bit 5.
; it also shouldn't break the emulator either so i'm not fixing it.
; unintended behavior is fun.
; < zbSeg
; > A = low byte
; > X = high byte
; changes: A, X, Y
.proc get_modrm_seg

    ; get register index
    ldx zbSeg

    ; get register address
    ldy Reg::rzbaSegRegMap, x

    ; get register value
    lda Const::ZERO_PAGE, y
    ldx Const::ZERO_PAGE+1, y
    rts
.endproc
