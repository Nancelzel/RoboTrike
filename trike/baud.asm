        NAME  Baud

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Baud                                    ;
;            Table of baud rate dividers for the serial I/O routine          ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the table of serial parameters, including baud rate
; divisor and parity.
;
; These tables assume the RoboTrike has 3 wheels.
;
; The tables included are:
;       Parity_Table - a table of flags for wheels to go backwards
;
; Revision History:
;   11/24/15   Nancy Cao      initial code and comments


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

Baud_Table        LABEL   WORD
                  PUBLIC  Baud_Table

        DW      120     ; 4800 baud rate
        DW      80      ; 7200 baud rate
        DW      60      ; 9600 baud rate
        DW      30      ; 19200 baud rate
        DW      15      ; 38400 baud rate
        
CODE    ENDS



        END
