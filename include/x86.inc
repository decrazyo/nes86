
.ifndef _X86_
    _X86_ = 1

    .scope X86
        .importzp zbHalt

        .import x86
        .import step
        .import run
        .import panic

        .enum eErr
            FETCH_ERROR
            DECODE_ERROR
            EXECUTE_ERROR
            WRITE_ERROR
            IO_ERROR
            UNKNOWN_ERROR
            ERROR_COUNT
        .endenum

    .endscope

.endif
