NAME    REMOTE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    Remote                                  ;
;                       RoboTrike Remote Board Functions                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the functions used by the remote
;                    board of the RoboTrike. The public functions included are:
;                        InitRemote         - initializes the remote board,
;                                             including the chips, illegal,
;                                             handlers, keypad, the display
;                                             board, the serial, the timer 2
;                                             which is used to debounce the
;                                             keypad and display digits on the
;                                             display board, and int 2, which is
;                                             used to handle different
;                                             interrupts for the serial. The
;                                             event queue that stores events to
;                                             be processed by the motor is also
;                                             initialized. (public)
;                        SetCriticalError - sets the critical error flag (public)
;                  The private functions included are:
;                        SerialPutString - puts a command through the serial,
;                                          one character at a time (private)
;                        KeyHandler     - handles any key presses; displays the
;                                         function of the pressed key, then
;                                         sends the command (private)
;                        DataHandler - reads data received from the serial and
;                                      displays it onto the display board (private)
;                        ErrorHandler   - determines what error to display on
;                                         the display board (private)
;                        DoNothing      - a function that does nothing (private)
;                 Tables included are:
;                        JumpTable - a table of addresses of handler functions
;                        CommandTable - a table of commands to send to the serial
;                                       from the keys pressed
;                        DisplayTable - a table of commands to display on the
;                                       display board
;                        ErrorTable - a table of possible errors to display on
;                                     the display board
;                        
;
; Revision History:
;     12/01/15  Nancy Cao         initial comments and pseudocode
;     12/25/15  Nancy Cao         initial code and updated comments
;     12/28/15  Nancy Cao         updated comments

; local include files
$INCLUDE(REMOTE.INC)          ; remote constants used for the remote main
$INCLUDE(QUEUE.INC)           ; queue constants used for the queue

EXTRN InitCS:NEAR               ; used to initialize chip select
EXTRN ClrIRQVectors:NEAR        ; used to clear interrupt vector table
EXTRN InitKeypad:NEAR           ; used to initialize keypad
EXTRN InitDisplay:NEAR          ; used to initialize display
EXTRN InitSerial:NEAR           ; used to initialize serial
EXTRN InitEventQueue:NEAR       ; used to initialize the event queue
EXTRN InitTimer2:NEAR           ; used to initialize timer 2
EXTRN InstallTimer2Handler:NEAR ; installs timer 2 handler
EXTRN InitInt2:NEAR             ; used to initialize interrupt 2
EXTRN InstallInt2Handler:NEAR   ; installs interrupt 2 handler
EXTRN Display:NEAR              ; displays a string onto the display board
EXTRN EnqueueEvent:NEAR         ; enqueues an event into the event queue
EXTRN DequeueEvent:NEAR         ; dequeues an event from the event queue
EXTRN SerialPutChar:NEAR        ; puts a character through the serial


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; Main loop
; 
; Description: The main loop initializes the remote board. The chips, illegal
;              handlers, keypad, display board, and the serial are all
;              initialized. Timer 2 and its handler is also initialized and
;              installed, which is used to debounce on the keypad and display
;              digits on the display board. Int 2 and its handler is also
;              initialized and installed. The event queue, which stores events
;              that the remote board should do, is initialized. The critical
;              flag is set to no critical error, and then dequeues an event
;              from the event queue to determine what type of event is next.
;
; Operation:   This function first initializes the chip select, and then clears
;              the interrupt vector table. Timer 2 is then initialized, and its
;              handler is installed. Int 2 is initialized, and its handler is
;              installed. Then both keypad and display are initialized. The
;              serial is also initialized, and the event queue is initialized.
;              The critical flag is set to NO_ERROR, the display buffer is set
;              to 0 since no data has been received, and a default message of
;              "EE 51" is sent to the display board. Interrupts are
;              then allowed before checking if there is a critical error. If
;              there is no error, the function loops and attempts to dequeue the
;              event queue over and over again. If at any time the critical flag is
;              set, the remote is re-initialized before dequeuing events again.
;              Once an event value is dequeued, it is converted into a word
;              index to be used to look up the corresponding handler in the
;              JumpTable (no action, key handler, data handler, or error handler).
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: criticalFlag - the critical error flag (DS, R/W)
;                   displayBuffer - the index of the display for the data
;                                   received (DS, W)
;                   startmsg - a starting message for the remote side (DS, R)
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
; Data Structures: Queue.
;
; Registers Changed: AX, SI, DS, BX, zero flag
;
; Author: Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao        initial comments and pseudocode
;     12/25/15  Nancy Cao        initial code and comments
;     12/28/15  Nancy Cao        updated comments
;

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
        
        CALL    InstallTimer2Handler    ; install the timer 2 handler
        
        CALL    InitTimer2              ; initialize timer 2
       
        CALL    InstallInt2Handler      ; install the interrupt 2 handler

        CALL    InitInt2                ; initialize interrupt 2

        CALL    InitKeypad              ; initialize the keypad
            
        CALL    InitDisplay             ; initialize the display
        
        CALL    InitSerial              ; initialize the serial
          
        CALL    InitEventQueue          ; initialize the event queue
            
        MOV     criticalFlag, NO_ERROR  ; reset critical error flag
        MOV     displayBuffer, 0         ; reset buffer
        
        MOV     SI, OFFSET(startmsg)    ; display start message on the display
        PUSH    CS                      ; switch to ES:SI 
        POP     ES
        CALL    Display                 ; display start message
          
        STI                             ; and finally allow interrupts.
        
