;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   INT.INC                                  ;
;                            Interrupt 2 Definitions                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the interrupt 2 functions.
;
; Revision History:
;     11/25/15   Nancy Cao      initial revisions and comments

; Interrupt Vectors
Int2Vec         EQU 14                 ; interrupt vector for int 2

; definitions

Int2Val         EQU 0000000000010111B  ; 00000000000----- reserved
                                       ; -----------0---- set level triggering
                                       ; ------------0--- enable interrupts
                                       ; -------------111 priority level
                                       
                                       
                                       
VECTOR_SIZE     EQU 4                  ; the size of a vector
BYTE_SIZE       EQU 2                  ; the size of a byte
TOTAL_VECT      EQU 256                ; the number of vectors to initialize


INT2Ctrl        EQU     0FF3CH         ; address of interrupt 2 control register