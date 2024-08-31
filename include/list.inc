
; this file contains various macros for operating on comma separated lists.
; i can't decide if these macros are terrible or beautiful. maybe both.
; i definitely feel like i'm abusing ca65's macros though.
; using these macros may noticeably increase compilation time.

.linecont +

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
    ; increment "length" each time the macro is called.
    ; < length = initial length value. set this to 0.
    ; < item = list item provided by "iterate".
    ; > length = number of times this macro was called by "iterate".
    ;            i.e. number of items in the list.
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   length .set 0
    ;   iterate {FUNC_LIST}, {count_all length,}
    ;   ; "length" should now be 4
    .macro count_all length, item
        .local length
        .local item

        .ifblank length
            .error "macro 'count_all' missing required parameter 'length'"
            .exitmacro
        .endif

        .ifblank item
            .error "macro 'count_all' missing required parameter 'item'"
            .exitmacro
        .endif

        length .set length + 1
    .endmacro

    ; count the number of items in "list"
    ; < list = comma separated list of items to count.
    ; < length = initial length value. set this to 0.
    ; > length = number of items in "list".
    ; example:
    ;   .define FUNC_LIST func_1, func_2, func_3, func_4
    ;   length .set 0
    ;   length_of {FUNC_LIST}, length
    ;   ; "length" should now be 4
    .macro length_of list, length
        .local list
        .local length

        .ifblank list
            .error "macro 'length_of' missing required parameter 'list'"
            .exitmacro
        .endif

        .ifblank length
            .error "macro 'length_of' missing required parameter 'length'"
            .exitmacro
        .endif

        iterate {list}, {count_all length,}
    .endmacro

    ; do not call this function externally. call "zip_lists" instead.
    ; this is a recursive function that does the bulk of the work for "zip_lists".
    ; < name = name of a new macro to define with the content of the zipped list.
    ; < count = number of items in a both lists.
    ; < list1 = comma separated list to combine with "list2". must be the same length as "list2".
    ; < list2 = comma separated list to combine with "list1". must be the same length as "list1".
    ; < list3 = accumulates the result of zipping "list1" and "list2". leave this blank initially.
    .macro zipper name, count, list1, list2, list3
        .local name
        .local count
        .local list1
        .local list2
        .local list3
        .local done
        .local len1
        .local len2
        .local tcount1
        .local tcount2

        .ifblank name
            .error "macro 'zipper' missing required parameter 'name'"
            .exitmacro
        .endif

        .ifblank count
            .error "macro 'zipper' missing required parameter 'count'"
            .exitmacro
        .endif

        .if count = 0
            ; list3 will have a leading comma that needs to be stripped.
            .define name .right(.tcount(list3) - 1, list3)
        .else
            count .set count - 1

            done .set 0
            len1 .set 0
            tcount1 .set .tcount(list1)

            ; find the length of the first item in list1.
            .repeat tcount1, i
                .if done = 0
                    .if .match({.mid(i, 1, list1)}, {,})
                        done .set 1
                    .else
                        len1 .set len1 + 1
                    .endif
                .endif
            .endrepeat

            done .set 0
            len2 .set 0
            tcount2 .set .tcount(list2)

            ; find the length of the first item in list2.
            .repeat tcount2, i
                .if done = 0
                    .if .match({.mid(i, 1, list2)}, {,})
                        done .set 2
                    .else
                        len2 .set len2 + 1
                    .endif
                .endif
            .endrepeat

            ; use recursion to zip the lists together.
            ; the first items in list1 and list2 will be removed
            ; and combined to form a new item to append to list3.
            zipper \
            name, \
            count, \
            {.right(tcount1 - len1 - 1, list1)},\
            {.right(tcount2 - len2 - 1, list2)}, \
            {list3, .left(len1, list1) .left(len2, list2)}
        .endif

    .endmacro

    ; combine 2 lists together into a new list
    ; by combining the 0th items of each list, followed by the 1st items, etc...
    ; this is basically python's builtin "zip" function.
    ; https://docs.python.org/3/library/functions.html#zip
    ; < name = name of a new macro to define with the content of the zipped list.
    ; < list1 = comma separated list to combine with "list2". must be the same length as "list2".
    ; < list2 = comma separated list to combine with "list1". must be the same length as "list1".
    ; example:
    ;   .define MY_LIST_1 foo, bar
    ;   .define MY_LIST_2 baz, qux
    ;   zip_lists MY_LIST, {MY_LIST_1}, {MY_LIST_2}
    ;   ; the example above is equivalent to the following.
    ;   ; .define MY_LIST foo baz, bar qux
    .macro zip_lists name, list1, list2
        .local name
        .local list1
        .local list2
        .local length1
        .local length2

        .ifblank name
            .error "macro 'zip_lists' missing required parameter 'name'"
            .exitmacro
        .endif

        .ifblank list1
            .error "macro 'zip_lists' missing required parameter 'list1'"
            .exitmacro
        .endif

        .ifblank list2
            .error "macro 'zip_lists' missing required parameter 'list2'"
            .exitmacro
        .endif

        length1 .set 0
        length2 .set 0

        length_of {list1}, length1
        length_of {list2}, length2

        .if length1 <> length2
            .error "lists are different lengths"
        .endif

        zipper name, length1, {list1}, {list2}
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
    ; > count = number of times this macro was called by "iterate".
    ;           i.e. number of items in the list.
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
    ;   index .set -1
    ;   index_of {FUNC_LIST}, func_3, index
    ;   ; "index" should now be 2
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
            .error "item index is out of range"
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

        value .set -1
        count .set 0
        iterate {list}, {find_item value, count, item,}

        .if count > 255
            .warning "list contains more than 255 items"
        .endif

        .if value = -1
            .error "item could not be found in list"
            .exitmacro
        .elseif value > 255
            .error "item index is out of range"
            .exitmacro
        .endif

        iterations .set index - size + 1
        size .set size + iterations

        .repeat iterations
            .byte value
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
