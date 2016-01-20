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
;                                               calls on the keyscan function
;                                               from keypad.asm
;                        InstallTimer2Handler - installs the timer 2 handler
;
; Revision History:
;     11/01/15  Nancy Cao         initial revision
;     11/03/15  Nancy Cao         updated comments
;     11/05/15  Nancy Cao         updated comments
;     11/08/15  Nancy Cao         updated code/comments for keypad
;     11/12/15  Nancy Cao         moved install timer 2 handler from interrupt
;                                 file and updated comments

; local include files
$INCLUDE(TIMER.INC)        ; display constants for timers
$INCLUDE(INTER.INC)        ; display constants for interrupts

EXTRN Keyscan:NEAR         ; scans and debounces pressed keys
EXTRN Multiplex:NEAR       ; multiplexes the digits on the board

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; Timer2EventHandler
; 
; Description: This function reacts to the timer 2 interrupt and calls on the
;              multiplex function to determine which digit to display next. It
;              then sends the EOI to the interrupt controller and timer
;              (COUNTS_PER_MS).
;
; Operation:   This function simply calls Multiplex, which will write to the
;              actual display. Afterwards, it will send the EOI to the interrupt
;              controller and to timer 2, then semd timer 2 to the interrupt.
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
;

Timer2EventHandler  PROC        NEAR
                   PUBLIC      Timer2EventHandler
                   
    PUSHA                        ; save current values in registers in stack

    CALL    Keyscan              ; scans the keys to see if any are pressed
 Start:
    CALL    Multiplex
    MOV     DX, INTCtrlrEOI      ; send the EOI to the interrupt controller
    MOV     AX, TimerEOI         ; send the EOI to the timer
    OUT     DX, AL               ; send timer to the interrupt

    POPA                         ; retrieve saved values in stack to registers
    
    IRET                         ;and return for event handlers

Timer2EventHandler       ENDP

; InitTimer2
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

InitTimer2   PROC        NEAR
             PUBLIC      InitTimer2

        MOV     DX, Tmr2Count   ;initialize the count register to Tmr2Count
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt  ;setup max count for 1ms counts
        MOV     AX, COUNTS_PER_MS
        OUT     DX, AL

        MOV     DX, Tmr2Ctrl    ;setup the control register with interrupts
        MOV     AX, Tmr2CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer2      ENDP

; InstallTimer2Handler
;
; Description:       Install the event handler for the timer 2 interrupt.
;
; Operation:         Writes the address of the timer 2 event handler to the
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

InstallTimer2Handler  PROC    NEAR
                      PUBLIC  InstallTimer2Handler

    XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
    MOV     ES, AX
                                ;store the vector
    MOV     ES: WORD PTR (VECTOR_SIZE * Tmr2Vec), OFFSET(Timer2EventHandler)
    MOV     ES: WORD PTR (VECTOR_SIZE * Tmr2Vec + BYTE_SIZE), SEG(Timer2EventHandler)


    RET                     ;all done, return


InstallTimer2Handler  ENDP

CODE ENDS

END