;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  CONVERTS.INC                              ;
;                              Converts Definitions                          ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the conversion functions.
;
; Revision History:
;     10/18/15  Nancy Cao      initial revision


;definitions

ASCII_NULL         EQU 0     ;string termination character (<null>)
PLUS               EQU '+'   ;the ASCII positive sign
MINUS              EQU '-'   ;the ASCII negative sign
ZERO               EQU '0'   ;the ASCII 0 sign
LETTER_A           EQU 'A'   ;the ASCII A
MAX_DEC_POW        EQU 10000 ;10^4, the largest 16-bit power of decimal 10
MAX_HEX_POW        EQU 4096  ;16^3, the largest 16-but power of hex 16