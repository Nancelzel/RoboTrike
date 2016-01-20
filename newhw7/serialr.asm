NAME    SERIALR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SERIALR                                  ;
;                     RoboTrike Serial Routine Functions                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the RoboTrike serial routine
;                    functions. The public functions included are:
;                        InitSerial         - initializes the serial
;                        SerialPutChar      - loads a char into the serial
;                                             queue
;                        SetBaudRate        - sets the baud rate for serial
;                        SetParityRate      - sets the parity rate for serial
;                        SerialEventHandler - uses timer 2 interrupts to check
;                                             when to check for something in the
;                                             queue. Also enqueues errors
;                                             from reading the queue.
;
; Revision History:
;     11/17/15  Nancy Cao         initial comments and pseudocode
;     11/22/15  Nancy Cao         initial code

; local include files
$INCLUDE(SERIALR.INC)     ; serial constants used for serial I/O Routines
$INCLUDE(QUEUE.INC)       ; queue constants used for the queue

EXTRN QueueInit:NEAR      ; used to initialize the queue, set the head and the
                          ; tail at appropriate locations
EXTRN QueueEmpty:NEAR     ; used to check if the queue is empty
EXTRN QueueFull:NEAR      ; used to check if the queue is full
EXTRN Dequeue:NEAR        ; used to remove an element from the queue and return
                          ; that element if the queue is not already empty
EXTRN Enqueue:NEAR        ; used to put an element into the queue if the queue
                          ; is not already full
EXTRN EnqueueEvent:NEAR   ; enqueues an event and its value to the queue
                          
EXTRN Baud_Table:WORD     ; baud rate dividers used to get baud rates
EXTRN Parity_Table:BYTE   ; parity settings for the serial

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; InitSerial
; 
; Description: This function initializes the serial. The shared variables
;              initialized include the serial chip, the baud rate, the parity,
;              and the serial counter used for the event handler.
;
; Operation:   This function first initializes the serial chip. The baud rate
;              initially is 0, as well as the parity. The counter is set to
;              some rate.
;
; Arguments:        default - the index of the default values of the baud rate
;                             and parity
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: baud - the baud rate of the serial (w)
;                   parity - the parity of the serial (w)
;                   serialCounter - the counter for the serial event handler (w)
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
;     11/17/15  Nancy Cao        initial comments and pseudocode
;     11/22/15  Nancy Cao        initial code and updated comments
;

InitSerial          PROC        NEAR
                    PUBLIC      InitSerial

Init82050:                          ; initialize the 82050 serial chip
    MOV     DX, SERIAL_LCR          ; serial LCR address
    MOV     AL, SERIAL_SETUP        ; the value to put to LCR
    OUT     DX, AL                  ; write SERIAL_SETUP to SERIAL_LCR
                                    ; (also changes access back to Rx/Tx)

    MOV     DX, SERIAL_IER          ; serial IER address
    MOV     AL, SERIAL_IN_IRQ       ; the value to put into IER
    OUT     DX, AL                  ; writes SERIAL_IN_IRQ to SERIAL_IER
                                    ; which turns on the interrupts
	;JMP    SetSerial               ; set the rest of the serial

SetSerial:                          ; set serial parameters
    MOV     BX, 2                   ; the index of the default Baud rate divisor
    SHL     BX, 1                   ; must shift left since reading word table
    CALL    SetBaudRate             ; set the baud rate divider
    MOV     BX, 0                   ; the index of the default parity
    CALL    SetParity               ; set the parity of the serial
    ;JMP    InitQueue               ; initialize the queue

InitQueue:
    MOV     SI, OFFSET(tx)      ; pass in address of the transfer queue at DS:SI
    MOV     CX, LENGTH_TEST     ; pass in length of queue
    CALL    QueueInit           ; initialize an empty queue with head/tails
    ;JMP    InitKickstart       ; initialize kickstart flag

InitKickstart:
    MOV kickstart, 0            ; no kickstart since no interrupts
    ;JMP    EndInitSerial       ; finish initializing the serial

EndInitSerial:
    RET

InitSerial    ENDP

; SerialPutChar
;
; Description:       This function takes in an eventType, a constant signifying
;                    the event, and an eventVAlue, which is either a character
;                    or an error code. The character/error code is enqueued.
;                    If the character/error code is successfully enqueued,
;                    the carry flag is reset; otherwise it is set, meaning the
;                    queue was full
;
; Operation:         The function takes the eventValue stored in in AL and calls
;                    Enqueue, a function from queue.asm that enqueues the
;                    character currently stored in AL. If the function
;                    successfully stores the character, the carry flag is reset.
;                    If the function does not store the character, the carry
;                    flag is set to mean full.
;
; Arguments:         eventValue (AL) - either a character received or error code
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
; Registers Changed: Carry flag.
;
; Author:            Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code

