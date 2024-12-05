
.include "header.inc"

.segment "HEADER"

; iNES/NES 2.0 file identifier
.byte 'N', 'E', 'S', $1A

.if Header::TYPE = Header::eType::INES
    .out "Using iNes header"

    .assert Header::PRG_ROM .mod $4000 = 0, error, "PRG_ROM must be a multiple of 16k"
    .assert Header::PRG_ROM / $4000 <= $ff, error, "PRG_ROM value is too large."
    .byte Header::PRG_ROM / $4000 & $ff

    .assert Header::CHR_ROM .mod $2000 = 0, error, "CHR_ROM must be a multiple of 8k."
    .assert Header::CHR_ROM / $2000 <= $ff, error, "CHR_ROM value is too large."
    .byte Header::CHR_ROM / $2000 & $ff

    .assert Header::MIRROR <= 1, error, "MIRROR must be 0 or 1."
    .assert Header::SRAM <= 1, error, "SRAM must be 0 or 1."
    .assert Header::TRAINER <= 1, error, "TRAINER must be 0 or 1."
    .assert Header::ALT_NAM <= 1, error, "ALT_NAM must be 0 or 1."
    .assert Header::MAPPER <= $ff, error, "MAPPER value is too large."
    MIRROR = Header::MIRROR
    SRAM = Header::SRAM << 1
    TRAINER = Header::TRAINER << 2
    ALT_NAM = Header::ALT_NAM << 3
    MAPPER = Header::MAPPER & $0f << 4
    .byte MAPPER | ALT_NAM | TRAINER | SRAM | MIRROR

    .assert Header::CONSOLE <= 2, error, "CONSOLE value is too large."
    .byte Header::MAPPER & $f0 | Header::CONSOLE

    .assert Header::PRG_RAM .mod $2000 = 0, "PRG_RAM must be a multiple of 8k."
    .assert Header::PRG_RAM / $2000 <= $ff, error, "PRG_RAM value is too large."
    .byte Header::PRG_RAM / $2000 & $ff

    .assert Header::TIMING <= 1, error, "TIMING value is too large."
    .byte Header::TIMING

    ; the linker will fill the rest of the header with zeros for us.
.elseif Header::TYPE = Header::eType::NES2
    .out "Using NES 2.0 header"

    ; TODO: add exponent-multiplier notation support for PRG_ROM and CHR_ROM.
    .assert Header::PRG_ROM .mod $4000 = 0, error, "PRG_ROM must be a multiple of 16k"
    .assert Header::PRG_ROM / $4000 <= $eff, error, "PRG_ROM value is too large."
    PRG_ROM = Header::PRG_ROM / $4000
    .byte PRG_ROM & $ff

    .assert Header::CHR_ROM .mod $2000 = 0, error, "CHR_ROM must be a multiple of 8k"
    .assert Header::CHR_ROM / $2000 <= $eff, error, "CHR_ROM value is too large."
    CHR_ROM = Header::CHR_ROM / $2000
    .byte CHR_ROM & $ff

    .assert Header::MIRROR <= 1, error, "MIRROR must be 0 or 1."
    .assert Header::SRAM <= 1, error, "SRAM must be 0 or 1."
    .assert Header::TRAINER <= 1, error, "TRAINER must be 0 or 1."
    .assert Header::ALT_NAM <= 1, error, "ALT_NAM must be 0 or 1."
    .assert Header::MAPPER <= $fff, error, "MAPPER value is too large."
    MIRROR = Header::MIRROR
    SRAM = Header::SRAM << 1
    TRAINER = Header::TRAINER << 2
    ALT_NAM = Header::ALT_NAM << 3
    MAPPER = Header::MAPPER & $0f << 4
    .byte MAPPER | ALT_NAM | TRAINER | SRAM | MIRROR

    .assert Header::CONSOLE <= 3, error, "CONSOLE value is too large."
    NES2 = (2 << 2) ; NES 2.0 identifier
    .byte Header::MAPPER & $f0 | NES2 | Header::CONSOLE

    .assert Header::SUBMAPPER <= 15, error, "SUBMAPPER value is too large."
    .byte Header::SUBMAPPER << 4 | Header::MAPPER >> 8

    .byte CHR_ROM & $f00 >> 4 | PRG_ROM >> 8

    prg_ram_power .set -1
    bytes_to_power Header::PRG_RAM, prg_ram_power
    prg_nvram_power .set -1
    bytes_to_power Header::PRG_NVRAM, prg_nvram_power
    .byte prg_nvram_power << 4 | prg_ram_power

    chr_ram_power .set -1
    bytes_to_power Header::CHR_RAM, chr_ram_power
    chr_nvram_power .set -1
    bytes_to_power Header::CHR_NVRAM, chr_nvram_power
    .byte chr_nvram_power << 4 | chr_ram_power

    .assert Header::TIMING <= 3, error, "TIMING value is too large."
    .byte Header::TIMING

    ; we're not doing anything that would require these settings.
    .byte $00 ; Vs. System / extended console
    .byte $00 ; miscellaneous ROMs

    .assert Header::DEVICE <= $3e, error, "DEVICE value is too large."
    .byte Header::DEVICE
.else
    .error "Unknown header type."
.endif
