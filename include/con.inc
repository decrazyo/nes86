; console-like output functions.

.ifndef _CON_
.define _CON_

.scope Con
    .import con

    .import csr_home

    ; these functions aren't terribly efficient but they are mostly for debugging/testing.
    .import print_chr
    .import print_str

    .import print_hex
    .import print_hex_arr
    .import print_hex_arr_rev

    .import print_bin

    ; TODO: print binary array
    ; .import print_bin_arr
    ; TODO: print binary array in reverse
    ; .import print_bin_arr_rev
.endscope

.endif