DequeueEventValue:
        CMP criticalFlag, CRITICAL_ERROR ; check if there is a critical error
        JE  ResetRemote                  ; if so, re-initialize everything
        
        CALL DequeueEvent                ; otherwise dequeue an event
        
        JZ DequeueEventValue             ; if nothing was dequeued try again
        
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
; Data Structures:   None.
;
; Registers Changed: None.
;
; Author:            Nancy Cao
; Revision History:
;     12/26/15  Nancy Cao   initial code and comments
;     12/28/15  Nancy Cao   updated comments

SetCriticalError     PROC    NEAR
                     PUBLIC  SetCriticalError

    MOV     criticalFlag, CRITICAL_ERROR  ; set the critical flag to be a
                                          ; critical error
    RET
      
SetCriticalError     ENDP

; SerialPutString
;
; Description:       This function retrieves the appropriate command to pass
;                    to the trike from the CommandTable and passes it through
;                    the serial one character at a time using SerialPutChar.
;                    ASCII_NULL is the signal that the entire command has been
;                    sent through.
;
; Operation:         The function starts by getting the appropriate command to
;                    pass to the serial by looking at BX, the index of the
;                    command from CommandTable to send over to the trike. It
;                    then goes through each character of the command at a time
;                    and sends it to the trike via SerialPutChar. The index is
;                    increased to send the next character. This loops until the
;                    null terminal is read.
;
; Arguments:         DX - the index of the command to put through the serial
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
; Registers Changed: AX, BX
;
; Author:            Nancy Cao
; Revision History:
;     12/26/15  Nancy Cao   initial code and comments
;     12/28/15  Nancy Cao   updated comments
;     01/04/15  Nancy Cao   fixed some bugs

SerialPutString     PROC    NEAR
    
    MOV  BX, DX                   ; index of the command to send
    
CheckEndString:
    MOV  AL, CS:CommandTable[BX]  ; get current character
    
Break10:
    CMP   AL, ASCII_NULL          ; check if character is the end of string
    JE    PutStringFinish         ; if yes, we are done
    ;JNE  SendChar                ; otherwise continue sending characters to
                                  ; serial

SendChar:                         ; send the character over the serial
    PUSH  BX                      ; don't want SerialPutChar to change index
    CALL  SerialPutChar           ; put the character over the serial
    POP   BX                      ; retreive saved index
    INC   BX                      ; increment index to next character
    JMP   CheckEndString          ; check if this character is the end char

PutStringFinish:
    RET
      
SerialPutString     ENDP
                
              
; KeyHandler
;
; Description:       This function looks for the string to display determined
;                    by what key was pressed on the keypad. The argument is the
;                    index of the key value that can be used to look up in the
;                    CommandTable to see the appropriate string to display.
;                    The display board is cleared before calling display. It
;                    then sends the appropriate command to the motor side by
;                    calling SerialPutString.
;
; Operation:         The function first takes the index argument and stores
;                    it in DX in preparation for looking up the appropriate
;                    string to display in the CommandTable. Afterwards, the
;                    address of the DisplayTable is found and the index is
;                    shifted appropriately to take account of the size of the
;                    string to display. The address and the index value is added
;                    to get the address of the command to display. The function
;                    switches from CS to ES to write into ES instead, before
;                    calling the Display function. Afterwards, SerialPutString
;                    is called to send the appropriate command to the serial to
;                    the motors so that the specified action can be performed.
;
; Arguments:         AL - the event value
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
; Registers Changed: DX, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao   initial comments and pseudocode
;     12/26/15  Nancy Cao   initial code and updated comments
;     12/28/15  Nancy Cao   updated comments
;     01/04/15  Nancy Cao   fixed some bugs

KeyHandler     PROC    NEAR

