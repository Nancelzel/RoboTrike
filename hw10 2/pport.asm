NAME    PPORT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    PPORT                                   ;
;                      RoboTrike Parallel Port Functions                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    parallel port. The public functions included are:
;                        InitPP            - initializes the paralllel port
;
; Revision History:
;     11/17/15  Nancy Cao         initial code and comments

; local include files
$INCLUDE(PPORT.INC)        ; display constants for timers


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; InitPP
;
; Description:       Initialize the parallel port.
;
; Operation:         Write the control value to the parallel port.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Control value.
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

InitPP  PROC    NEAR
        PUBLIC  InitPP

        MOV     DX, ParallelPort    ; setup to write to parallel port
        ADD     DX, PortOffset      ; the offset 
        MOV     AL, ParallelVal      ; to write ControlVal to ParallelPort  
        OUT     DX, AL              ; write ControlVal to ParallelPort

        RET                         ;done so return


InitPP  ENDP


CODE ENDS

END