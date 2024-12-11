
.ifndef _HEADER_
    _HEADER_ = 1

    .scope Header

        ; using one-based indexing since it will be more understandable in the Makefile.
        .enum eType
            INES = 1
            NES2 = 2
        .endenum

        ; type of ROM file header to use
        ; https://www.nesdev.org/wiki/INES
        ; https://www.nesdev.org/wiki/NES_2.0
        .ifndef HEADER_TYPE
            HEADER_TYPE = eType::NES2
        .endif

        ; common iNes/NES 2.0 header settings

        ; PRG ROM in bytes
        .ifndef PRG_ROM
            PRG_ROM = $100000
        .endif

        ; CHR ROM in bytes
        .ifndef CHR_ROM
            CHR_ROM = $2000
        .endif

        ; PRG RAM in bytes
        .ifndef PRG_RAM
            PRG_RAM = $20000
        .endif

        ; most emulators need the SRAM flag to be 0.
        ; the ksNes emulator needs it to be 1 since it only supports SRAM, not PRG RAM
        .ifndef SRAM
            SRAM  = 0       ; 1 = battery backed save RAM at $6000-7FFF
        .endif

        MIRROR    = 1       ; 0 = horizontal
                            ; 1 = vertical
        TRAINER   = 0       ; 1 = 512-byte trainer data
        ALT_NAM   = 0       ; 1 = alternative nametable layout
        MAPPER    = 5       ; 5 = MMC5
        CONSOLE   = 0       ; 0 = NES/Famicom
                            ; 1 = Vs. System
                            ; 2 = Playchoice 10
                            ; 3 = extended console type (NES 2.0 header only)
        TIMING    = 0       ; 0: NTSC NES
                            ; 1: PAL NES
                            ; 2: Multi-region (NES 2.0 header only)
                            ; 3: Dendy (NES 2.0 header only)

        ; exclusive NES 2.0 header settings
        PRG_NVRAM = 0       ; PRG NVRAM in bytes
        CHR_RAM   = 0       ; CHR RAM in bytes
        CHR_NVRAM = 0       ; CHR NVRAM in bytes

        SUBMAPPER = 0       ; mapper variant
        DEVICE    = $23     ; default expansion device
                            ; $00 = None
                            ; $23 = Family BASIC Keyboard

        ; NES 2.0 headers represent some numbers as 64 times a power of 2.
        ; this macro will convert a number in bytes to that power.
        ; < bytes = size of a memory region measured in bytes.
        ; > power = power of 2 times 64 that equals the specified number of bytes.
        ;           if bytes is 0 then power will be 0.
        ;           if bytes is an invalid number then power will be -1.
        .macro bytes_to_power bytes, power
            .local bytes
            .local power
            .local count

            power .set -1

            .if bytes = 0
                power .set 0
            .else
                .repeat 15, count
                    .if bytes = 64 << (count + 1)
                        power .set (count + 1)
                    .endif
                .endrepeat

                .if power = -1
                    .error "cannot convert bytes to power of 2 times 64"
                .endif
            .endif
        .endmacro

    .endscope

.endif
