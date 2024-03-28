
.ifndef _X86_FETCH_
_X86_FETCH_ = 1

.scope Fetch

    .importzp zbPrefixSegment
    .importzp zbPrefixOther

    .importzp zbInstrLen
    .importzp zbInstrBuffer
    .importzp zbInstrOpcode
    .importzp zaInstrOperands

    .import fetch

.endscope

.endif
