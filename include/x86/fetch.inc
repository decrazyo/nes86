
.ifndef _X86_FETCH_
_X86_FETCH_ = 1

.scope Fetch

    BUFFER_LEN = 6

    .importzp zbPrefixSegment
    .importzp zbPrefixRepeat
    .importzp zbPrefixLock

    .importzp zbInstrLen
    .importzp zbInstrBuffer
    .importzp zbInstrOpcode
    .importzp zaInstrOperands

    .import fetch

    .ifdef DEBUG
    .import debug_fetch
    .endif
.endscope

.endif
