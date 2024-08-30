
.ifndef _X86_
    _X86_ = 1

    .scope X86
        .importzp zbHalt

        .import x86
        .import step
        .import run
        .import panic

        .enum eErr
            REG_INDEX
            CODE_END
            FETCH_LEN
            FETCH_FUNC
            DECODE_FUNC
            EXECUTE_FUNC
            WRITE_FUNC
            MOD_RM
            IO_FUNC
            UNKNOWN
        .endenum

    .endscope

.endif
