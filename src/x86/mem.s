
.include "x86/mem.inc"
.include "x86/reg.inc"
.include "x86/execute.inc"
.include "x86.inc"

.include "const.inc"
.include "tmp.inc"
.include "mmc5.inc"
.include "nmi.inc"
.include "chr.inc"

.export mem

.export use_segment
.export use_pointer

.export get_ip_byte

.export pop_word
.export push_word

.export get_si_byte
.export get_si_word

.export get_di_byte
.export get_di_word

.export set_di_byte
.export set_di_word

.export get_byte
.export get_word

.export get_word_fast
.export get_dword_lo
.export get_dword_hi

.export set_byte
.export set_word

.exportzp zaSegment

.segment "ZEROPAGE"



; adjusted segment
zaSegment: .res 3
; pointer supplied by use_ptr
zwPointer: .res 2

zpAddress:
zbAddressLo: .res 1
zbAddressHi: .res 1
zbBank: .res 1

.segment "CODE"

; =============================================================================
; high level public memory interface
; =============================================================================

.proc mem
    rts
.endproc


; read value from a segment register
; shift the value left 4 bits
; store it for later
; we'll use the MMC5's multiplier since it's faster than actually shifting.
; < X = zero-page address of a segment register
.proc use_segment
    lda Const::ZERO_PAGE, x
    sta Mmc5::MULT_LO
    lda #16
    sta Mmc5::MULT_HI

    lda Mmc5::MULT_LO
    sta zaSegment
    lda Mmc5::MULT_HI
    sta zaSegment+1

    lda Const::ZERO_PAGE+1, x
    sta Mmc5::MULT_LO
    lda #16
    sta Mmc5::MULT_HI

    lda Mmc5::MULT_LO
    ora zaSegment+1
    sta zaSegment+1
    lda Mmc5::MULT_HI
    sta zaSegment+2
    rts
.endproc


; copy the pointer pointer
; store address of the pointer
.proc use_pointer
    sta zwPointer
    stx zwPointer+1
    rts
.endproc

; ------------------------------------
; instruction pointer memory access
; ------------------------------------

.proc get_ip_byte
    ; initialize offsets
    ldx #Reg::zwIP
    ldy #0

    ; get a byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y
    rts
.endproc

; ------------------------------------
; stack memory access
; ------------------------------------

.proc pop_word
    ; initialize offsets
    ldx #Reg::zwSP
    ldy #0


    ; pop the low byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y
    pha

    ; pop the high byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y

    tax
    pla
    rts
.endproc


.proc push_word
    ; temporarily store the word we need to push
    pha
    stx Tmp::zb3

    ; initialize offsets
    ldx #Reg::zwSP
    ldy #0

    ; push the high byte
    jsr dec_pointer
    jsr set_address
    lda Tmp::zb3
    sta (zpAddress), y

    ; push the low byte
    jsr dec_pointer
    jsr set_address
    pla
    sta (zpAddress), y
    rts
.endproc

; ------------------------------------
; string memory access
; ------------------------------------

.proc get_si_byte
    ; initialize offset
    ldx #Reg::zwSI
    bne get_str_byte ; branch always
    ; [tail_branch]
.endproc


.proc get_di_byte
    ; initialize offset
    ldx #Reg::zwDI
    ; [fall_through]
.endproc

.proc get_str_byte
    ; initialize offset
    ldy #0

    ; get a byte
    jsr set_address
    jsr dir_pointer
    lda (zpAddress), y
    rts
.endproc


.proc get_si_word
    ; initialize offset
    ldx #Reg::zwSI
    bne get_str_word ; branch always
    ; [tail_branch]
.endproc


.proc get_di_word
    ; initialize offset
    ldx #Reg::zwDI
    ; [fall_through]
.endproc

.proc get_str_word
    ; initialize offset
    ldy #0

    ; determine if we're reading the string forward or backward.
    jsr Execute::get_direction_flag
    bne backward

    ; get the low byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y
    pha

    ; get the high byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y

    tax
    pla
    rts

backward:
    ; get the high byte
    jsr inc_pointer
    jsr set_address
    lda (zpAddress), y
    sta Tmp::zb3

    ; get the low byte
    jsr dec_pointer
    jsr set_address
    jsr dec_pointer
    jsr dec_pointer
    lda (zpAddress), y

    ldx Tmp::zb3
    rts
.endproc


.proc set_di_byte
    ; temporarily store the byte we need to set
    pha

    ; initialize offsets
    ldx #Reg::zwDI
    ldy #0

    ; push the high byte
    jsr set_address
    jsr dir_pointer
    pla
    sta (zpAddress), y
    rts
.endproc


