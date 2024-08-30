
; this file contains various macros for operating on comma separated lists.
; i can't decide if these macros are terrible or beautiful. maybe both.
; i definitely feel like i'm abusing ca65's macros though.
; using these macros may noticeably increase compilation time.

.ifndef _LIST_
    _LIST_ = 1

    ; macro definitions ignore scopes so we won't define one.

    ; iterate through the items of a comma separated list.
    ; a callback macro will be called with each item of the list
    ; in the order that the items appear in the list.
    ; < list = comma separated list if items to iterate over.
    ; < callback = macro to call with each item of "list".
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   iterate {FUNC_LIST}, my_callback
    .macro iterate list, callback
        .local list
        .local callback
        .local start
        .local len
        .local i
        .local j

        .ifblank list
            .error "macro 'iterate' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank callback
            .error "macro 'iterate' missing required parameter 'callback'"
            .exitmacro
        .endif

        start .set 0
        len .set 0

        .repeat .tcount(list), i
            j .set i + 1

            ; ".mid" appears to break when the starting token index is greater then 100.
            ; we'll use ".left" and ".right" to mimic the functionality of ".mid".

            .if .match({.right(1, .left(j, list))}, {,})
                ; we have reached a comma in the list.
                ; call "callback" with the current list item.
                callback .right(len, .left(start + len, list))

                ; adjust the indices to point to the start of the next list item.
                start .set j
                len .set 0
            .else
                ; the token isn't a comma.
                ; we'll consider this token to be part of the current list item.
                len .set len + 1
            .endif
        .endrepeat

        ; call "callback" with the last list item.
        callback .right(len, list)

    .endmacro

    ; this is intended to be a callback macro for "iterate".
    ; define byte sized data containing the low byte of "item" minus 1.
    ; 1 is subtracted so that the byte can be used in jump tables which use "rts" instead of "jmp".
    ; this is similar to the ".lobyte" pseudo function.
    ; < item = value to extract the low byte from
    .macro lo_return_byte item
        .local item

        .ifblank item
            .error "macro 'lo_return_byte' missing required parameter 'item'"
            .exitmacro
        .endif

        .byte .lobyte(item-1)
    .endmacro

    ; iterate over "list" and define a byte for each list item with "lo_return_byte"
    ; this can be used to build jump tables which use "rts" instead of "jmp".
    ; this is similar to the ".lobytes" pseudo function.
    ; < list = comma separated list if items to define bytes for.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   rbaJumpTableLo:
    ;   lo_return_bytes {FUNC_LIST}
    .macro lo_return_bytes list
        .local list

        .ifblank list
            .error "macro 'lo_return_bytes' missing required parameter 'list'"
            .exitmacro
        .endif

        iterate {list}, lo_return_byte
    .endmacro

    ; this is intended to be a callback macro for "iterate".
    ; define byte sized data containing the high byte of "item" minus 1.
    ; 1 is subtracted so that the byte can be used in jump tables which use "rts" instead of "jmp".
    ; this is similar to the ".hibyte" pseudo function.
    ; < item = value to extract the high byte from
    .macro hi_return_byte item
        .local item

        .ifblank item
            .error "macro 'hi_return_byte' missing required parameter 'item'"
            .exitmacro
        .endif

        .byte .hibyte(item-1)
    .endmacro

    ; iterate over "list" and define a byte for each list item with "hi_return_byte"
    ; this can be used to build jump tables which use "rts" instead of "jmp".
    ; this is similar to the ".hibytes" pseudo function.
    ; < list = comma separated list if items to define bytes for.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   rbaJumpTableHi:
    ;   hi_return_bytes {FUNC_LIST}
    .macro hi_return_bytes list
        .local list

        .ifblank list
            .error "macro 'hi_return_bytes' missing required parameter 'list'"
            .exitmacro
        .endif

        iterate {list}, hi_return_byte
    .endmacro

    ; this is intended to be a callback macro for "iterate".
    ; compare "item1" to "item2".
    ; if the items match then set "index" to "count".
    ; increment "count" each time the macro is called.
    ; < index = initial index value. set this to -1 to detect if no match was found.
    ; < count = initial count value. set this to 0 for zero-indexed lists.
    ; < item1 = item to search for in a list.
    ; < item2 = list item to compare against. provided by "iterate".
    ; > index = index of the last occurrence of "item1" in a list or the initial "index" value.
    ; > count = number of times this macro was called by "iterate". i.e. number of items in the list.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   index .set -1
    ;   count .set 0
    ;   iterate {FUNC_LIST}, {find_item index, count, func_3,}
    ;   ; "index" should now be 2
    ;   ; "count" should now be 4
    ;   .assert index <> -1, error, "item not found"
    .macro find_item index, count, item1, item2
        .local index
        .local count
        .local item1
        .local item2

        .ifblank index
            .error "macro 'find_item' missing required parameter 'index'"
            .exitmacro
        .endif

        .ifblank count
            .error "macro 'find_item' missing required parameter 'count'"
            .exitmacro
        .endif

        .ifblank item1
            .error "macro 'find_item' missing required parameter 'item1'"
            .exitmacro
        .endif

        .ifblank item2
            .error "macro 'find_item' missing required parameter 'item2'"
            .exitmacro
        .endif

        .if .xmatch(item1, item2)
            index .set count
        .endif

        count .set count + 1
    .endmacro

    ; find the index of "item" in "list" and return the index in "index".
    ; "index" is unchanged if "item" is not in "list".
    ; < list = comma separated list to search.
    ; < item = item to search for in "list".
    ; < index = initial index value. set this to -1 to detect if no match was found.
    ; > index = index of the last occurrence of "item" in "list" or the initial "index" value.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   ; this will produce the same result as ".byte 2".
    ;   index_byte {FUNC_LIST}, func_3
    .macro index_of list, item, index
        .local list
        .local item
        .local index
        .local count

        .ifblank list
            .error "macro 'index_of' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank item
            .error "macro 'index_of' missing required parameter 'item'"
            .exitmacro
        .endif

        .ifblank index
            .error "macro 'index_of' missing required parameter 'index'"
            .exitmacro
        .endif

        count .set 0
        iterate {list}, {find_item index, count, item,}
    .endmacro

    ; this is macro probably shouldn't be called externally.
    ; "index_byte_fill" and "index_byte_at" are safer and should be used instead.
    ; get the index of "item" in "list" and define a byte with the value of that index.
    ; < list = comma separated list to search.
    ; < item = item to search for in "list".
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   ; this will produce the same result as ".byte 2".
    ;   index_byte {FUNC_LIST}, func_3
    .macro index_byte list, item
        .local list
        .local item
        .local index
        .local count

        .ifblank list
            .error "macro 'index_byte' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank item
            .error "macro 'index_byte' missing required parameter 'item'"
            .exitmacro
        .endif

        index .set -1
        count .set 0
        iterate {list}, {find_item index, count, item,}

        .if count > 255
            .warning "list contains more than 255 items"
        .endif

        .if index = -1
            .error "item could not be found in list"
            .exitmacro
        .elseif index > 255
            .error "index is out of range"
            .exitmacro
        .endif

        .byte index
    .endmacro

    ; get the index of "item" in "list".
    ; define n bytes with the value of that index, where n = index - size + 1.
    ; < size = current size of the table being built.
    ; < index = table index to fill to.
    ; < list = comma separated list to search.
    ; < item = item to search for in "list".
    ; > size = new size of the table.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   size .set 0
    ;   ; define 3 bytes with a value of 1.
    ;   index_byte_fill size, 2, {FUNC_LIST}, func_2
    ;   ; "size" is now 3.
    ;   ; define 1 byte with a value of 0.
    ;   index_byte_fill size, 3, {FUNC_LIST}, func_1
    ;   ; "size" is now 4.
    ;   ; this will error out because size > 3.
    ;   index_byte_fill size, 3, {FUNC_LIST}, func_1
    .macro index_byte_fill size, index, list, item
        .local size
        .local index
        .local list
        .local item

        .ifblank size
            .error "macro 'index_byte_fill' missing required parameter 'size'"
            .exitmacro
        .endif

        .ifblank index
            .error "macro 'index_byte_fill' missing required parameter 'index'"
            .exitmacro
        .endif

        .ifblank list
            .error "macro 'index_byte_fill' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank item
            .error "macro 'index_byte_fill' missing required parameter 'item'"
            .exitmacro
        .endif

        .if size > index
            .error "'size' is larger than 'index'"
            .exitmacro
        .endif

        .repeat index - size + 1
            index_byte {list}, item
            size .set size + 1
        .endrepeat
    .endmacro

    ; get the index of "item" in "list" and define a byte with the value of that index.
    ; "size" must equal "index" unless "fill" is specified.
    ; if "fill" is specified then additional bytes will be defined until "size" equals "index".
    ; the value of fill bytes will be the index of "fill" in "list".
    ; < size = current size of the table being built.
    ; < index = table index to define a byte at.
    ; < list = comma separated list to search.
    ; < item = item to search for in "list".
    ; < fill = optional item to search for in "list". used to fill gaps in the table.
    ; > size = new size of the table.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   size .set 0
    ;   rbaJumpTableIndex:
    ;   index_byte_at size, 0, {FUNC_LIST}, func_3
    ;   index_byte_at size, 1, {FUNC_LIST}, func_4
    ;   index_byte_at size, 5, {FUNC_LIST}, func_1, func_2
    ;   .assert size = 6, error, "incorrect table size."
    ;   ; the example above is equivalent to the following.
    ;   ; .byte 2
    ;   ; .byte 3
    ;   ; .byte 1
    ;   ; .byte 1
    ;   ; .byte 1
    ;   ; .byte 0
    .macro index_byte_at size, index, list, item, fill
        .local size
        .local index
        .local list
        .local item
        .local fill

        .ifblank size
            .error "macro 'index_byte_at' missing required parameter 'size'"
            .exitmacro
        .endif

        .ifblank index
            .error "macro 'index_byte_at' missing required parameter 'index'"
            .exitmacro
        .endif

        .ifblank list
            .error "macro 'index_byte_at' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank item
            .error "macro 'index_byte_at' missing required parameter 'item'"
            .exitmacro
        .endif

        .if size > index
            .error "'size' is larger than 'index'"
            .exitmacro
        .endif

        .if index > size
            .ifblank fill
                .error "'index' is larger than 'size' and 'fill' was not specified"
                .exitmacro
            .else
                index_byte_fill size, index-1, {list}, fill
            .endif
        .endif

        index_byte {list}, item
        size .set size + 1
    .endmacro

.endif
