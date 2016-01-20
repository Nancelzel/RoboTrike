        NAME  Flags

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     Flags                                  ;
;                Tables of flags for the wheels of the RoboTrike             ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the tables of flags for the wheels of the RoboTrike. These
; flags signify whether to either have the wheels rotate clockwise (forward = 0)
; or counterclockwise (backward = 1), as well as turned on (1) or off (0). The
; lowest 2 bits are for the first wheel; the second lowest 2 bits are for the
; second wheel; and the third lowest 2 bits are for the third wheel. The lower
; of the two bits are flags for whether the wheels should go backwards or not;
; the higher of the two bits are flags for whether the wheels should be on or
; off.
;
; These tables assume the RoboTrike has 3 wheels.
;
; The tables included are:
;       Back_Table - a table of flags for wheels to go backwards
;       Motor_On   - a table of flags for wheels to turn on
;
; Revision History:
;   11/16/15   Nancy Cao      initial code and comments


;setup code group and start the code segment
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

Back_Table      LABEL   BYTE
                PUBLIC  Back_Table
                
        DB      00000001B           ; flags first wheel to go backwards
        DB      00000100B           ; flags second wheel to go backwards
        DB      00010000B           ; flags third wheel to go backwards
                
Motor_On        LABEL   BYTE
                PUBLIC  Motor_On

        DB      00000010B           ; flags first wheel to turn on
        DB      00001000B           ; flags second wheel to turn on
        DB      00100000B           ; flags third wheel to turn on
        
CODE    ENDS



        END
