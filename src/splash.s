
; this module is responsible for drawing the boot splash screen text and graphics.
; this was done to keep the boot code, in main.s, from getting over-complicated.
; the code in this module spends a lot of time waiting for NMI
; to make sure that the boot splash screen looks nice as it renders.
; this early in the boot process we don't really care about wasting cycles.
; each string or graphic has its own exported function.
; that's a bit excessive but it makes it easy to change the way the boot splash screen renders.

.include "nmi.inc"
.include "ppu.inc"
.include "splash.inc"

.export splash

.export nes86_logo
.export energy_logo

.export debug_string

.export version_string

.export copyleft_string

.export processor_string
.export processor_8086

.export memory_test_string

.export ram_string
.export ram_pass
.export ram_fail

.export rom_string
.export rom_pass
.export rom_fail

.export keyboard_string
.export keyboard_on_screen
.export keyboard_family_basic

.export boot_string
.export boot_count

; convert an onscreen (x, y) tile position to a PPU address.
; < x_pos = x position
; < y_pos = y position
.define X_Y_POS_TO_PPU_ADDR(x_pos, y_pos) $2000 + 32 * y_pos + x_pos

; convert a label address to a raSplashStrings table offset.
; < label = string label between raSplashStrings and raSplashStringsEnd
.define STRING_OFFSET(label) <(label - raSplashStrings)

; convert a label address to a raSplashStringsAddr table offset.
; < label = string address label between raSplashStringsAddr and raSplashStringsAddrEnd
.define STRING_ADDRESS_OFFSET(label) <(label - raSplashStringsAddr)

.segment "RODATA"

; splash screen pallet data.
; pallet data may contain NULL bytes so we can't define this as a string.
; we're using magenta to indicate unused colors.
rbaPallets:
; normal white on black text colors
; also used for inverted colors
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::WHITE,       Ppu::eColor::MAGENTA
; "NES86" has white text with a red "86"
.byte Ppu::eColor::BLACK, Ppu::eColor::WHITE, Ppu::eColor::RED,         Ppu::eColor::BLACK
; "energy" graphic should appear yellow
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::BLACK,       Ppu::eColor::PALE_YELLOW
; "inefficient" text should appear green
.byte Ppu::eColor::BLACK, Ppu::eColor::BLACK, Ppu::eColor::LIGHT_GREEN, Ppu::eColor::MAGENTA
rbaPalletsEnd:

; ==============================================================================
; string table
; ==============================================================================

; table of splash screen string data.
; where a string is considered to be any sequence of non-NULL bytes followed by a NULL byte
raSplashStrings:

; pallet attributes for splash screen graphics
; .byte (bottomright << 6) | (bottomleft << 4) | (topright << 2) | (topleft << 0)

; NES86 logo attributes
rsNes86Attr:
.byte (1 << 6) | (1 << 4) | (1 << 2) | (1 << 0)
.byte $00