.proc set_di_word
    ; temporarily store the word we need to set
    pha
    stx Tmp::zb3

    ; initialize offsets
    ldx #Reg::zwDI
    ldy #0

    ; determine if we're writing the string forward or backward.
    jsr Execute::get_direction_flag
    bne backward

    ; get the low byte
    jsr set_address
    jsr inc_pointer
    pla
    sta (zpAddress), y

    ; get the high byte
    jsr set_address
    jsr inc_pointer
    lda Tmp::zb3
    sta (zpAddress), y
    rts

backward:
    ; get the high byte
    jsr inc_pointer
    jsr set_address
    lda Tmp::zb3
    sta (zpAddress), y

    ; get the low byte
    jsr dec_pointer
    jsr set_address
    jsr dec_pointer
    jsr dec_pointer
    pla
    sta (zpAddress), y
    rts
.endproc

; ------------------------------------
; general memory access
; ------------------------------------

.proc get_byte
    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; get a byte
    jsr set_address
    lda (zpAddress), y
    rts
.endproc


.proc get_word
    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; get the high byte
    jsr inc_pointer
    jsr set_address
    lda (zpAddress), y
    sta Tmp::zb3

    ; get the low byte
    jsr dec_pointer
    jsr set_address
    lda (zpAddress), y

    ldx Tmp::zb3
    rts
.endproc


get_word_fast:
.proc get_dword_lo
    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; get the low byte
    jsr set_address
    jsr inc_pointer
    lda (zpAddress), y
    pha

    ; get the high byte
    jsr set_address
    lda (zpAddress), y

    tax
    pla
    rts
.endproc


.proc get_dword_hi
    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; get the low byte
    jsr inc_pointer
    jsr set_address
    lda (zpAddress), y
    pha

    ; get the high byte
    jsr inc_pointer
    jsr set_address
    lda (zpAddress), y

    tax
    pla
    rts
.endproc


.proc set_byte
    ; temporarily store the byte we need to set
    pha

    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; set a byte
    jsr set_address
    pla
    sta (zpAddress), y
    rts
.endproc


.proc set_word
    ; temporarily store the word we need to set
    pha
    stx Tmp::zb3

    ; initialize offsets
    ldx #zwPointer
    ldy #0

    ; set the low byte
    jsr set_address
    pla
    sta (zpAddress), y

    ; set the high byte
    jsr inc_pointer
    jsr set_address
    lda Tmp::zb3
    sta (zpAddress), y
    rts
.endproc

; =============================================================================
; low level memory access and utility functions
; =============================================================================

; < X = zero-page address of a pointer
.proc set_address
    ; add the x86 pointer to the shifted x86 segment
    clc
    lda Const::ZERO_PAGE, x
    adc zaSegment
    sta zbAddressLo

    lda Const::ZERO_PAGE+1, x
    adc zaSegment+1
    sta zbAddressHi

    lda #0
    adc zaSegment+2
    sta zbBank

    ; we now have a 20-bit x86 address.
    ; we need to convert that address into an MMC5 bank number
    ; and a pointer to an MMC5 window in the 6502's address space.

    ; extract the highest 6 bits x86 address.
    ; this will become our MMC5 bank number.
    lda zbAddressHi
    asl
    rol zbBank
    asl
    rol zbBank
    asl zbBank

    ; adjust the remaining 14 bits of the x86 address.
    ; this will become our pointer to an MMC5 window.
    lsr
    lsr
    ; C was cleared by lsr
    adc #>Mmc5::WINDOW_1
    sta zbAddressHi

    ; RAM and ROM can share the same addresses in the MMC5.
    ; if we're accessing ROM then we need to adjust our bank number.

    ; check if we are accessing RAM or ROM.
    lda zbBank
    cmp #^(Mmc5::PRG_RAM_SIZE << 3)
    bcc select_bank ; branch if the address is in RAM

    ; the address is in ROM.
    ; adjusted the bank number to account for RAM addresses.
    ; C was set by cmp
    sbc #^(Mmc5::PRG_RAM_SIZE << 3)

    ; we may now be accessing the same address as some RAM.
    ; add a flag that tells the MMC5 to access ROM instead of RAM.
    ora #Mmc5::ROM

select_bank:
    sta Mmc5::WINDOW_1_CTRL
    rts
.endproc


.proc dir_pointer
    jsr Execute::get_direction_flag
    bne dec_pointer
    ; [tail_branch]
.endproc

.proc inc_pointer
    inc Const::ZERO_PAGE, x
    bne done ; branch if no carry is needed.
    inc Const::ZERO_PAGE+1, x
done:
    rts
.endproc


.proc dec_pointer
    lda Const::ZERO_PAGE, x
    bne done ; branch if no borrow is needed.
    dec Const::ZERO_PAGE+1, x
done:
    dec Const::ZERO_PAGE, x
    rts
.endproc