DisplayKeyCommand:
    MOV  DL, AL                          ; move index to DL
    MOV  DH, 0                           ; clear higher bit of DX so DX can be
                                         ; index of DisplayTable
    LEA  SI, CS:DisplayTable             ; get address to beginning of DisplayTable
    SHL  DX, DISPLAY_LENGTH              ; multiply index by length of string (8-bit so shift by 3 since 2^3 = 8)
    ADD  SI, DX                          ; get the address of appropriate display
                                         ; and store it as the address argument
                                         ; for Display
    PUSH CS                              ; move to ES:SI
    POP  ES
    CALL Display                         ; display the string
    ;JMP SendCommandToSerial             ; send appropriate command to motors

SendCommandToSerial:
    CALL SerialPutString                 ; send the command through the serial
                                         ; to the motors; index stored in DX
    RET
      
KeyHandler     ENDP

; DataHander
;
; Description:       This function takes the character received from the serial
;                    and determines whether to display the current data
;                    received from the data or to continue appending characters
;                    to the current string to display. It will display the
;                    current string if the return character is reached or the
;                    string has reached DISPLAY_SIZE.
;
; Operation:         This function first checks if the character read in is
;                    the return character. If so, the current string saved from
;                    the serial should be displayed. Otherwise, the function
;                    checks if the length of the current string has already
;                    reached DISPLAY_SIZE. If so, the current string saved from
;                    the serial should be displayed. Otherwise, the current
;                    character read is appended to the end of displayStr, and
;                    the buffer is incremented for the next character. To display,
;                    the function first appends a null character to the end
;                    before moving to ES:SI to display displayStr. Afterwards,
;                    the buffer is reset for the next data received.
;
; Arguments:         AL - the character read from the serial
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  displayBuffer - the current max index of the current string
;                                   to display (DS, R/W)
;                    displayStr   - the current string to display (DS, W)
;                    
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
; Registers Changed: AX, BX, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao   initial comments and pseudocode
;     12/26/15  Nancy Cao   initial code and comments
;     12/28/15  Nancy Cao   updated comments

DataHandler     PROC    NEAR

CheckEndData:
    CMP  AL, ASCII_RET      ; check if we are at the end of reading data
    JE   DisplayData        ; if yes display the entire data
    JNE  TryAppendChar      ; otherwise attempt to append character
    
TryAppendChar:
    CMP displayBuffer, DISPLAY_SIZE    ; check if max display size is reached
    JZ  FinishDataHandler              ; if yes go ahead and display
    ;JMP AppendChar                    ; otherwise continue reading in char
    
AppendChar:
    MOV  BX, displayBuffer             ; get the current index of where the
                                       ; string on display ends
    MOV  SI, OFFSET(displayStr)        ; get address of displayStr
    ADD  SI, BX                        ; current address to add next character
    MOV  [SI], AL                      ; add character
    INC  displayBuffer                 ; increment index to the next character
    JMP  FinishDataHandler             ; finish handling data
    
DisplayData:

    MOV  BX, displayBuffer             ; get the current index of where the
                                       ; string on display ends
    MOV  SI, OFFSET(displayStr)        ; get address of displayStr
    ADD  SI, BX                        ; current address to add next character
    MOV  AL, ASCII_NULL                ; assign null value
    MOV  [SI], AL                      ; append null character to string to display
    MOV  SI, OFFSET(displayStr)        ; get address of string to display
    PUSH DS                            ; move to ES:SI
    POP  ES
    CALL Display                       ; display the string
    MOV  displayBuffer, 0              ; reset to beginning of display
    ;JMP FinishDataHandler             ; finish handling data
    
FinishDataHandler:
    RET
      
DataHandler     ENDP

; ErrorHander
;
; Description:       This function handles error events. An error index is
;                    passed in, and the function looks up the appropriate error
;                    to display on the display board
;
; Operation:         The function makes the passed in index into an index for
;                    lookup in ErrorTable. The address of ErrorTable is stored
;                    as an argument, the index is shifted appropriately to take
;                    account of the size of the string to display. The address
;                    and the index value is added to get the address of the
;                    command to display. The function switches from CS to ES to
;                    write into ES instead, before calling the Display function.
;
; Arguments:         AL - the index of ErrorTable
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
; Data Structures:   Queue.
;
; Registers Changed: DX, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/01/15  Nancy Cao   initial comments and pseudocode
;     12/26/15  Nancy Cao   updated code and comments
;     12/28/15  Nancy Cao   updated comments

ErrorHandler     PROC    NEAR

