;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  INTER.INC                                 ;
;                            Interrupt Definitions                           ;
;                                Include File                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the interrupt functions.
;
; Revision History:
;     11/17/15   Nancy Cao      initial revisions and comments

; General Definitions

FIRST_RESERVED_VEC	EQU	1            	;reserve vectors 1-3
LAST_RESERVED_VEC	EQU	3
NUM_IRQ_VECTORS     EQU     256         ;number of interrupt vectors
VECTOR_SIZE         EQU 4               ; the size of a vector
BYTE_SIZE           EQU 2               ; the size of a byte
TOTAL_VECTOR_NUM    EQU 256             ; the number of vectors to initialize

; Addresses

; Register Values

INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register
NonSpecEOI      EQU     08000H          ;Non-specific EOI command