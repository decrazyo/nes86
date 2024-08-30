
; This module is responsible for writing values to registers and the x86 address space.
; If an instruction's opcode indicates that it simply moves a value to or from a fixed
; location, i.e. a specific register or the stack, then this module may read that value.
; This module may decode instructions to determine where to write data.
; If this module must write to the x86 address space then it expects the MMU
; to have already been configured for that write by the "decode" stage.
; If this module writes to "CS" or "IP" then it must flag the MMU's code address as dirty.
; If this module writes to "SS" or "SP" then it must flag the MMU's stack address as dirty.

.linecont +

.include "const.inc"
.include "list.inc"
.include "tmp.inc"
.include "x86.inc"
.include "x86/decode.inc"
.include "x86/fetch.inc"
.include "x86/interrupt.inc"
.include "x86/mem.inc"
.include "x86/opcode.inc"
.include "x86/reg.inc"
.include "x86/write.inc"

.export write

.segment "RODATA"

.define WRITE_FUNCS \
write_nothing, \
write_d0l_rm8, \
write_d0x_rm16, \
write_d0l_reg8, \
write_d0x_reg16, \
write_d0l_al, \
write_d0x_ax, \
write_d0l_mem8, \
write_d0x_mem16, \
write_d0x_seg16, \
write_d0l_reg8_d1l_rm8, \
write_d0x_reg16_d1x_rm16, \
write_d0x_reg16_d1x_ax, \
write_d0x_ds_d1x_reg16, \
write_d0x_es_d1x_reg16, \
write_d0l_ah, \
write_d0l_flags_lo, \
write_d0x_flags, \
write_d0l_al_d1l_ah, \
write_d0x_ax_d1x_dx, \
write_d0l_mem8_di, \
write_d0x_mem16_di, \
write_group1a, \
write_group1b, \
write_group3a, \
write_group3b, \
write_group4b, \
write_bad

; write function jump table
rbaWriteFuncLo:
lo_return_bytes {WRITE_FUNCS}
rbaWriteFuncHi:
hi_return_bytes {WRITE_FUNCS}

