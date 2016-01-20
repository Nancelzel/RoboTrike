        NAME  Parity

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Parity                                  ;
;                 Table of parity for the serial I/O routine                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

Parity_Table      LABEL   BYTE
                  PUBLIC  Parity_Table
                
        DB      00000000B           ; no parity
        DB      00001100B           ; even parity
        DB      00000100B           ; odd parity
        DB      00011100B           ; stick even parity
        DB      00010100B           ; stick odd parity
        
CODE    ENDS



        END
