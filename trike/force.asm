        NAME  Force_Vectors

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                FORCE_VECTORS                               ;
;            Tables of force vectors for the wheels of the RoboTrike         ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the tables of x-force and y-force vector values for the
; wheels of the RoboTrike in hexadecimal form. The tables assume the RoboTrike
; has 3 wheels.
;
; The tables included are:
;       Forcex_Table - a table of the x-force vectors of the wheels
;       Forcey_Table - a table of the y-force vecotrs of the wheels
;
; Revision History:
;   11/15/15   Nancy Cao      initial code and comments

;setup code group and start the code segment
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'


; Forcex_Table
;
; Description:      This is the force vector table for the x-direction for the
;                   wheels of the RoboTrike. Values listed are in hex. 
;
; Notes:            Assumed that the RoboTrike has 3 wheels and are oriented 120
;                   degrees around each other.
;
; Author:           Nancy Cao
; Revision History:
;   11/15/15  Nancy Cao    initial table and comments

Forcex_Table    LABEL   WORD
                PUBLIC  Forcex_Table


;       DW      normalized value (hexadecimal)
			
        DW          07FFFH       ; x-force vector (1) of wheel 1
        DW          0C000H       ; x-force vector (-1/2) of wheel 2
        DW          0C000H       ; x-force vector (-1/2) of wheel 3


; Forcey_Table
;
; Description:      This is the force vector table for the y-direction for the
;                   wheels of the RoboTrike. Values listed are in hex. 
;
; Notes:            Assumed that the RoboTrike has 3 wheels and are oriented 120
;                   degrees around each other.
;
; Author:           Nancy Cao
; Revision History:
;   11/15/15  Nancy Cao     initial table and comments

Forcey_Table    LABEL   WORD
                PUBLIC  Forcey_Table


;       DW      normalized value (hexadecimal)	

        DW         0000H        ; y-force vector (0) of wheel 1
        DW         9127H        ; y-force vector (-root3/2) of wheel 2
        DW         6ED9H        ; y-force vector (root3/2) of wheel 3
       
CODE    ENDS



        END
