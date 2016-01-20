;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TRIKE.INC                               ;
;                                Trike Definitions                           ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the trike functions.
;
; Revision History:
;     12/28/15  Nancy Cao      initial code and comment

; definitions
NO_CRITICAL_ERROR  EQU 0
NO_ERROR           EQU 0    ; flag for no errors
CRITICAL_ERROR     EQU 1
ASCII_NULL         EQU 0    ; ASCII value of null
ASCII_RET          EQU 13   ; ASCII value of '<RETURN>'
DISPLAY_SIZE       EQU 8    ; the max number of characters that can be displayed
DISPLAY_LENGTH     EQU 3    ; the power of 2 of the length of the string displayed; 2^3 = 8-bit string