NAME    TIMER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    TIMER                                   ;
;                         RoboTrike Timer Event Handler                      ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    timer event handler. The public functions included are:
;                        InitTimer2           - initalizes timer 2
;                        Timer2EventHandler   - in response to the timer 2
;                                               interrupt, the event handler
;                                               calls on the MotorEVentHandler
;                        InstallTimer2Handler - installs the timer 2 handler
;
; Revision History:
;     11/15/15  Nancy Cao         initial code and comments
;     11/18/15  Nancy Cao         updated comments

; local include files
$INCLUDE(INT.INC)         ; display constants for timers

EXTRN SerialInterruptHandler:NEAR ; handles motor on/off, motor direction and laser
                             ; on/off using pulse modulation

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; InitInt2
;
; Description:       Initialize the 80188 Timer 2.  The timer 2 is initialized
;                    to generate interrupts every COUNTS_PER_MS.
;                    The interrupt controller is also initialized to allow the
;                    timer 2 interrupts.  Timer #2 is used to prescale the
;                    internal clock from 2.304 MHz to 1 KHz.
;
; Operation:         The appropriate values are written to the timer control
;                    registers in the PCB.  Also, the timer count registers
;                    are reset to zero.  Finally, the interrupt controller is
;                    setup to accept timer interrupts and any pending
;                    interrupts are cleared by sending a TimerEOI to the
;                    interrupt controller.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Timer2config
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
;     11/01/15  Nancy Cao   initial revision and comments
;     11/05/15  Nancy Cao   updated comments

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