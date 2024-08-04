; TODO: move all this shit to keyboard.s

; we will only have one keyboard driver active at a time,
; either the Family BASIC driver or the on-screen driver.
; this means that the two drivers can share the same RAM.
; this module manages the shared RAM of bother drivers
; and exports meaningful symbols for each.

.include "keyboard/ram.inc"
.include "keyboard/family_basic.inc"

; Family BASIC exports
.exportzp zbJoypad1State
.exportzp zbaMatrixState
.exportzp zbaRowState
.exportzp zbaRowKeys
.exportzp zbKeyIndex

; on-screen exports
.exportzp zbKeyboardScrollX
.exportzp zbKeyboardScrollY
.exportzp zbKeyboardEnabled

.exportzp zbJoypadNew
.exportzp zbJoypadOld
.exportzp zbJoypadPressed

.exportzp zbCursorX
.exportzp zbCursorY

.exportzp zbModifierKeys

.segment "ZEROPAGE"

zbJoypad1State: .res 1
zbaMatrixState: .res FamilyBasic::MATRIX_ROWS

; these are temporary variables.
; we can't use Tmp because they are changed during NMI.
; consider adding temporary variables that can be shared among NMI routines.
zbaRowState: .res 1
zbaRowKeys: .res 1
zbKeyIndex: .res 1


; TODO: merge these
zbKeyboardScrollX: .res 1
zbKeyboardScrollY: .res 1
zbKeyboardEnabled: .res 1

zbJoypadNew: .res 1
zbJoypadOld: .res 1
zbJoypadPressed: .res 1

zbCursorX: .res 1
zbCursorY: .res 1

zbModifierKeys: .res 1