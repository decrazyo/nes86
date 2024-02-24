
.include "con.inc"
.include "chr.inc"
.include "const.inc"
.include "nmi.inc"
.include "ppu.inc"
.include "tmp.inc"

.export con
.export con_csr_home
.export con_print_chr
.export con_print_str
.export con_print_hex
.export con_print_arr
.export con_print_bin

.segment "ZEROPAGE"

zbCursorX: .res 1
zbCursorY: .res 1

; TODO: implement scrolling
;zbScroll: .res 1

.segment "CODE"

.proc con
    jmp ppu
    ; jsr rts -> jmp
.endproc


; move the cursor to the upper left corner of the screen
; changes: A
.proc con_csr_home
    lda #0
    sta zbCursorX
    sta zbCursorY
    rts
.endproc


; print a single character to the screen.
; < A = char to print
.proc con_print_chr
    sta gzbTmp1
    jsr csr_to_addr
    jsr nmi_write_addr

    lda gzbTmp1
    jsr pur_char

    jsr nmi_write_done
    rts
.endproc

; print a C string to the screen.
; < gzwTmp0 = pointer to a C string.
.proc con_print_str
    jsr csr_to_addr
    jsr nmi_write_addr

    ldy #0
loop:
    lda (gzwTmp0), y
    cmp #0
    beq done
    iny
    jsr pur_char
    jmp loop
done:
    jsr nmi_write_done
    rts
.endproc

; print a single byte in hex.
; < A = byte to print
.proc con_print_hex
    sta gzbTmp1
    jsr csr_to_addr
    jsr nmi_write_addr

    lda gzbTmp1
    jsr print_nibble_hi

    lda gzbTmp1
    jsr print_nibble_lo

    jsr nmi_write_done
    rts
.endproc

; print an array of bytes as hex digits.
; < gzwTmp0 = pointer to an array.
; < Y length of the array
.proc con_print_arr
    ; this should all work as long as we don't change pur_char to use Y too much.
    jsr csr_to_addr
    sty gzbTmp3 ; must do this after csr_to_addr
    jsr nmi_write_addr

    ldy #0
loop:
    lda (gzwTmp0), y
    jsr print_nibble_hi
    lda (gzwTmp0), y
    jsr print_nibble_lo
    iny
    cpy gzbTmp3
    bcc loop

    jsr nmi_write_done
    rts
.endproc


; print a single byte in binary.
; < A = byte to print
.proc con_print_bin
    sta gzbTmp1
    jsr csr_to_addr
    jsr nmi_write_addr

    ldy #8
loop:
    rol gzbTmp1
    bcs one
    lda #$30
    SKIP_WORD
one:
    lda #$31
    jsr pur_char
    dey
    bne loop

    jsr nmi_write_done
    rts
.endproc


; convert the cursor position into a VRAM address.
; pass the calculated address to nmi_write_addr.
; change: A, X
.proc csr_to_addr
    lda #0
    sta gzbTmp2 ; high byte
    lda zbCursorY
    sta gzbTmp3 ; low byte

    ; multiply cursor y by 32 tiles per row.
    ldx #5
mul32:
    asl gzbTmp3
    rol gzbTmp2
    dex
    bne mul32

    ; add x offset
    lda zbCursorX
    ora gzbTmp3
    sta gzbTmp3

    ; add VRAM base address
    clc
    lda gzbTmp2
    adc #$20
    sta gzbTmp2

    lda gzbTmp2
    ldx gzbTmp3
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
    jsr nmi_write_data
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
    cpx #SCREEN_W_TILE
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
    cpx #SCREEN_H_TILE
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
;    sty gzbTmp3
;    ldy zbCursorX
;
;loop:
;    jsr nmi_write_data
;    iny
;    cpy #SCREEN_W_TILE
;    bne loop
;
;    ldy gzbTmp3
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
    jsr nmi_write_done
    jsr csr_to_addr
    sty gzbTmp3
    jsr nmi_write_addr
    ldy gzbTmp3
.endproc


; try to handle control characters.
; < A = possible control character
; > C = 0 success
;   C = 1 failure
.proc handle_control
    cmp #$0a ; \n
    bne not_new_line
    jsr handle_new_line
    bcc success
not_new_line:
    cmp #$09 ; \t
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
    ldx #<(SCREEN_W_TILE - 1)
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
    jsr nmi_write_data
    jsr csr_advance
    lda zbCursorX
    and #%00000011 ; tab stop every 4 chars
    bne handle_tab
    clc
    rts
.endproc
