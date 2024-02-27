
.ifndef _X86_
.define _X86_

.scope X86
    .import x86
    .import step
    .import run
    .import panic

    .enum Err
        REG_INDEX
        CODE_END
        FETCH_BAD
        FETCH_LEN
        DECODE_FUNC
        EXECUTE_BAD
        EXECUTE_FUNC
        WRITE_FUNC
        UNKNOWN
    .endenum

    .ifdef DEBUG
    .import debug_x86
    .endif
.endscope

.endif
