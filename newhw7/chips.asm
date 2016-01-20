NAME    CHIPS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    CHIPS                                   ;
;                        RoboTrike Chip Select Functions                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    chip select. The public functions included are:
;                        InitCS            - initializes the chip select
;
; Revision History:
;     11/17/15  Nancy Cao         initial code and comments

; local include files
$INCLUDE(CHIPS.INC)        ; display constants for chips

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; InitCS
;
; Description:       Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:         Write the initial values to the PACS and MPCS registers.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            MPCS, PACS, Control values.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
;
; Author:            Nancy Cao
; Revision History:
;     11/17/2015     Nancy Cao        initial code and comments

InitCS  PROC    NEAR
        PUBLIC  InitCS

        MOV     DX, PACSreg    ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL         ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg    ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL         ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                    ;done so return


InitCS  ENDP


CODE ENDS

END