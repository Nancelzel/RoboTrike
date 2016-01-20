NAME    INT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    INT                                     ;
;                         RoboTrike Interrupt 2 Installer                    ;
;                                 EE/CS 51                                   ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program initializes and installs the interrupt
;                    2 for the interrupt handler in serialr.asm. The public
;                    functions included are:
;                        InitInt  2           - initalizes int 2
;                        InstallInt2Handler   - installs the int 2 handler
;
; Revision History:
;     11/25/15  Nancy Cao         initial code and comments
;     11/30/15  Nancy Cao         updated comments

; local include files
$INCLUDE(INT.INC)         ; display constants for interrupt 2

EXTRN SerialInterruptHandler:NEAR ; the interrupt handler from serialr.asm that
                                  ; uses int 2.

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; InitInt2
;
; Description:       Initialize the 80188 INT 2.  INT 2 is set to level
;                    triggering.
;
; Operation:         The appropriate value is written into the interrupt 2
;                    control register.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
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
;     11/25/15  Nancy Cao   initial revision and comments
;     11/30/15  Nancy Cao   updated comments

InitInt2     PROC        NEAR
             PUBLIC      InitInt2

StartIntInit:
        MOV     DX, INT2Ctrl ; send an interrupt 2 control register
        MOV     AX, Int2Val
        OUT     DX, AX

        RET                     ;done so return

InitInt2      ENDP

; InstallInt2Handler
;
; Description:       Install the event handler for the int 2 interrupt.
;
; Operation:         Writes the address of the int 2 event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, ES
;
; Author:            Nancy Cao
; Revision History:
;     11/25/15  Nancy Cao   initial revision and comments
;     11/30/15  Nancy Cao   updated comments

InstallInt2Handler    PROC    NEAR
                      PUBLIC  InstallInt2Handler

    XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX
                                ;store the vector
    MOV     ES: WORD PTR (VECTOR_SIZE * Int2Vec), OFFSET(SerialInterruptHandler)
    MOV     ES: WORD PTR (VECTOR_SIZE * Int2Vec + BYTE_SIZE), SEG(SerialInterruptHandler)


    RET                     ;all done, return


InstallInt2Handler  ENDP

CODE ENDS

END