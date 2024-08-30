
.ifndef _CHR_
    _CHR_ = 1

    .scope Chr
        NUL = $00 ; null character.
        SOH = $01 ; start of heading.
        ; STX = $02 ; start of text. conflicts with 6502 assembly mnemonic.
        ETX = $03 ; end of text.
        EOT = $04 ; end of transmission.
        ENQ = $05 ; enquiry.
        ACK = $06 ; acknowledge.
        BEL = $07 ; bell.
        BS = $08  ; backspace.
        HT = $09  ; horizontal tab.
        LF = $0A  ; new line.
        VT = $0B  ; vertical tab.
        FF = $0C  ; form feed.
        CR = $0D  ; carriage ret.
        SO = $0E  ; shift out.
        SI = $0F  ; shift in.
        DLE = $10 ; data link escape.
        DC1 = $11 ; device control 1.
        DC2 = $12 ; device control 2.
        DC3 = $13 ; device control 3.
        DC4 = $14 ; device control 4.
        NAK = $15 ; negative ack.
        SYN = $16 ; synchronous idle.
        ETB = $17 ; end of trans. blk.
        CAN = $18 ; cancel.
        EM = $19  ; end of medium.
        SUB = $1A ; substitute.
        ESC = $1B ; escape.
        FS = $1C  ; file separator.
        GS = $1D  ; group separator.
        RS = $1E  ; record separator.
        US = $1F  ; unit separator.

        ; using this constant makes code a little easier to read in my opinion.
        SPACE = ' '

        DEL = $7f ; delete

        NULL = $00
        NEW_LINE = $0a
        BLANK_TILE = <-1

    .endscope

.endif