DisplayErrorMessage:   
    MOV  DL, AL                          ; move index to DL
    MOV  DH, 0                           ; clear higher bit of DX so DX can be
                                         ; index of DisplayTable
    LEA  SI, CS:ErrorTable               ; get address to beginning of ErrorTable
    SHL  DX, DISPLAY_LENGTH              ; multiply index by length of string (8-bit so shift by 3 since 2^3 = 8)
    ADD  SI, DX                          ; get the address of appropriate display
                                         ; and store it as the address argument
                                         ; for Display
    PUSH CS                              ; move to ES:SI
    POP  ES
    CALL Display                         ; display the string

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

    DW        OFFSET(DoNothing)      ; does nothing
    DW        OFFSET(KeyHandler)     ; handles key presses
    DW        OFFSET(DataHandler)    ; handles commands to display
    DW        OFFSET(ErrorHandler)   ; handles errors

; A table of commands corresponding to the keys pressed on the keypad
CommandTable LABEL BYTE
             PUBLIC  CommandTable

    DB        'V+100 ', ASCII_RET, ASCII_NULL  ; KEY_0: increase speed by 100
    DB        'V-100 ', ASCII_RET, ASCII_NULL  ; KEY_1: decrease speed by 100
    DB        'V+500 ', ASCII_RET, ASCII_NULL  ; KEY_2: increase speed by 500
    DB        'V-500 ', ASCII_RET, ASCII_NULL  ; KEY_3: decrease speed by 500
    DB        'S0    ', ASCII_RET, ASCII_NULL  ; KEY_4: stop the RoboTikre
    DB        'S32767', ASCII_RET, ASCII_NULL  ; KEY_5: set to 1/2 MAX_SPEED
    DB        'V32767', ASCII_RET, ASCII_NULL  ; KEY_6: set to MAX_SPEED
    DB        'D+10  ', ASCII_RET, ASCII_NULL  ; KEY_7: turn RoboTrike 10 degrees right    
    DB        'D-10  ', ASCII_RET, ASCII_NULL  ; KEY_8: turn RoboTrike 10 degrees left
    DB        'D+30  ', ASCII_RET, ASCII_NULL  ; KEY_9: turn RoboTrike 30 degrees right
    DB        'D-30  ', ASCII_RET, ASCII_NULL  ; KEY_A: turn RoboTrike 30 degrees left
    DB        'F     ', ASCII_RET, ASCII_NULL  ; KEY_B: turn turret laser on
    DB        'O     ', ASCII_RET, ASCII_NULL  ; KEY_C: turn turret laser off
    DB        '      ', ASCII_RET, ASCII_NULL  ; KEY_D: do nothing
    DB        '      ', ASCII_RET, ASCII_NULL  ; KEY_E: do nothing
    DB        '      ', ASCII_RET, ASCII_NULL  ; KEY_F: do nothing
    
; A table of messages corresponding to keys to display on the display board
DisplayTable LABEL BYTE
             PUBLIC DisplayTable
			
    DB        '1      ', ASCII_NULL             ; increase speed by 100
    DB        '2      ', ASCII_NULL             ; decrease speed by 100
    DB        '3      ', ASCII_NULL             ; increase speed by 500
    DB        '4      ', ASCII_NULL             ; decrease speed by 500
    DB        '5      ', ASCII_NULL             ; stop RoboTrike
    DB        '6      ', ASCII_NULL             ; set speed to 1/2 MAX_SPEED
    DB        '7      ', ASCII_NULL             ; set speed to MAX_SPEED
    DB        '8      ', ASCII_NULL             ; turn RoboTrike 10 degrees right
    DB        '9      ', ASCII_NULL             ; turn RoboTrike 10 degrees left
    DB        '10     ', ASCII_NULL             ; turn RoboTrike 30 degrees right
    DB        '11     ', ASCII_NULL             ; turn RoboTrike 30 degrees left
    DB        '12     ', ASCII_NULL             ; fire laser
    DB        '13     ', ASCII_NULL             ; turn laser off
    DB        '14     ', ASCII_NULL             ; do nothing
    DB        '15     ', ASCII_NULL             ; do nothing
    DB        '16     ', ASCII_NULL             ; do nothing

; A table of error messages to display onto the display board
ErrorTable LABEL BYTE
           PUBLIC ErrorTable
			
    DB        '17     ', ASCII_NULL             ; framing error
    DB        '18     ', ASCII_NULL             ; parity error       
    DB        '19     ', ASCII_NULL             ; break error
    DB        '20     ', ASCII_NULL             ; overrun error
    DB        '21     ', ASCII_NULL             ; buffer overflow error
         
startmsg   DB 'EE 51  ', ASCII_NULL             ; default message

CODE ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

criticalFlag  DB NO_ERROR      ; the flag that indicates if a critical
                                       ; error has occurred
displayStr    DB DISPLAY_SIZE + 1 DUP(?) ; the data sent from motors to display
displayBuffer DW 0                      ; the current index of char in display

DATA    ENDS


;the stack

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS



        END     START