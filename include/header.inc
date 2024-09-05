
.ifndef _HEADER_
    _HEADER_ = 1

    .scope Header

        ; define this to use the NES 2.0 style header
        USE_NES2 = 1

        .scope Ines
            PRG_ROM = 64 ; number of 16k PRG ROM chunks (1024k)
            CHR_ROM = 1  ; number of 8k CHR ROM chunks
            MIRROR  = 1  ; 0 = horizontal, 1 = vertical
            SRAM    = 0  ; 1 = battery backed save RAM at $6000-7FFF
            TRAINER = 0  ; 1 = 512-byte trainer data
            ALT     = 0  ; 1 = alternative nametable layout
            MAPPER  = 5  ; 5 = MMC5
            CONSOLE = 0  ; 0 = NES/Famicom
                         ; 1 = Vs. System
                         ; 2 = Playchoice 10
                         ; 3 = extended console type
        .endscope

        .scope Nes2
            PRG_RAM   = 11  ; (64 << n) byte of PRG RAM (128k)
            PRG_NVRAM = 0   ; (64 << n) byte of PRG NVRAM
            CHR_RAM   = 0   ; (64 << n) byte of CHR RAM
            CHR_NVRAM = 0   ; (64 << n) byte of CHR NVRAM
            TIMING    = 2   ; 0: NTSC NES
                            ; 1: PAL NES
                            ; 2: Multi-region
                            ; 3: Dendy
            ; EXP_DEV   = $00 ; default expansion device
            EXP_DEV   = $23 ; default expansion device
                            ; $00 = None
                            ; $23 = Family BASIC Keyboard
        .endscope

    .endscope

.endif
