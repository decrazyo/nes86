
.include "con.inc"
.include "chr.inc"
.include "const.inc"
.include "nmi.inc"
.include "ppu.inc"
.include "tmp.inc"

.export con

.export csr_home

.export print_chr
.export print_str

.export print_hex
.export print_hex_arr
.export print_hex_arr_rev

.export print_bin
; .export print_bin_arr
; .export print_bin_arr_rev

.segment "ZEROPAGE"

zbCursorX: .res 1
zbCursorY: .res 1

; TODO: implement scrolling
;zbScroll: .res 1

.segment "CODE"

; ==============================================================================
; public functions
; ==============================================================================

; initialize the console
.proc con
    jmp Ppu::ppu
    ; jsr rts -> jmp
.endproc


; move the cursor to the upper left corner of the screen
; changes: A
.proc csr_home
    lda #0
    sta zbCursorX
    sta zbCursorY
    rts
.endproc


; print a single character to the screen.
; < A = char to print
.proc print_chr
    sta Tmp::zb1
    jsr csr_to_addr
    jsr Nmi::write_addr

    lda Tmp::zb1
    jsr pur_char

    jsr Nmi::write_done
    rts
.endproc


; print a C string to the screen.
; < Tmp::zw0 = pointer to a C string.
.proc print_str
    jsr csr_to_addr
    jsr Nmi::write_addr

    ldy #0
loop:
    lda (Tmp::zw0), y
    cmp #0
    beq done
    iny
    jsr pur_char
    jmp loop
done:
    jsr Nmi::write_done
    rts
.endproc

; print a single byte in hex.
; < A = byte to print
.proc print_hex
    sta Tmp::zb1
    jsr csr_to_addr
    jsr Nmi::write_addr

    lda Tmp::zb1
    jsr print_nibble_hi

    lda Tmp::zb1
    jsr print_nibble_lo

    jsr Nmi::write_done
    rts
.endproc

; print an array of bytes as hex digits.
; < Tmp::zw0 = pointer to an array.
; < Y length of the array
.proc print_hex_arr
    ; this should all work as long as we don't change pur_char to use Y too much.
    jsr csr_to_addr
    sty Tmp::zb3 ; must do this after csr_to_addr
    jsr Nmi::write_addr

    ldy #0
    beq start
loop:
    lda (Tmp::zw0), y
    jsr print_nibble_hi
    lda (Tmp::zw0), y
    jsr print_nibble_lo
    iny
start:
    cpy Tmp::zb3
    bcc loop

    jsr Nmi::write_done
    rts
.endproc

; print an array of bytes as hex digits in reverse.
; < Tmp::zw0 = pointer to an array.
; < Y length of the array
.proc print_hex_arr_rev
    ; this should all work as long as we don't change pur_char to use Y too much.
    jsr csr_to_addr
    sty Tmp::zb3 ; must do this after csr_to_addr
    jsr Nmi::write_addr

    ldy Tmp::zb3
    beq done
    dey
loop:
    lda (Tmp::zw0), y
    jsr print_nibble_hi
    lda (Tmp::zw0), y
    jsr print_nibble_lo
    dey
    bpl loop

done:
    jsr Nmi::write_done
    rts
.endproc

; print a single byte in binary.
; < A = byte to print
.proc print_bin
    sta Tmp::zb1
    jsr csr_to_addr
    jsr Nmi::write_addr

    ldy #8
loop:
    rol Tmp::zb1
    bcs one
    lda #$30
    SKIP_WORD
one:
    lda #$31
    jsr pur_char
    dey
    bne loop

    jsr Nmi::write_done
    rts
.endproc

; ==============================================================================
; private functions
; ==============================================================================

; convert the cursor position into a VRAM address.
; pass the calculated address to Nmi::write_addr.
; change: A, X
.proc csr_to_addr
    lda #0
    sta Tmp::zb2 ; high byte
    lda zbCursorY
    sta Tmp::zb3 ; low byte

    ; multiply cursor y by 32 tiles per row.
    ldx #5