; map opcodes to jump table indices
size .set 0
rbaWriteFuncIndex:
index_byte_at size, Opcode::ADD_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::ADD_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::ADD_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::ADD_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::ADD_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::ADD_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::PUSH_ES,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::POP_ES,     {WRITE_FUNCS}, write_d0x_seg16
index_byte_at size, Opcode::OR_Eb_Gb,   {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::OR_Ev_Gv,   {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::OR_Gb_Eb,   {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::OR_Gv_Ev,   {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::OR_AL_Ib,   {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::OR_AX_Iv,   {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::PUSH_CS,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_0Fh,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::ADC_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::ADC_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::ADC_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::ADC_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::ADC_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::ADC_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::PUSH_SS,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::POP_SS,     {WRITE_FUNCS}, write_d0x_seg16
index_byte_at size, Opcode::SBB_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::SBB_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::SBB_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::SBB_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::SBB_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::SBB_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::PUSH_DS,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::POP_DS,     {WRITE_FUNCS}, write_d0x_seg16
index_byte_at size, Opcode::AND_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::AND_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::AND_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::AND_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::AND_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::AND_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::ES,         {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::DAA,        {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::SUB_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::SUB_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::SUB_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::SUB_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::SUB_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::SUB_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::CS,         {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::DAS,        {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::XOR_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::XOR_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::XOR_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::XOR_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::XOR_AL_Ib,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::XOR_AX_Iv,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::SS,         {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::AAA,        {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::CMP_Eb_Gb,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMP_Ev_Gv,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMP_Gb_Eb,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMP_Gv_Ev,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMP_AL_Ib,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMP_AX_Iv,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::DS,         {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::AAS,        {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::INC_AX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_CX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_DX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_BX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_SP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_BP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_SI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::INC_DI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_AX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_CX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_DX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_BX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_SP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_BP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_SI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::DEC_DI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::PUSH_AX,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_CX,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_DX,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_BX,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_SP,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_BP,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_SI,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSH_DI,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::POP_AX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_CX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_DX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_BX,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_SP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_BP,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_SI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::POP_DI,     {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::NONE_60h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_61h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_62h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_63h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_64h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_65h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_66h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_67h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_68h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_69h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Ah,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Bh,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Ch,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Dh,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Eh,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_6Fh,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::JO_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNO_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JB_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JAE_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JZ_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNZ_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNA_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JA_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JS_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNS_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JPE_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JPO_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JL_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNL_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JNG_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JG_Jb,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::GRP1_Eb_Ib, {WRITE_FUNCS}, write_group1a
index_byte_at size, Opcode::GRP1_Ev_Iv, {WRITE_FUNCS}, write_group1b
index_byte_at size, Opcode::GRP1_82h,   {WRITE_FUNCS}, write_group1a
index_byte_at size, Opcode::GRP1_Ev_Ib, {WRITE_FUNCS}, write_group1b
index_byte_at size, Opcode::TEST_Gb_Eb, {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::TEST_Gv_Ev, {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::XCHG_Gb_Eb, {WRITE_FUNCS}, write_d0l_reg8_d1l_rm8
index_byte_at size, Opcode::XCHG_Gv_Ev, {WRITE_FUNCS}, write_d0x_reg16_d1x_rm16
index_byte_at size, Opcode::MOV_Eb_Gb,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::MOV_Ev_Gv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::MOV_Gb_Eb,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_Gv_Ev,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_Ew_Sw,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::LEA_Gv_M,   {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_Sw_Ew,  {WRITE_FUNCS}, write_d0x_seg16
index_byte_at size, Opcode::POP_Ev,     {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::NOP,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::XCHG_CX_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_DX_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_BX_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_SP_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_BP_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_SI_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::XCHG_DI_AX, {WRITE_FUNCS}, write_d0x_reg16_d1x_ax
index_byte_at size, Opcode::CBW,        {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::CWD,        {WRITE_FUNCS}, write_d0x_ax_d1x_dx
index_byte_at size, Opcode::CALL_Ap,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::WAIT,       {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::PUSHF,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::POPF,       {WRITE_FUNCS}, write_d0x_flags
index_byte_at size, Opcode::SAHF,       {WRITE_FUNCS}, write_d0l_flags_lo
index_byte_at size, Opcode::LAHF,       {WRITE_FUNCS}, write_d0l_ah
index_byte_at size, Opcode::MOV_AL_Ob,  {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::MOV_AX_Ov,  {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::MOV_Ob_AL,  {WRITE_FUNCS}, write_d0l_mem8
index_byte_at size, Opcode::MOV_Ov_AX,  {WRITE_FUNCS}, write_d0x_mem16
index_byte_at size, Opcode::MOVSB,      {WRITE_FUNCS}, write_d0l_mem8_di
index_byte_at size, Opcode::MOVSW,      {WRITE_FUNCS}, write_d0x_mem16_di
index_byte_at size, Opcode::CMPSB,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMPSW,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::TEST_AL_Ib, {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::TEST_AX_Iv, {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::STOSB,      {WRITE_FUNCS}, write_d0l_mem8_di
index_byte_at size, Opcode::STOSW,      {WRITE_FUNCS}, write_d0x_mem16_di
index_byte_at size, Opcode::LODSB,      {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::LODSW,      {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::SCASB,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::SCASW,      {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::MOV_AL_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_CL_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_DL_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_BL_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_AH_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_CH_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_DH_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_BH_Ib,  {WRITE_FUNCS}, write_d0l_reg8
index_byte_at size, Opcode::MOV_AX_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_CX_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_DX_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_BX_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_SP_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_BP_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_SI_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::MOV_DI_Iv,  {WRITE_FUNCS}, write_d0x_reg16
index_byte_at size, Opcode::NONE_C0h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_C1h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::RET_Iw,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::RET,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::LES_Gv_Mp,  {WRITE_FUNCS}, write_d0x_es_d1x_reg16
index_byte_at size, Opcode::LDS_Gv_Mp,  {WRITE_FUNCS}, write_d0x_ds_d1x_reg16
index_byte_at size, Opcode::MOV_Eb_Ib,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::MOV_Ev_Iv,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::NONE_C8h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_C9h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::RETF_Iw,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::RETF,       {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::INT3,       {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::INT_Ib,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::INTO,       {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::IRET,       {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::GRP2_Eb_1,  {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::GRP2_Ev_1,  {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::GRP2_Eb_CL, {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::GRP2_Ev_CL, {WRITE_FUNCS}, write_d0x_rm16
index_byte_at size, Opcode::AAM_I0,     {WRITE_FUNCS}, write_d0l_al_d1l_ah
index_byte_at size, Opcode::AAD_I0,     {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::NONE_D6h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::XLAT,       {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::NONE_D8h,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_D9h,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DAh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DBh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DCh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DDh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DEh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::NONE_DFh,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::LOOPNZ_Jb,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::LOOPZ_Jb,   {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::LOOP_Jb,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JCXZ_Jb,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::IN_AL_Ib,   {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::IN_AX_Ib,   {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::OUT_Ib_AL,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::OUT_Ib_AX,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CALL_Jv,    {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JMP_Jv,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JMP_Ap,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::JMP_Jb,     {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::IN_AL_DX,   {WRITE_FUNCS}, write_d0l_al
index_byte_at size, Opcode::IN_AX_DX,   {WRITE_FUNCS}, write_d0x_ax
index_byte_at size, Opcode::OUT_DX_AL,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::OUT_DX_AX,  {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::LOCK,       {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::NONE_F1h,   {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::REPNZ,      {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::REPZ,       {WRITE_FUNCS}, write_bad
index_byte_at size, Opcode::HLT,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CMC,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::GRP3_Eb,    {WRITE_FUNCS}, write_group3a
index_byte_at size, Opcode::GRP3_Ev,    {WRITE_FUNCS}, write_group3b
index_byte_at size, Opcode::CLC,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::STC,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CLI,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::STI,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::CLD,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::STD,        {WRITE_FUNCS}, write_nothing
index_byte_at size, Opcode::GRP4_Eb,    {WRITE_FUNCS}, write_d0l_rm8
index_byte_at size, Opcode::GRP4_Ev,    {WRITE_FUNCS}, write_group4b
.assert size = 256, error, "incorrect table size"

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; write data back to memory or registers after execution.
.proc write
    ldx Fetch::zbInstrOpcode
    ldy rbaWriteFuncIndex, x
    lda rbaWriteFuncHi, y
    pha
    lda rbaWriteFuncLo, y
    pha
    rts
.endproc


; ==============================================================================
; write back handlers
; ==============================================================================

.proc write_d0x_rm16
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d0x_mem16

    ldy Decode::zbRM
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x
    rts
.endproc


.proc write_d0l_rm8
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d0l_mem8

    ldy Decode::zbRM
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD0L
    sta Const::ZERO_PAGE, x

    rts
.endproc


.proc write_d0x_reg16
    ldy Decode::zbReg
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc


.proc write_d0l_reg8
    ldy Decode::zbReg
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD0L
    sta Const::ZERO_PAGE, x

    rts
.endproc


.proc write_d0x_ax
    lda Reg::zwD0X+1
    sta Reg::zwAX+1
    ; [fall_through]
.endproc

.proc write_d0l_al
    lda Reg::zbD0L
    sta Reg::zbAL
    rts
.endproc


.proc write_d0x_mem16
    lda Reg::zwD0X
    ldx Reg::zwD0X+1
    jmp Mem::set_word
    ; [tail_jump]
.endproc


.proc write_d0l_mem8
    lda Reg::zbD0L
    jmp Mem::set_byte
    ; [tail_jump]
.endproc


.proc write_d0x_seg16
    ldy Decode::zbSeg
    ldx Reg::rzbaSegRegMap, y

    lda Reg::zwD0X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD0X+1
    sta Const::ZERO_PAGE+1, x

    jmp Interrupt::skip
    ; [tail_jump]
.endproc


.proc write_d0x_reg16_d1x_rm16
    jsr write_d1x_rm16
    jmp write_d0x_reg16
    ; [tail_jump]
.endproc


.proc write_d0l_reg8_d1l_rm8
    jsr write_d1l_rm8
    jmp write_d0l_reg8
    ; [tail_jump]
.endproc


.proc write_d0x_reg16_d1x_ax
    lda Reg::zwD1X
    sta Reg::zwAX
    lda Reg::zwD1X+1
    sta Reg::zwAX+1

    jmp write_d0x_reg16
    ; [tail_jump]
.endproc


.proc write_d0x_ds_d1x_reg16
    jsr write_d0x_reg16

    lda Reg::zwD1X
    sta Reg::zwDS
    lda Reg::zwD1X+1
    sta Reg::zwDS+1

    rts
.endproc


.proc write_d0x_es_d1x_reg16
    jsr write_d0x_reg16

    lda Reg::zwD1X
    sta Reg::zwES
    lda Reg::zwD1X+1
    sta Reg::zwES+1

    rts
.endproc


.proc write_d0l_ah
    lda Reg::zbD0L
    sta Reg::zbAH
    rts
.endproc


.proc write_d0x_flags
    lda Reg::zwD0X+1
    and #>Reg::FLAGS_MASK ; only set valid flags
    sta Reg::zwFlags+1
    ; [fall_through]
.endproc

.proc write_d0l_flags_lo
    lda Reg::zbD0L
    ; and <Reg::FLAGS_MASK ; only set valid flags
    and #<(Reg::FLAG_SF | Reg::FLAG_ZF | Reg::FLAG_AF | Reg::FLAG_PF | Reg::FLAG_CF)
    sta Reg::zbFlagsLo
    rts
.endproc


.proc write_d0l_al_d1l_ah
    lda Reg::zbD0L
    sta Reg::zbAL
    lda Reg::zbD1L
    sta Reg::zbAH
    rts
.endproc


.proc write_d0x_ax_d1x_dx
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


.proc write_d0x_mem16_di
    lda Reg::zwD0X
    ldx Reg::zwD0X+1
    jmp Mem::set_di_word
    ; [tail_jump]
.endproc


.proc write_d0l_mem8_di
    lda Reg::zbD0L
    jmp Mem::set_di_byte
    ; [tail_jump]
.endproc


.proc write_nothing
    rts
.endproc


.proc write_bad
    lda #X86::eErr::WRITE_FUNC
    jmp X86::panic
    ; [tail_jump]
.endproc


; ==============================================================================
; extended instruction write functions
; ==============================================================================

.proc write_group1a
    lda Decode::zbExt
    cmp #7 ; CMP
    beq done
    jsr write_d0l_rm8
done:
    rts
.endproc


.proc write_group1b
    lda Decode::zbExt
    cmp #7 ; CMP
    beq done
    jsr write_d0x_rm16
done:
    rts
.endproc


.proc write_group3a
    lda Decode::zbExt
    lsr
    beq done ; branch if instruction is TEST or illegal.
    lsr
    bne done ; branch if instruction is MUL, IMUL, DIV, or IDIV.

    ; instruction is NOT or NEG
    jmp write_d0l_rm8

done:
    rts
.endproc


.proc write_group3b
    lda Decode::zbExt
    lsr
    beq done ; branch if instruction is TEST or illegal.
    lsr
    bne done ; branch if instruction is MUL, IMUL, DIV, or IDIV.

    ; instruction is NOT or NEG
    jmp write_d0x_rm16

done:
    rts
.endproc


.proc write_group4b
    lda Decode::zbExt
    lsr
    bne done ; branch if instruction is CALL, JMP, or PUSH
    ; instruction is INC or DEC
    jmp write_d0x_rm16
done:
    rts
.endproc


; ==============================================================================
; utility functions
; ==============================================================================

.proc write_d1x_rm16
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d1x_mem16

    ldy Decode::zbRM
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD1X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD1X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc


.proc write_d1l_rm8
    lda Decode::zbMod
    cmp #Decode::MODRM_MOD_REGISTER
    bne write_d1l_mem8

    ldy Decode::zbRM
    ldx Reg::rzbaReg8Map, y

    lda Reg::zbD1L
    sta Const::ZERO_PAGE, x

    rts
.endproc


.proc write_d1x_mem16
    lda Reg::zwD1X
    ldx Reg::zwD1X+1
    jmp Mem::set_word
    ; [tail_jump]
.endproc


.proc write_d1l_mem8
    lda Reg::zbD1L
    jmp Mem::set_byte
    ; [tail_jump]
.endproc


.proc write_d1x_reg16
    ldy Decode::zbReg
    ldx Reg::rzbaReg16Map, y

    lda Reg::zwD1X
    sta Const::ZERO_PAGE, x
    lda Reg::zwD1X+1
    sta Const::ZERO_PAGE+1, x

    rts
.endproc
