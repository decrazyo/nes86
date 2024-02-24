; console-like output functions.

.ifndef _CON_
.define _CON_

.global con

.global con_csr_home

; these functions aren't terribly efficient but they are mostly for debugging/testing.
.global con_print_chr
.global con_print_str
.global con_print_hex
.global con_print_arr
.global con_print_bin

.endif
