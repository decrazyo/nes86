
; This module is responsible for reading x86 instructions from the x86 address space
; into an instruction buffer. instructions may come from RAM or ROM.

.linecont +

.include "list.inc"
.include "x86.inc"
.include "x86/decode.inc"
.include "x86/fetch.inc"
.include "x86/mem.inc"
.include "x86/opcode.inc"
.include "x86/reg.inc"

.exportzp zbPrefixSegment
.exportzp zbPrefixRepeat
.exportzp zbPrefixLock

.exportzp zbInstrLen
.exportzp zbInstrBuffer
.exportzp zbInstrOpcode
.exportzp zaInstrOperands

.export fetch

.segment "ZEROPAGE"

; segment prefix
; CS, DS, ES, SS
zbPrefixSegment: .res 1

; repeat prefix
; REPZ, REPNZ
zbPrefixRepeat: .res 1

; lock prefix
; LOCK
zbPrefixLock: .res 1

; instruction length
; opcode + operands
; does not include prefixes
zbInstrLen: .res 1

; instruction buffer
zbInstrBuffer:
zbInstrOpcode: .res 1
zaInstrOperands: .res Fetch::BUFFER_LEN

.segment "RODATA"

.define FETCH_FUNCS \
fetch_error, \
fetch_len_1, \
fetch_len_2, \
fetch_len_3, \
fetch_len_4, \
fetch_len_5, \
fetch_modrm_reg, \
fetch_modrm_ext_imm8, \
fetch_modrm_ext_imm16, \
fetch_modrm_ext_opt_imm8, \
fetch_modrm_ext_opt_imm16, \
fetch_segment_prefix, \
fetch_repeat_prefix, \
fetch_lock_prefix

; the functions fetch_len_1 through fetch_len_5 must be at indices 1 through 5.
; we'll check that they are to ensure that the functions operate correctly.
.repeat 5, i
    j .set i + 1

    index .set -1
    index_of {FETCH_FUNCS}, .ident(.sprintf("fetch_len_%i", j)), index

    .if index <> j
        .error.sprintf("fetch_len_%i is at index %i instead of index %i", j, index, j)
    .endif
.endrepeat

; fetch function jump table
rbaFetchFuncLo:
lo_return_bytes {FETCH_FUNCS}
rbaFetchFuncHi:
hi_return_bytes {FETCH_FUNCS}

