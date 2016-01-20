NAME    TRIKE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Trike                                   ;
;                       RoboTrike Trike Board Functions                      ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the functions used by the remote
;                    board of the RoboTrike. The public functions included are:
;                        InitTrike          - initializes the remote board,
;                                             including the chips, illegal,
;                                             handlers, keypad, the display
;                                             board, the serial, the timer 0
;                                             which is used for the
;                                             motors, and int 2, which is
;                                             used to handle different
;                                             interrupts for the serial. The
;                                             event queue
;                                             that stores events to be
;                                             processed by the motor is also
;                                             initialized. (public)
;                        SetCriticalError - sets the critical error flag (public)
;                  The private functions included are:
;                        SerialPutString - puts a command through the serial,
;                                          one character at a time
;                        KeyHandler     - handles any key presses; displays the
;                                         function of the pressed key, then
;                                         sends the command (private)
;                        DataHandler - reads data received from the serial and
;                                      displays it onto the display board (private)
;                        ErrorHandler   - determines what error to display on
;                                         the display board (private)
;                        DoNothing - does nothing (private)
;                 Tables included are:
;                        JumpTable - a table of addresses of handler functions
;                        ErrorTable - a table of possible errors to display on
;                                     the display board
;                        
;
; Revision History:
;     12/01/15  Nancy Cao         initial comments and pseudocode
;     12/25/15  Nancy Cao         initial code and updated comments
;     12/28/15  Nancy Cao         updated comments

; local include files
$INCLUDE(TRIKE.INC)          ; remote constants used for the remote main
$INCLUDE(QUEUE.INC)           ; queue constants used for the queue

EXTRN InitCS:NEAR             ; used to initialize chip select
EXTRN ClrIRQVectors:NEAR      ; used to clear interrupt vector table
EXTRN InitSerial:NEAR         ; used to initialize serial
EXTRN InitEventQueue:NEAR     ; used to initialize the event queue
EXTRN InitTimer0:NEAR         ; used to initialize timer 0
EXTRN InstallTimer0Handler:NEAR  ; installs timer 0 handler
EXTRN InitInt2:NEAR           ; used to initialize interrupt 2
EXTRN InstallInt2Handler:NEAR ; installs interrupt 2 handler
EXTRN InitPP:NEAR             ; initializes the parallel port
EXTRN InitMotor:NEAR          ; initializes the motor
EXTRN EnqueueEvent:NEAR       ; enqueues an event to the event queue
EXTRN DequeueEvent:NEAR       ; dequeues an event from the event queue
EXTRN SerialPutChar:NEAR      ; puts a character through the serial

EXTRN InitSerialChar:NEAR     ; initializes the parser
EXTRN ParseSerialChar:NEAR    ; parses a command string into characters and
                              ; calls appropriate command based on command


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; Main loop
; 
; Description: The main loop initializes the trike. The chips, illegal
;              handlers, keypad, display board, and the serial are all
;              initialized. Timer 0 and its handler is also initialized and
;              installed, which is used for the motors. Int 2 and its handler is
;              also initialized and installed. The parallel port is initialized.
;              The motors and the parser is initialized. The event queue, which
;              stores events that the remote board should do, is initialized.
;              The critical flag is set to no critical error, and then dequeues
;              an event from the event queue to determine what type of event is
;              next to be handled.
;
; Operation:   This function first initializes the chip select, and then clears
;              the interrupt vector table. Timer 0 is then initialized, and its
;              handler is installed. Int 2 is initialized, and its handler is
;              installed. Then both keypad and display are initialized. The
;              parallel port, motors, parser, and serial are also initialized,
;              and the event queue is initialized. The critical flag is set to
;              NO_CRITICAL_ERROR, and then allow interrupts. The critical flag
;              is first set to NO_CRITICAL_ERROR, and then the function loops
;              and attempts to dequeue the event queue over and over again. If
;              at any time the critical flag is set, the remote is
;              re-initialized before dequeuing events again. Once an event value
;              is dequeued, it is converted into a word index to be used to look
;              up the corresponding handler in the JumpTable (key handler, data
;              handler, or error handler).
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: criticalFlag - the critical error flag (DS, R/W)
; Global Variables: None.
;
; Input: None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: None.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: BX
;
;
; Author: Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao        initial comments and pseudocode
;     12/25/15  Nancy Cao        initial code and comments
;     12/28/15  Nancy Cao        updated comments