SerialPutChar    PROC        NEAR
                 PUBLIC      SerialPutChar

    MOV SI, OFFSET(tx)
    CALL QueueFull        ; check if the queue is full before we try to enqueue
                          ; a char into the queue
    JZ SetCarryFlag	      ; the zero flag is set which means the queue is full,
                          ; so set the carry flag indicating that a char was
						  ; not put into the queue
    ;JMP EnqueueChar       ; otherwise attempt to enqueue the char

EnqueueChar:
	CALL Enqueue          ; enqueue the char
	;JMP CheckKickstart   ; check if we should kickstart
	
CheckKickstart:
	CMP kickstart, 1      ; check if kickstart flag is set
    JZ  DisableETBE  ; if so, disable interrupts
    JMP FinishPutChar     ; otherwise we are done

DisableETBE:
    MOV DX, SERIAL_IER        ; copy of value of SERIAL_IER
	IN  AL, DX                ; read in the value stored in IER to disable
    AND AL, DISABLE_ETBE_MASK ; clear the ETBE bit in the value
    OUT DX, AL                ; put the value back into IER to disable
    ;JMP EnableInterrupt      ; enable the interrupt again
 
EnableETBE:
    IN AL, DX
    OR AL, ENABLE_ETBE_MASK
    OUT DX, AL                ; put value back into IER to enable
    MOV kickstart, 0          ; unflag kickstart
    JMP FinishPutChar         ; finished with kickstarting
				
SetCarryFlag:
    STC                   ; set the carry flag to indicate char
	;JMP FinishPutChar

FinishPutChar:
    CLC                   ; unset the carry flag to indicate that a char was
	                      ; put into the queue
    STI                   ; end of critical code; enable interrupts again
	RET
	
SerialPutChar           ENDP

; SetBaudRate
;
; Description:       This function sets the baud rate parameter to its
;                    appropriate value.
;
; Operation:         Writes the baud rate parameter into the shared variable
;                    baud.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  baud - the baud of the serial (w)
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
;     11/17/15  Nancy Cao   initial comments and pseudocode

SetBaudRate      PROC        NEAR
                 PUBLIC      SetBaudRate
   
    PUSHF  
    CLI                   ; disable interrupts because critical code
    
SetDLAB:      
    MOV     DX, SERIAL_LCR          ; get the LCR address to talk to it
    IN      AL, DX                  ; read in the value from LCR
    OR      AL, ENABLE_BAUD_MASK    ; change baud bit to be set
    OUT     DX, AL                  ; sets DLAB
    ;JMP    WriteBaudDivisor
    
SetDLM:
    PUSH AX
    MOV AL, AH
    MOV DX, SERIAL_DLM
    OUT DX, AL
    POP AX
    
SetDLL:
    MOV DX, SERIAL_DLL
    OUT DX, AL
    
WriteBaudDivisor:
    MOV     DX, SERIAL_BAUD         ; set the baud rate divisor
    MOV     AX, CS:Baud_Table[BX]   ; get baud rate divisor
    OUT     DX, AX                  ; write out baud rate divisor
    ;JMP    ResetDLAB  

ResetDLAB:
    MOV     DX, SERIAL_LCR          ; talk to the baud rate divisor registers
    IN      AL, DX                  ; read in the value from LCR
    AND     AL, DISABLE_BAUD_MASK   ; clear the ETBE bit in the value
    OUT     DX, AL                  ; reset DLAB
    ;JMP    FinishedSetBaud

FinishSetBaud:
    ;STI                   ; end of critical code; enable interrupts again
    POPF
    RET

SetBaudRate           ENDP

; SetParity
;
; Description:       This function sets the parity parameter to its appropriate
;                    value.
;
; Operation:         Writes the parity rate parameter into the shared variable
;                    parity.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  parity - the parity of the serial (w)
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
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code

SetParity        PROC        NEAR
                 PUBLIC      SetParity

ClearParityBits:
    MOV     DX, SERIAL_LCR          ; get the LCR address to talk to it
    MOV     AL, CS:Parity_Table[BX] ; get the new parity
    OR      AL, SERIAL_SETUP        ; set up serial
    OUT     DX, AL                  ; set the parity in LCR
    ;JMP    FinishParity

FinishParity:
    RET
                 
SetParity    ENDP                 
                 