; map opcodes to jump table indices
size .set 0
rbaFetchFuncIndex:
index_byte_at size, Opcode::ADD_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADD_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADD_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADD_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADD_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::ADD_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::PUSH_ES,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_ES,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::OR_Eb_Gb,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::OR_Ev_Gv,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::OR_Gb_Eb,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::OR_Gv_Ev,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::OR_AL_Ib,   {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::OR_AX_Iv,   {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::PUSH_CS,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::NONE_0Fh,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::ADC_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADC_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADC_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADC_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::ADC_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::ADC_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::PUSH_SS,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_SS,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::SBB_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SBB_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SBB_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SBB_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SBB_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::SBB_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::PUSH_DS,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_DS,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::AND_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::AND_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::AND_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::AND_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::AND_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::AND_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::ES,         {FETCH_FUNCS}, fetch_segment_prefix
index_byte_at size, Opcode::DAA,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::SUB_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SUB_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SUB_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SUB_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::SUB_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::SUB_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::CS,         {FETCH_FUNCS}, fetch_segment_prefix
index_byte_at size, Opcode::DAS,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XOR_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XOR_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XOR_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XOR_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XOR_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::XOR_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::SS,         {FETCH_FUNCS}, fetch_segment_prefix
index_byte_at size, Opcode::AAA,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CMP_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::CMP_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::CMP_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::CMP_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::CMP_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::CMP_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::DS,         {FETCH_FUNCS}, fetch_segment_prefix
index_byte_at size, Opcode::AAS,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_AX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_CX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_DX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_BX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_SP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_BP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_SI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INC_DI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_AX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_CX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_DX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_BX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_SP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_BP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_SI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::DEC_DI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_AX,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_CX,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_DX,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_BX,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_SP,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_BP,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_SI,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSH_DI,    {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_AX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_CX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_DX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_BX,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_SP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_BP,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_SI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POP_DI,     {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::NONE_60h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_61h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_62h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_63h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_64h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_65h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_66h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_67h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_68h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_69h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Ah,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Bh,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Ch,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Dh,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Eh,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_6Fh,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::JO_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNO_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JB_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JAE_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JZ_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNZ_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNA_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JA_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JS_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNS_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JPE_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JPO_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JL_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNL_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JNG_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JG_Jb,      {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::GRP1_Eb_Ib, {FETCH_FUNCS}, fetch_modrm_ext_imm8
index_byte_at size, Opcode::GRP1_Ev_Iv, {FETCH_FUNCS}, fetch_modrm_ext_imm16
index_byte_at size, Opcode::GRP1_82h,   {FETCH_FUNCS}, fetch_modrm_ext_imm8
index_byte_at size, Opcode::GRP1_Ev_Ib, {FETCH_FUNCS}, fetch_modrm_ext_imm8
index_byte_at size, Opcode::TEST_Gb_Eb, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::TEST_Gv_Ev, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XCHG_Gb_Eb, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::XCHG_Gv_Ev, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Eb_Gb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Ev_Gv,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Gb_Eb,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Gv_Ev,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Ew_Sw,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::LEA_Gv_M,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Sw_Ew,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::POP_Ev,     {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NOP,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_CX_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_DX_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_BX_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_SP_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_BP_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_SI_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::XCHG_DI_AX, {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CBW,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CWD,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CALL_Ap,    {FETCH_FUNCS}, fetch_len_5
index_byte_at size, Opcode::WAIT,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::PUSHF,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::POPF,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::SAHF,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::LAHF,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::MOV_AL_Ob,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_AX_Ov,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_Ob_AL,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_Ov_AX,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOVSB,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::MOVSW,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CMPSB,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CMPSW,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::TEST_AL_Ib, {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::TEST_AX_Iv, {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::STOSB,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::STOSW,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::LODSB,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::LODSW,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::SCASB,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::SCASW,      {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::MOV_AL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_CL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_DL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_BL_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_AH_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_CH_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_DH_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_BH_Ib,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::MOV_AX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_CX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_DX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_BX_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_SP_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_BP_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_SI_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::MOV_DI_Iv,  {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::NONE_C0h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_C1h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::RET_Iw,     {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::RET,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::LES_Gv_Mp,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::LDS_Gv_Mp,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::MOV_Eb_Ib,  {FETCH_FUNCS}, fetch_modrm_ext_imm8
index_byte_at size, Opcode::MOV_Ev_Iv,  {FETCH_FUNCS}, fetch_modrm_ext_imm16
index_byte_at size, Opcode::NONE_C8h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::NONE_C9h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::RETF_Iw,    {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::RETF,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INT3,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::INT_Ib,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::INTO,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::IRET,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::GRP2_Eb_1,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::GRP2_Ev_1,  {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::GRP2_Eb_CL, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::GRP2_Ev_CL, {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::AAM_I0,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::AAD_I0,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::NONE_D6h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::XLAT,       {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::NONE_D8h,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_D9h,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DAh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DBh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DCh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DDh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DEh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::NONE_DFh,   {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::LOOPNZ_Jb,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::LOOPZ_Jb,   {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::LOOP_Jb,    {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::JCXZ_Jb,    {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::IN_AL_Ib,   {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::IN_AX_Ib,   {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::OUT_Ib_AL,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::OUT_Ib_AX,  {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::CALL_Jv,    {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::JMP_Jv,     {FETCH_FUNCS}, fetch_len_3
index_byte_at size, Opcode::JMP_Ap,     {FETCH_FUNCS}, fetch_len_5
index_byte_at size, Opcode::JMP_Jb,     {FETCH_FUNCS}, fetch_len_2
index_byte_at size, Opcode::IN_AL_DX,   {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::IN_AX_DX,   {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::OUT_DX_AL,  {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::OUT_DX_AX,  {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::LOCK,       {FETCH_FUNCS}, fetch_lock_prefix
index_byte_at size, Opcode::NONE_F1h,   {FETCH_FUNCS}, fetch_error
index_byte_at size, Opcode::REPNZ,      {FETCH_FUNCS}, fetch_repeat_prefix
index_byte_at size, Opcode::REPZ,       {FETCH_FUNCS}, fetch_repeat_prefix
index_byte_at size, Opcode::HLT,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CMC,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::GRP3_Eb,    {FETCH_FUNCS}, fetch_modrm_ext_opt_imm8
index_byte_at size, Opcode::GRP3_Ev,    {FETCH_FUNCS}, fetch_modrm_ext_opt_imm16
index_byte_at size, Opcode::CLC,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::STC,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CLI,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::STI,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::CLD,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::STD,        {FETCH_FUNCS}, fetch_len_1
index_byte_at size, Opcode::GRP4_Eb,    {FETCH_FUNCS}, fetch_modrm_reg
index_byte_at size, Opcode::GRP4_Ev,    {FETCH_FUNCS}, fetch_modrm_reg
.assert size = 256, error, "incorrect table size"

.define MODRM_FUNCS \
modrm_rm_mode_0, \
modrm_rm_mode_1, \
modrm_rm_mode_2, \
modrm_rm_mode_3

; ModR/M mode jump table
rbaModRMFuncLo:
lo_return_bytes {MODRM_FUNCS}
rbaModRMFuncHi:
hi_return_bytes {MODRM_FUNCS}

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; instruction fetch
; read instruction bytes into the instruction buffer.
; changes: A, X, Y
; calls fetch handlers with
; < A = instruction byte
; < X = instruction length
; < Y = function index
.proc fetch
    ; check if we need to repeat the previous instruction.
    lda Fetch::zbPrefixRepeat
    bne done ; branch if there is a repeat prefix

    ; reset the instruction length and segment prefix
    sta Fetch::zbInstrLen
    sta Fetch::zbPrefixSegment

    ldx #Reg::zwCS
    jsr Mem::use_segment

next:
    ; get a byte from memory
    jsr Mem::get_ip_byte

    ; lookup the appropriate handler
    tax
    ldy rbaFetchFuncIndex, x

    ; call the fetch handler
    lda rbaFetchFuncHi, y
    pha
    lda rbaFetchFuncLo, y
    pha
    txa ; instruction byte
done:
    rts
.endproc


; ==============================================================================
; fetch handlers
; see "fetch" for argument descriptions
; ==============================================================================

; called when an unsupported instruction byte is fetch.
.proc fetch_error
    jsr buffer_ip_byte
    lda #X86::eErr::FETCH_ERROR
    jmp X86::panic
    ; [tail_jump]
.endproc


; handle fixed length 5 byte instruction.
.proc fetch_len_5
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 4 byte instruction.
.proc fetch_len_4
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 3 byte instruction.
.proc fetch_len_3
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; handle fixed length 2 byte instruction.
.proc fetch_len_2
    jsr buffer_ip_byte
    jsr Mem::get_ip_byte
    ; [fall_through]
.endproc

; append a byte to the instruction buffer.
buffer_ip_byte:
; handle fixed length 1 byte instruction.
.proc fetch_len_1
    ldx zbInstrLen
    sta Fetch::zbInstrBuffer, x
    inc zbInstrLen
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 8-bit immediate value.
.proc fetch_modrm_ext_imm8
    jsr modrm_rm_mode
    jmp modrm_rm_mode_1
    ; [tail_jump]
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode needs an additional 16-bit immediate value.
.proc fetch_modrm_ext_imm16
    jsr modrm_rm_mode
    jmp modrm_rm_mode_2
    ; [tail_jump]
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 8-bit immediate value.
.proc fetch_modrm_ext_opt_imm8
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jmp modrm_rm_mode_1
done:
    rts
.endproc


; fetch ModR/M bytes.
; the reg field indexes an opcode extension.
; the extended opcode might need an additional 16-bit immediate value.
.proc fetch_modrm_ext_opt_imm16
    jsr modrm_rm_mode
    lda zaInstrOperands
    and #Decode::MODRM_EXT_MASK
    bne done ; branch if the extended opcode isn't a TEST instruction.
    jmp modrm_rm_mode_2
done:
    rts
.endproc


; fetch segment prefix
.proc fetch_segment_prefix
    sta Fetch::zbPrefixSegment
    jmp fetch::next
    ; [tail_jump]
.endproc


; fetch repeat prefix
.proc fetch_repeat_prefix
    ; store the repeat prefix.
    sta Fetch::zbPrefixRepeat

    ; fetch the instruction to be repeated.
    jsr fetch::next

    ; repeat prefixes are only valid for string instructions.
    ; attempting to repeat a non-string instruction will cause an infinite loop.
    ; to avoid that, we'll explicitly check that we are repeating a string instruction.
    lda zbInstrOpcode

    ; if we aren't repeating a string instruction then we'll remove the repeat prefix.
    cmp #Opcode::MOVSB
    bcc no_repeat
    cmp #Opcode::SCASW + 1
    bcs no_repeat
    cmp #Opcode::TEST_AL_Ib
    beq no_repeat
    cmp #Opcode::TEST_AX_Iv
    beq no_repeat

    ; check the value of CX.
    lda Reg::zwCX
    ora Reg::zwCX+1
    bne done ; branch if CX != 0

    ; CX is already zero so we shouldn't execute the instruction.
    ; remove the return address to skip the rest of the instruction pipeline.
    ; NOTE: this is kind of a hack but it works well enough.
    pla
    pla

no_repeat:
    ; remove the repeat prefix to resume normal execution.
    lda #0
    sta Fetch::zbPrefixRepeat

done:
    rts
.endproc


; fetch lock prefix.
; the emulator doesn't use this prefix for anything.
; all instructions are already executed atomically.
.proc fetch_lock_prefix
    sta Fetch::zbPrefixLock
    jmp fetch::next
    ; [tail_jump]
.endproc


; ==============================================================================
; ModR/M mode specific handlers.
; ==============================================================================

; fetch ModR/M bytes.
; the reg field indexes a register
; or an opcode extension that doesn't need anything special.
fetch_modrm_reg:
; read a ModR/M byte and any additional bytes indicated by the Mod and R/M fields.
.proc modrm_rm_mode
    ; store the instruction byte
    jsr buffer_ip_byte

    ; store the ModR/M byte
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte

    ; move the Mod field into the 2 lowest bits.
    and #Decode::MODRM_MOD_MASK
    asl
    rol
    rol

    ; use the mode to index a function pointer.
    tay
    lda rbaModRMFuncHi, y
    pha
    lda rbaModRMFuncLo, y
    pha

    ; call ModR/M mode specific handler.
    ; A = garbage
    ; X = instruction length
    ; Y = ModR/M mode
    rts
.endproc


; handle ModR/M mode 0
; possibly fetch 2 more bytes depending on the R/M field value.
.proc modrm_rm_mode_0
    ; grab the ModR/M byte
    ldx zbInstrLen
    lda Fetch::zbInstrBuffer-1, x

    ; assess the R/M field.
    and #Decode::MODRM_RM_MASK
    cmp #Decode::MODRM_RM_DIRECT
    bne modrm_rm_mode_3 ; branch if the R/M field refers to registers.
    ; the R/M field refers to a direct address that we need to fetch.
    ; [tail_branch]
.endproc

; handle ModR/M mode 2
; 16-bit signed offset
; read 2 more byte
.proc modrm_rm_mode_2
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte
    ; [fall_through]
.endproc

; handle ModR/M mode 1
; 8-bit signed offset
; read 1 more byte
.proc modrm_rm_mode_1
    jsr Mem::get_ip_byte
    jsr buffer_ip_byte
    ; [fall_through]
.endproc

; handle ModR/M mode 3
; the R/M field contains a register index.
; nothing more to do.
.proc modrm_rm_mode_3
    rts
.endproc