START:  

MAIN:
        MOV     AX, DGROUP              ; initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ; initialize the data segment
        MOV     DS, AX


ResetRemote:
        CALL    InitCS                  ; initialize the 80188 chip selects
                                        ; assumes LCS and UCS already setup
       
        CALL    ClrIRQVectors           ; clear interrupt vector table
        
        CALL    InitTimer0              ; initialize timer 0
        
        CALL    InstallTimer0Handler    ; install the timer 0 handler
        
        CALL    InitInt2                ; initialize interrupt 0
        
        CALL    InstallInt2Handler      ; install the interrupt 0 handler
        
        CALL    InitPP                  ; initialize the parallel port

        CALL    InitMotor               ; initialize the motors
        
        CALL    InitSerialChar          ; initialize the parser
        
        CALL    InitSerial              ; initialize the serial
        
        CALL    InitEventQueue          ; initialize the event queue
        
        MOV     criticalFlag, NO_CRITICAL_ERROR ; reset critical error flag
                                        
        STI                             ; and finally allow interrupts.
        
DequeueEventValue:
        CMP criticalFlag, CRITICAL_ERROR ; check if there is a critical error
        JE  ResetRemote                  ; if so, re-initialize everything
        
        CALL DequeueEvent                ; otherwise dequeue an event
        
        JZ DequeueEventValue             ; if nothing was dequeued try again

Break:        
        MOV BL, AH                       ; move event value into lower bit of BX
                                         ; index
        MOV BH, 0                        ; clear higher bit of BX
        SHL BX, 1                        ; convert byte index to word index,
                                         ; since JumpTable is word type
        
        CALL CS:JumpTable[BX]       	 ; call function corresponding to event
        
        JMP DequeueEventValue            ; keep dequeuing event values
        
        HLT                              ; never executed (hopefully)
 
; SetCriticalError
;
; Description:       This function sets the critical error flag.
;
; Operation:         The critical error flag is set.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  criticalFlag - the critical error flag (DS, W)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   Queue.
;
; Registers Changed: None.
;
; Author:            Nancy Cao
; Revision History:
;     12/26/15  Nancy Cao   initial code and comments

SetCriticalError     PROC    NEAR
                     PUBLIC  SetCriticalError

    MOV     criticalFlag, CRITICAL_ERROR  
    RET
      
SetCriticalError     ENDP

; SerialPutString
;
; Description:       This function passes to the serial the string stored at the
;                    argument passed in SI one character at a time using
;                    SerialPutChar. ASCII_NULL is the signal that the entire
;                    command has been sent through.
;
; Operation:         This function starts by getting the character stored at
;                    SI, which is the argument passed in. If this character is
;                    the null terminal character, the entire string has been
;                    sent and the function can end. Otherwise, the current
;                    address is saved as the character is sent through the
;                    serial to the remote via SerialPutChar. The address is
;                    retrieved at the end and incremented to get the next
;                    character to be put through the serial.
;
; Arguments:         SI - the address of where the string to pass through the
;                         serial starts
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
; Registers Changed: AX, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/26/15  Nancy Cao   initial code and comments
;     12/28/15  Nancy Cao   updated comments

SerialPutString     PROC    NEAR

CheckEndString:
    MOV     AL, ES:[SI]             ; next character to put to serial to display
    CMP     AL, ASCII_NULL          ; check if character is the end of string
    JE      PutStringFinish         ; if yes, we are done
    ;JNE    SendChar                ; otherwise continue sending characters to
                                    ; serial

SendChar:                           ; send the character over the serial
    PUSH    SI                      ; save current index of character on stack
    CALL    SerialPutChar           ; put the character over the serial
    POP     SI                      ; retrieve saved index of character from stack    
    INC     SI                      ; increment index to next character
    JMP     CheckEndString          ; check if this character is the end char

PutStringFinish:
    RET
      
SerialPutString     ENDP

