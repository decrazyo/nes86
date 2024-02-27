
.ifndef _X86_
.define _X86_

.scope X86
    .import x86
    .import step
    .import run
    .import panic

    .enum Err
        REG
        MMU
        FETCH
        DECODE
        EXECUTE
        WRITE
        UNKNOWN
    .endenum

    .ifdef DEBUG
    .import debug_x86
    .endif
.endscope

.endif
