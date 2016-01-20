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
;                        InitTimer2           - initializes timer 0
;                        Timer2EventHandler   - in response to the timer 0
;                                               interrupt, the event handler
;                                               calls on the keyscan function
;                                               from keypad.asm
;                        InstallTimer2Handler - installs the timer 0 handler
;
; Revision History:
;     11/01/15  Nancy Cao         initial revision
;     11/03/15  Nancy Cao         updated comments
;     11/05/15  Nancy Cao         updated comments
;     11/08/15  Nancy Cao         updated code/comments for keypad
;     11/12/15  Nancy Cao         moved install timer 2 handler from interrupt
;                                 file and updated comments
;     12/28/15  Nancy Cao         altered names and constants for timer 0
;                                 instead of timer 2

; local include files
$INCLUDE(TIMER.INC)        ; display constants for timers
$INCLUDE(INTER.INC)        ; display constants for interrupts

EXTRN MotorEventHandler:NEAR ; handles motor on/off, motor direction and laser
                             ; on/off using pulse modulation


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; Timer0EventHandler
; 
; Description: This function reacts to the timer 0 interrupt and calls on the
;              multiplex function to determine which digit to display next. It
;              then sends the EOI to the interrupt controller and timer
;              (COUNTS_PER_MS).
;
; Operation:   This function simply calls Multiplex, which will write to the
;              actual display. Afterwards, it will send the EOI to the interrupt
;              controller and to timer 0, then send timer 0 to the interrupt.
;
; Arguments: None
; Return Value: None.
; Local Variables: None.
; Shared Variables: None.
; Global Variables: None.
;
; Input: None.
; Output: EOI.
;
; Error Handling: None.
;
; Limitations: None.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: None.
;
; Author: Nancy Cao
; Revision History:
;     10/27/15  Nancy Cao        initial comments and pseudocode
;     10/31/15  Nancy Cao        initial revision
;     11/08/15  Nancy Cao        updated code for keypad
;     12/28/15  Nancy Cao        changed to timer 0 for motors
;

Timer0EventHandler  PROC        NEAR
                    PUBLIC      Timer0EventHandler
                   
    PUSHA                        ; save current values in registers in stack

    CALL    MotorEventHandler    ; figures out direction for every motor. Also
                                 ; whether motors/laser should be on/off

    MOV     DX, INTCtrlrEOI      ; send the EOI to the interrupt controller
    MOV     AX, TimerEOI         ; send the EOI to the timer
    OUT     DX, AL               ; send timer to the interrupt

    POPA                         ; retrieve saved values in stack to registers
    
    IRET                         ;and return for event handlers

Timer0EventHandler       ENDP

; InitTimer0
;
; Description:       Initialize the 80188 Timer 0.  The timer 0 is initialized
;                    to generate interrupts every COUNTS_PER_MS.
;                    The interrupt controller is also initialized to allow the
;                    timer 0 interrupts.  Timer #0 is used to prescale the
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
; Output:            Timer0config
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
;     12/28/15  Nancy Cao   updated to user timer 0 for motors

InitTimer0   PROC        NEAR 
             PUBLIC      InitTimer0

        MOV     DX, Tmr0Count   ;initialize the count register to Tmr2Count
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCnt  ;setup max count for 1ms counts
        MOV     AX, COUNTS_PER_MS
        OUT     DX, AL

        MOV     DX, Tmr0Ctrl    ;setup the control register with interrupts
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer0      ENDP

; InstallTimer2Handler
;
; Description:       Install the event handler for the timer 0 interrupt.
;
; Operation:         Writes the address of the timer 0 event handler to the
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
;     11/01/15  Nancy Cao   initial revision and comments
;     11/05/15  Nancy Cao   updated comments
;     11/12/15  Nancy Cao   updated comments
;     12/28/15  Nancy Cao   updated to use timer 0 for motors

InstallTimer0Handler  PROC    NEAR
                      PUBLIC  InstallTimer0Handler

    XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX
                                ;store the vector
    MOV     ES: WORD PTR (VECTOR_SIZE * Tmr0Vec), OFFSET(Timer0EventHandler)
    MOV     ES: WORD PTR (VECTOR_SIZE * Tmr0Vec + BYTE_SIZE), SEG(Timer0EventHandler)


    RET                     ;all done, return


InstallTimer0Handler  ENDP

CODE ENDS

END