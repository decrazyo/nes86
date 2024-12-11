
; this module handles the high level initialization of various components,
; performs some basic hardware tests,
; and passes off executions to the x86 emulator.

.include "apu.inc"
.include "chr.inc"
.include "keyboard.inc"
.include "main.inc"
.include "mmc5.inc"
.include "nmi.inc"
.include "ppu.inc"
.include "splash.inc"
.include "terminal.inc"
.include "x86.inc"

.export main

.segment "CODE"

.proc main
    ; initialize hardware
    jsr Apu::apu
    jsr Ppu::ppu

    ; initialize the splash screen
    jsr Splash::splash

    ; display static splash screen elements
    jsr Splash::nes86_logo
    jsr Splash::energy_logo
    .ifdef DEBUG
        jsr Splash::debug_string
    .endif
    jsr Splash::version_string
    jsr Splash::copyleft_string

    ; initialize the x86 emulator
    jsr Splash::processor_string
    jsr X86::x86
    jsr Splash::processor_8086

    ; clear PRG RAM in preparation for memory tests.
    ; this is also done in case the x86 software we're running doesn't clear its own RAM.
    jsr Splash::memory_test_string
    jsr Mmc5::clear_ram

    ; perform RAM test and report the results.
    jsr Splash::ram_string
    jsr Mmc5::test_ram
    bcc ram_test_pass
    jsr Splash::ram_fail
    jmp ram_test_done
ram_test_pass:
    jsr Splash::ram_pass
ram_test_done:

    ; perform ROM test and report the results.
    jsr Splash::rom_string
    jsr Mmc5::test_rom
    bcc rom_test_pass
    jsr Splash::rom_fail
    jmp rom_test_done
rom_test_pass:
    jsr Splash::rom_pass
rom_test_done:

    ; initialize a keyboard and report which driver was loaded.
    jsr Splash::keyboard_string
    jsr Keyboard::keyboard
    bcc family_basic_driver
    jsr Splash::keyboard_on_screen
    jmp keyboard_initialized
family_basic_driver:
    jsr Splash::keyboard_family_basic
keyboard_initialized:

    ; let the user know that we're ready to boot.
    ; i can't be bothered to implement different POST beep codes.
    jsr Apu::beep
    jsr Splash::boot_string


    ; keep the boot splash screen visible for a while.
    ldy #5 ; seconds to pause before booting
boot_delay:
    jsr Splash::boot_count

    ; TODO: detect 50Hz consoles and set this to 50
    ldx #60 ; frames to wait. about 1 second.
busy_wait:
    jsr Nmi::wait
    dex
    bne busy_wait

    ; the keyboard was scanned once per frame while we were waiting.
    ; read what the user typed.
read_keyboard:
    jsr Keyboard::get_key
    bcs keyboard_buffer_empty
    ; boot immediately if the user pressed enter.
    cmp #Chr::LF
    beq resume_boot
    bne read_keyboard

keyboard_buffer_empty:
    dey
    bne boot_delay
    jsr Splash::boot_count

resume_boot:
    ; flush the keyboard buffer in case the user typed something other than enter.
    jsr Keyboard::clear

    ; initialize the terminal.
    ; this should clear the boot splash.
    jsr Terminal::terminal

    ; send a single line feed to the terminal.
    ; some emulators don't show the first line or 2 of tiles.
    ; this will ensure that the boot text is visible.
    lda #Chr::LF
    jsr Terminal::put_char

    ; run the x86 emulator
    jmp X86::run
    ; [tail_jump]
.endproc
