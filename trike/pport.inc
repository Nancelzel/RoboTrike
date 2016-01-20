;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  PPORT.INC                                 ;
;                         Parallel Port Definitions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the parallel port functions.
;
; Revision History:
;     11/17/15   Nancy Cao      initial code and comments

; Addresses
ParallelPort          EQU     180H      ;address of the parallel port

; Control Register Values
ParallelVal           EQU     10000000B ; control val to write to parallel port

; Other constants
PortOffset            EQU     3H       ; offset from the parallel port address