
.ifndef _X86_
_X86_ = 1

.scope X86
    .import x86
    .import step
    .import run
    .import panic

    .enum Err
        REG_INDEX
        CODE_END
        FETCH_LEN
        FETCH_FUNC
        DECODE_FUNC
        EXECUTE_FUNC
        WRITE_FUNC
        MOD_RM
        UNKNOWN
    .endenum

    .ifdef DEBUG
    .import debug_x86
    .endif
.endscope

.endif