mul32:
    asl Tmp::zb3
    rol Tmp::zb2
    dex
    bne mul32

    ; add x offset
    lda zbCursorX
    ora Tmp::zb3
    sta Tmp::zb3

    ; add VRAM base address
    clc
    lda Tmp::zb2
    adc #$20
    sta Tmp::zb2

    lda Tmp::zb2
    ldx Tmp::zb3
    rts
.endproc


; print high nibble of a byte.
; < A = byte to print
.proc print_nibble_hi
    and #$f0
    lsr
    lsr
    lsr
    lsr
    jmp print_nibble_hex
    ; jsr rts -> jmp
.endproc


; print low nibble of a byte.
; < A = byte to print
.proc print_nibble_lo
    and #$0f
    jmp print_nibble_hex
    ; jsr rts -> jmp
.endproc


.proc print_nibble_hex
    cmp #10
    bcc digit
    clc
    adc #$37
    SKIP_WORD
digit:
    ora #$30
    jmp pur_char
    ; jsr rts -> jmp
.endproc


; buffer a character for printing during the next NMI.
; supported control characters and cursor position will be handled here.
.proc pur_char
    jsr handle_control
    bcc done
    jsr Nmi::write_data
    jsr csr_advance
    bcc done
    jsr new_write
done:
    rts
.endproc


; move the cursor right.
; > C = 0 success
;   C = 0 failure
; changes: X
.proc csr_right
    ldx zbCursorX
    inx
    cpx #Const::SCREEN_W_TILE
    bcs done
    stx zbCursorX
done:
    rts
.endproc


; move the cursor down.
; > C = 0 success
;   C = 0 failure
; changes: X
.proc csr_down
    ldx zbCursorY
    inx
    cpx #Const::SCREEN_H_TILE
    bcs done
    stx zbCursorY
done:
    rts
.endproc


; move the cursor down.
; > C = 0 success
;   C = 0 failure
; changes: X
;.proc csr_erase
;    lda #BLANK_TILE
;    sty Tmp::zb3
;    ldy zbCursorX
;
;loop:
;    jsr Nmi::write_data
;    iny
;    cpy #Const::SCREEN_W_TILE
;    bne loop
;
;    ldy Tmp::zb3
;    rts
;.endproc


; advance the cursor to the position that the next character should be printed.
; move to the next line and wrap around the screen if needed.
; erase the line if the cursor moved to a new line.
; > C = 0 success
;   C = 1 need new write
.proc csr_advance
    jsr csr_right
    bcc done
    ; move to the start of the next line
    ldx #0
    stx zbCursorX

    jsr csr_down
    bcc done
    ; wrap around to the top of the screen
    ldx #0
    stx zbCursorY
    sec
done:
    rts
.endproc


.proc new_write
    jsr Nmi::write_done
    jsr csr_to_addr
    sty Tmp::zb3
    jsr Nmi::write_addr
    ldy Tmp::zb3
.endproc


; try to handle control characters.
; < A = possible control character
; > C = 0 success
;   C = 1 failure
.proc handle_control
    cmp #Chr::NEW_LINE
    bne not_new_line
    jsr handle_new_line
    bcc success
not_new_line:
    cmp #Chr::TAB
    bne not_tab
    jsr handle_tab
    bcc success
not_tab:
    ; TODO: add support for more control character.
    sec
success:
    rts
.endproc


; move the cursor to the start of the next line and erase that line.
; > C = 0 success
; changes: A, X
.proc handle_new_line
    ; advance to the next line
    ldx #<(Const::SCREEN_W_TILE - 1)
    stx zbCursorX
    jsr csr_advance
    jsr new_write
    clc
    rts
.endproc


; move the cursor to the next tab stop.
; > C = 0 success
; changes: A
.proc handle_tab
    lda #' '
    jsr Nmi::write_data
    jsr csr_advance
    lda zbCursorX
    and #%00000011 ; tab stop every 4 chars
    bne handle_tab
    clc
    rts
.endproc