; SerialInterruptHandler
;
; Description:       This function handles the serial and putting characters
;                    into the serial via a queue. The function keeps track of
;                    a counter whose size is the Baud Rate. Once the counter
;                    reaches 0, the event handler checks if there is anything
;                    enqueued in the queue. If yes, the character or code is
;                    retrieved from the queue to be output into the serial
;                    channel. If an error is generated, the error code is
;                    enqueued. If something was dequeued, the counter is
;                    reset.
;
; Operation:         The function decrements the serial counter, then checks
;                    if the counter reached 0. If yes, the function tries to
;                    dequeue a character from the function. If the queue is not
;                    empty, the function will get a character from the dequeue
;                    function, and output this character to the serial channel.
;                    If there is an error trying to dequeue a character,
;                    and error code is generated and enqueued into the queue.
;                    The counter is then reset if dequeue happened.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            EOI.
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
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code

SerialInterruptHandler   PROC        NEAR
                         PUBLIC      SerialInterruptHandler

    PUSHA
    
    MOV     DX, SERIAL_IIR          ; get the IIR address to see interrupt
    IN      AL, DX                  ; read in the value in IIR
    AND     AL, IIR_MASK
    CMP     AL, 0                   ; check if an interrupt occurred
    JZ      FinishHandling          ; if no interrupt occurred end
    ;JMP    ContinueHandling        ; otherwise continue
    
ContinueHandling:
    MOV     BL, AL                  ; make IIR an index for the jump table
    MOV     BH, 0                   ; clear the higher bit of BX for accurate
                                    ; index
    CALL    CS:Jump_Table[BX]	    ; calls function to clear specific interrupt
    
    MOV     DX, EOI                 ; address of EOI
    MOV     AL, EOI_VALUE           ; the value that should be in EOI
    OUT     DX, AL                  ; move EOI value to appropriate address
    ;JMP    FinishHandling
    
FinishHandling:
    POPA
    
    IRET
                                    
SerialInterruptHandler    ENDP           

; look at page 18 for info
; read it in to move to the nxt
ModemStatus  PROC        NEAR
             PUBLIC      ModemStatus
             
    MOV     DX, SERIAL_MCR          ; get the MSR address to clear interrupt
    IN      AL, DX                  ; get modem status
    
    RET

ModemStatus  ENDP

Transmitter    PROC       NEAR
              PUBLIC     Transmitter
    
    MOV      SI, OFFSET(tx)
    CALL     QueueEmpty         ; check if the queue is empty
    JZ       EmptyQueue         ; if so bring up kickstart
    JNZ      DequeueQueue       ; otherwise try to dequeue
   
EmptyQueue:
    MOV     kickstart, 1        ; flag kickstart to occur
    JMP     FinishTransmitter   ; and we are done

DequeueQueue:
    CALL    Dequeue             ; dequeue next character in queue
    MOV     DX, SERIAL_THR      ; address of the THR register
    OUT     DX, AL              ; output the dequeued character into THR
    ;JMP    FinishTrasmitter    ; and we are done
    
FinishTransmitter:
    RET
    
Transmitter    ENDP

DataReadyTimeout  PROC    NEAR
                  PUBLIC  DataReadyTimeout
                  
     MOV    DX, SERIAL_RBR      ; address of the RBR register
     IN     AL, DX              ; get the value at RBR
     MOV    AH, EVENT_RBR       ; the event value
     CALL   EnqueueEvent        ; enqueue value and event value at RBR
     
     RET
     
DataReadyTimeout  ENDP

ReceiverLineStatus PROC   NEAR
                   PUBLIC ReceiverLineStatus
              
    MOV     DX, SERIAL_LSR     ; address of the LSR register
    IN      AL, DX             ; read in the value at LSR
    AND     AL, ERROR_MASK     ; get the error generated in LSR
    MOV     AH, EVENT_ERROR    ; the event value
    CALL    EnqueueEvent       ; enqueue the error and event value
    
    RET
              
ReceiverLineStatus ENDP

Jump_Table        LABEL   WORD
                  PUBLIC  Jump_Table
                  
    DW      OFFSET(ModemStatus)          ; modem status interrupt
    DW      OFFSET(Transmitter)          ; transmitter holding register empty
    DW      OFFSET(DataReadyTimeout)     ; receiver data ready/char timeout
    DW      OFFSET(ReceiverLineStatus)   ; receiver line status
    
CODE ENDS    
           
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

tx QUEUE <>                          ; transfer queue that stores data
kickstart DB     ?                   ; keeps track of when to handle interrupts

DATA    ENDS

END