; DataHander
;
; Description:       This function takes calls ParseSerialChar to see if the
;                    character event value in AL can be parsed. If it is parsed
;                    successfully, nothing should be done. Otherwise, the
;                    corresponding error is looked up from a table and sent over
;                    the serial.
;
; Operation:         This function first calls ParseSerial to parse the
;                    character from the serial. If no errors occur, the function
;                    is done. Otherwise, AX should have the error index, which
;                    is used to look up the corresponding error in the
;                    ErrorTable. The address of ErrorTable is stored
;                    as an argument, the index is shifted appropriately to take
;                    account of the size of the error to send. The address
;                    and the index value is added to get the address of the
;                    error to send. The function switches from CS to ES to
;                    write into ES instead, before calling SerialPutString.
;
; Arguments:         AL - the event value to be parsed
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  errorStr - the error string to send to the remote (DS, R/W)
; Global Variables:  None.
;
; Input:             None. 
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   Queue.
;
; Registers Changed: None.
;
; Author:            Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao   initial comments and pseudocode
;     12/26/15  Nancy Cao   initial code and comments
;     12/28/15  Nancy Cao   updated comments

DataHandler     PROC    NEAR

DisplayDataMessage:
        CALL    ParseSerialChar         ; parses the command from serial; if no
                                        ; errors occurred the right function
                                        ; should have been called to handle the
                                        ; command                     
        CMP     AX, NO_ERROR            ; check there were no errors
        JE      FinishDataHandler       ; if no errors we are done
        ;JNE    SendError               ; otherwise need to send the appropriate
                                        ; error
        
SendError:
        LEA  SI, CS:ErrorTable           ; get address to beginning of ErrorTable
        MOV  BL, AL                      ; make error value the index for lookup
        MOV  BH, 0                       ; clear higher bit of BX
        SHL  BX, DISPLAY_LENGTH          ; multiply index by length of string (8-bit so shift by 3 since 2^3 = 8)
        ADD  SI, BX                      ; get the address of appropriate display
                                         ; and store it as the address argument
            
        PUSH CS                          ; move to ES:SI
        POP  ES      
        CALL SerialPutString             ; send error to serial to be displayed
        JMP FinishDataHandler
        
FinishDataHandler:
        RET                             ; once done handling, return
      
DataHandler     ENDP

; ErrorHander
;
; Description:       This function handles error events. If there is an error,
;                    an error message is passed to the seiral via
;                    SerialPutString.
;
; Operation:         The address of errorStr is stored as an argument for
;                    SerialPutString. Switch to ES:SI before SerialPutString
;                    is called, which will send the error over the serial to the
;                    remote.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  errorStr - the error message to display (DS, R/W)
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
; Registers Changed: SI
;
; Author:            Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao   initial comments and pseudocode
;     12/26/15  Nancy Cao   updated code and comments
;     12/28/15  Nancy Cao   updated comments

ErrorHandler     PROC    NEAR

DisplayErrorMessage:
        MOV  SI, OFFSET(errorStr)        ; get address of string to display
        PUSH CS                          ; move to ES:SI
        POP  ES
        CALL SerialPutString             ; send error over the serial
        RET
        
ErrorHandler     ENDP

; DoNothing
;
; Description:       This function does nothing.
;
; Operation:         This function does nothing.
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
; Registers Changed: None.
;
; Author:            Nancy Cao
; Revision History:
;     12/21/15  Nancy Cao   initial code and comments

DoNothing      PROC        NEAR

    NOP
    RET

DoNothing     ENDP

; A table of addresses of handler functions
JumpTable   LABEL   WORD
            PUBLIC  JumpTable

    DW        OFFSET(DoNothing)      ; do nothing
    DW        OFFSET(DoNothing)      ; do nothing (no key presses)
    DW        OFFSET(DataHandler)    ; handles commands to display
    DW        OFFSET(ErrorHandler)   ; handles errors

; A table of error messages to display onto the display board
ErrorTable LABEL BYTE
           PUBLIC ErrorTable

    DB        'No err', ASCII_RET, ASCII_NULL             ; no errors
    DB        'Overfl', ASCII_RET, ASCII_NULL             ; overflow error       
    DB        'Badarg', ASCII_RET, ASCII_NULL             ; bad argument
    DB        'TransE', ASCII_RET, ASCII_NULL             ; transition error
         
errorStr DB   'Errors', ASCII_RET, ASCII_NULL ; error
noError DB    'No err', ASCII_RET, ASCII_NULL ; no error

CODE ENDS


;the data segment
DATA    SEGMENT PUBLIC  'DATA'

criticalFlag DB NO_CRITICAL_ERROR      ; the flag that indicates if a critical
                                       ; error has occurred

DATA    ENDS


;the stack

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS



        END     START