; "energy inefficient" attributes
rsEnergyAttr0:
.byte (2 << 6) | (0 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte (2 << 6) | (2 << 4) | (0 << 2) | (0 << 0)
.byte $00
rsEnergyAttr1:
.byte (3 << 6) | (0 << 4) | (2 << 2) | (0 << 0)
.byte (3 << 6) | (3 << 4) | (2 << 2) | (2 << 0)
.byte (3 << 6) | (3 << 4) | (2 << 2) | (2 << 0)
.byte (0 << 6) | (3 << 4) | (0 << 2) | (2 << 0)
.byte $00

; the CHR ROM area that maps to control characters is used for boot splash graphics.

; NES86 logo
rsNes86Upper:
.byte "N", "E", $13, $17, $18, $00
rsNes86Lower:
.byte $03, $04, $05, $00

; cursive "energy" graphic
rsEnergy0:
.byte      $01, $02, $20, $20, $03, $04, $05, $06, $07, $08, $00
rsEnergy1:
.byte $09, $0a, $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13, $00
rsEnergy2:
.byte $14, $15, $16, $17, $18, $20, $19, $1a, $1b, $1c, $00
rsEnergy3:
.byte                               $1d, $20, $1e, $00

rsInefficient:
.asciiz "INEFFICIENT"

rsDebug:
.asciiz "DEBUG BUILD"

rsVersion:
.if .defined(MAJOR_VERSION) .and .defined(MINOR_VERSION)
    .asciiz "Version ", .sprintf("%i.%i", MAJOR_VERSION, MINOR_VERSION)
.else
    .warning "no version specified"
    .asciiz "Version unknown"
.endif

; $1f is a backwards "C"
rsCopyleft:
.byte "Copyleft (", $1f, ") 2024, Decrazyo", $00

rsProcessor:
.define PROCESSOR_STRING "Processor: "
.asciiz PROCESSOR_STRING
rs8086:
.asciiz "8086"

rsMemory:
.asciiz "Memory test: "
rsRam:
.define RAM_STRING "RAM: "
.asciiz RAM_STRING
rsRom:
.define ROM_STRING "ROM: "
.asciiz ROM_STRING
rsPass:
.asciiz "PASS"
rsFail:
.asciiz "FAIL"

rsKeyboard:
.define KEYBOARD_STRING "Keyboard: "
.asciiz "Keyboard: "

rsFamilyBasic:
.asciiz "Family BASIC"
rsOnScreen:
.asciiz "On screen"

rsBoot:
.define BOOT_STRING "Press ENTER to boot ( )"
.asciiz BOOT_STRING
BOOT_STRING_ADDR = X_Y_POS_TO_PPU_ADDR 2, 27
BOOT_COUNT_ADDR = BOOT_STRING_ADDR + .strlen(BOOT_STRING) - 2
raSplashStringsEnd:

SPLASH_STRING_BYTES = raSplashStringsEnd - raSplashStrings
.assert SPLASH_STRING_BYTES <= 256, error, "splash screen string data is too large"

; ==============================================================================
; string address table
; ==============================================================================

raSplashStringsAddr:
rNes86AttrAddr:
.word X_Y_POS_TO_PPU_ADDR 1, 30
.byte STRING_OFFSET rsNes86Attr
rEnergyAttr0Addr:
.word X_Y_POS_TO_PPU_ADDR 4, 30
.byte STRING_OFFSET rsEnergyAttr0
rEnergyAttr1Addr:
.word X_Y_POS_TO_PPU_ADDR 12, 30
.byte STRING_OFFSET rsEnergyAttr1

rNes86UpperAddr:
.word X_Y_POS_TO_PPU_ADDR 2, 2
.byte STRING_OFFSET rsNes86Upper
rNes86LowerAddr:
.word X_Y_POS_TO_PPU_ADDR 4, 3
.byte STRING_OFFSET rsNes86Lower

rEnergy0Addr:
.word X_Y_POS_TO_PPU_ADDR 20, 2
.byte STRING_OFFSET rsEnergy0
rEnergy1Addr:
.word X_Y_POS_TO_PPU_ADDR 19, 3
.byte STRING_OFFSET rsEnergy1
rEnergy2Addr:
.word X_Y_POS_TO_PPU_ADDR 19, 4
.byte STRING_OFFSET rsEnergy2
rEnergy3Addr:
.word X_Y_POS_TO_PPU_ADDR 25, 5
.byte STRING_OFFSET rsEnergy3

rInefficientAddr:
.word X_Y_POS_TO_PPU_ADDR 19, 6
.byte STRING_OFFSET rsInefficient

rDebugAddr:
.word X_Y_POS_TO_PPU_ADDR 2, 8
.byte STRING_OFFSET rsDebug

rVersionAddr:
.word X_Y_POS_TO_PPU_ADDR 2, 10
.byte STRING_OFFSET rsVersion

rCopyleftAddr:
.word X_Y_POS_TO_PPU_ADDR 2, 12
.byte STRING_OFFSET rsCopyleft

rProcessorAddr:
PROCESSOR_X = 2
PROCESSOR_Y = 16
.word X_Y_POS_TO_PPU_ADDR PROCESSOR_X, PROCESSOR_Y
.byte STRING_OFFSET rsProcessor

r8086Addr:
.word X_Y_POS_TO_PPU_ADDR PROCESSOR_X + .strlen(PROCESSOR_STRING), PROCESSOR_Y
.byte STRING_OFFSET rs8086

rMemoryAddr:
MEMORY_X = 2
MEMORY_Y = 18
.word X_Y_POS_TO_PPU_ADDR MEMORY_X, MEMORY_Y
.byte STRING_OFFSET rsMemory

rRamAddr:
RAM_X = MEMORY_X + 2
RAM_Y = MEMORY_Y + 1
.word X_Y_POS_TO_PPU_ADDR RAM_X, RAM_Y
.byte STRING_OFFSET rsRam
rRamPassAddr:
.word X_Y_POS_TO_PPU_ADDR RAM_X + .strlen(RAM_STRING) , RAM_Y
.byte STRING_OFFSET rsPass
rRamFailAddr:
.word X_Y_POS_TO_PPU_ADDR RAM_X + .strlen(RAM_STRING) , RAM_Y
.byte STRING_OFFSET rsFail

rRomAddr:
ROM_X = MEMORY_X + 2
ROM_Y = MEMORY_Y + 2
.word X_Y_POS_TO_PPU_ADDR ROM_X, ROM_Y
.byte STRING_OFFSET rsRom
rRomPassAddr:
.word X_Y_POS_TO_PPU_ADDR ROM_X + .strlen(ROM_STRING) , ROM_Y
.byte STRING_OFFSET rsPass
rRomFailAddr:
.word X_Y_POS_TO_PPU_ADDR ROM_X + .strlen(ROM_STRING) , ROM_Y
.byte STRING_OFFSET rsFail

rKeyboardAddr:
KEYBOARD_X = 2
KEYBOARD_Y = 22
.word X_Y_POS_TO_PPU_ADDR KEYBOARD_X, KEYBOARD_Y
.byte STRING_OFFSET rsKeyboard
rFamilyBasicAddr:
.word X_Y_POS_TO_PPU_ADDR KEYBOARD_X + .strlen(KEYBOARD_STRING), KEYBOARD_Y
.byte STRING_OFFSET rsFamilyBasic
rOnScreenAddr:
.word X_Y_POS_TO_PPU_ADDR KEYBOARD_X + .strlen(KEYBOARD_STRING), KEYBOARD_Y
.byte STRING_OFFSET rsOnScreen

rBootAddr:
.word BOOT_STRING_ADDR
.byte STRING_OFFSET rsBoot
raSplashStringsAddrEnd:

STRING_ADDR_BYTES = raSplashStringsAddrEnd - raSplashStringsAddr
.assert STRING_ADDR_BYTES <= 256, error, "splash screen string address data is too large"

.segment "CODE"

; ==============================================================================
; public interface
; ==============================================================================

; initialize the boot splash pallets.
; changes: A, X. Y
.proc splash
    ; initialize pallet data
    lda #<Ppu::BACKGROUND_PALLET_ADDR
    ldx #>Ppu::BACKGROUND_PALLET_ADDR
    jsr Ppu::initialize_write

    ldy #0
loop:
    lda rbaPallets, y
    jsr Ppu::write_bytes
    iny
    cpy #<(rbaPalletsEnd - rbaPallets)
    bcc loop

    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc


; render the NES86 logo
; changes: A, X, Y
.proc nes86_logo
    jsr Nmi::wait

    ldy #STRING_ADDRESS_OFFSET rNes86AttrAddr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rNes86UpperAddr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rNes86LowerAddr
    jsr buffer_rom_string

    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "energy inefficient" logo.
; changes: A, X, Y
.proc energy_logo
    jsr Nmi::wait

    ldy #STRING_ADDRESS_OFFSET rEnergyAttr0Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rEnergyAttr1Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rEnergy0Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rEnergy1Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rEnergy2Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rEnergy3Addr
    jsr buffer_rom_string

    ldy #STRING_ADDRESS_OFFSET rInefficientAddr
    jsr buffer_rom_string

    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "DEBUG BUILD" string.
; changes: A, X, Y
.proc debug_string
    ldy #STRING_ADDRESS_OFFSET rDebugAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the version string.
; changes: A, X, Y
.proc version_string
    ldy #STRING_ADDRESS_OFFSET rVersionAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the copyleft string.
; changes: A, X, Y
.proc copyleft_string
    ldy #STRING_ADDRESS_OFFSET rCopyleftAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "Processor:" string.
; changes: A, X, Y
.proc processor_string
    ldy #STRING_ADDRESS_OFFSET rProcessorAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "8086" string following the "Processor:" string.
; changes: A, X, Y
.proc processor_8086
    ldy #STRING_ADDRESS_OFFSET r8086Addr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "Memory test:" string.
; changes: A, X, Y
.proc memory_test_string
    ldy #STRING_ADDRESS_OFFSET rMemoryAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "RAM:" string following the "Memory test:" string.
; changes: A, X, Y
.proc ram_string
    ldy #STRING_ADDRESS_OFFSET rRamAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "PASS" string following the "RAM:" string.
; changes: A, X, Y
.proc ram_pass
    ldy #STRING_ADDRESS_OFFSET rRamPassAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "FAIL" string following the "RAM:" string.
; changes: A, X, Y
.proc ram_fail
    ldy #STRING_ADDRESS_OFFSET rRamFailAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "ROM:" string following the "Memory test:" string.
; changes: A, X, Y
.proc rom_string
    ldy #STRING_ADDRESS_OFFSET rRomAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "PASS" string following the "ROM:" string.
; changes: A, X, Y
.proc rom_pass
    ldy #STRING_ADDRESS_OFFSET rRomPassAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "FAIL" string following the "ROM:" string.
; changes: A, X, Y
.proc rom_fail
    ldy #STRING_ADDRESS_OFFSET rRomFailAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "Keyboard:" string.
; changes: A, X, Y
.proc keyboard_string
    ldy #STRING_ADDRESS_OFFSET rKeyboardAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "On screen" string following the "Keyboard:" string.
; changes: A, X, Y
.proc keyboard_on_screen
    ldy #STRING_ADDRESS_OFFSET rOnScreenAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "Family BASIC" string following the "Keyboard:" string.
; changes: A, X, Y
.proc keyboard_family_basic
    ldy #STRING_ADDRESS_OFFSET rFamilyBasicAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render the "Press ENTER to boot" string.
; changes: A, X, Y
.proc boot_string
    ldy #STRING_ADDRESS_OFFSET rBootAddr
    jsr buffer_rom_string
    jmp Nmi::wait
    ; [tail_jump]
.endproc


; render a digit following the "Press ENTER to boot" string.
; < Y = integer in the range [0, 9] to render as an ASCII digit.
; changes: A, X
.proc boot_count
    lda #<BOOT_COUNT_ADDR
    ldx #>BOOT_COUNT_ADDR
    jsr Ppu::initialize_write

    ; convert the integer to ASCII.
    tya
    clc
    adc #$30
    jmp Ppu::write_byte
    ; [tail_jump]
.endproc


; ==============================================================================
; private interface
; ==============================================================================

; buffer a string to be sent to the PPU during the next NMI.
; the string and its intended PPU address is provided by the raSplashStringsAddr table.
; < Y = raSplashStringsAddr offset
; changes: A, X, Y
.proc buffer_rom_string
    ; NOTE: consider using a struct when accessing raSplashStringsAddr.

    ; get the PPU address to write data to.
    lda raSplashStringsAddr, y
    ldx raSplashStringsAddr+1, y
    ; initialize a buffer for that address.
    jsr Ppu::initialize_write

    ; get the offset of a string to write to the PPU.
    lda raSplashStringsAddr+2, y
    tay

    ; account for zero-length strings.
    ; we shouldn't have any of those but it doesn't hurt to check.
    lda raSplashStrings, y
    beq copy_done
    ; copy the string to the PPU buffer.
copy_string:
    jsr Ppu::write_bytes
    iny
    lda raSplashStrings, y
    ; check for null terminator.
    bne copy_string
copy_done:

    ; close the buffer.
    jmp Ppu::finalize_write
    ; [tail_jump]
.endproc
