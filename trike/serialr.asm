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
;                        InitSerial         - initializes the serial (public)
;                        SerialPutChar      - loads a char into the serial
;                                             queue (public)
;                        SetBaudRate        - sets the baud rate (public)
;                        SetParity          - sets the parity(public)
;                        SerialEventHandler - uses interrupt 2 to check any
;                                             interrupts happening, the 4 being
;                                             modem, transmitter, data received,
;                                             and line status error.
;                                             when to check for something in the
;                                             queue. Also enqueues errors
;                                             from reading the queue.
;                        
;
; Revision History:
;     11/17/15  Nancy Cao         initial comments and pseudocode
;     11/22/15  Nancy Cao         initial code
;     11/24/15  Nancy Cao         finished coding all functions
;     11/28/15  Nancy Cao         fixed critical code issues
;     11/30/15  Nancy Cao         updated comments

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
; Description: This function initializes the serial. The LCR and the IER are
;              initialized to SERIAL_SETUP and SERIAL_IN_IRQ. The shared
;              variables are also initialized, including the serial chip, the
;              baud rate, the parity, and the serial counter used for the event
;              handler.
;
; Operation:   This function first initializes the serial chip registers LCR and
;              IER to SERIAL_SETUP (which sets it up the serial to access rx/tx
;              data registers, have no break point, no parity, one stoP bit, and
;              eight data bits) and SERIAL_IN_IRQ (which enables the four
;              interrupts: modem, transmitter, receiver line status, and data
;              ready), respectfully. The baud rate is set to be DEFAULT_BAUD,
;              and the parity is set to be DEFAULT_PARITY. The kickstart flag is
;              set to 0, since there are no interrupts.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: baud - the baud rate of the serial (w)
;                   parity - the parity of the serial (w)
;                   kickstart - the flag that handles interrupts (w)
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
; Registers Changed: None.
;
; Author: Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao        initial comments and pseudocode
;     11/22/15  Nancy Cao        initial code and updated comments
;     11/30/15  Nancy Cao        updated comments
;

InitSerial          PROC        NEAR
                    PUBLIC      InitSerial

Init82050:                          ; initialize the 82050 serial chip
    MOV     DX, SERIAL_LCR          ; serial LCR address
    MOV     AL, SERIAL_SETUP        ; the value to put to LCR
    OUT     DX, AL                  ; write SERIAL_SETUP to SERIAL_LCR

    MOV     DX, SERIAL_IER          ; serial IER address
    MOV     AL, SERIAL_IN_IRQ       ; the value to put into IER
    OUT     DX, AL                  ; writes SERIAL_IN_IRQ to SERIAL_IER
                                    ; which turns on the 4 interrupts
	;JMP    SetSerial               ; set the rest of the serial

SetSerial:                          ; set serial parameters
    MOV     BX, DEFAULT_BAUD        ; the index of the default Baud rate divisor
    SHL     BX, 1                   ; must shift left since reading word table
    CALL    SetBaudRate             ; set the baud rate divisor
    MOV     BX, DEFAULT_PARITY      ; the index of the default parity
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
; Description:       This function takes in an eventValue, which is either a
;                    character or an error code. The character/error code is
;                    enqueued. If the character/error code is successfully
;                    enqueued, the carry flag is reset; otherwise it is set,
;                    meaning the queue was full. If a character in enqueued,
;                    the function checks the kickstart and determines if ETBE
;                    should be disabled and then enabled again.
;
; Operation:         The function first checks if the queue is full. If it is,
;                    the carry flag is set, and no character is enqueued, since
;                    there is no space. Otherwise, the function will enqueue the
;                    character and check kickstart. If the kickstart is set,
;                    the ETBE is disabled and then enabled again before the
;                    kickstart is unset and the flag is unset.
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
; Registers Changed: Carry flag, AX, DX, SI
;
; Author:            Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

SerialPutChar    PROC        NEAR
                 PUBLIC      SerialPutChar

CheckQueueFull:
    MOV SI, OFFSET(tx)    ; pass in address of the transfer queue at DS:SI
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
    JZ  DisableETBE       ; if so, disable ETBE
    JMP FinishPutChar     ; otherwise we are done

DisableETBE:
    MOV DX, SERIAL_IER        ; address of SERIAL_IER
	IN  AL, DX                ; read in the value stored in IER to disable
    AND AL, DISABLE_ETBE_MASK ; clear the ETBE bit in the value
    OUT DX, AL                ; put the value back into IER to disable
    ;JMP EnableETBE           ; enable the ETBE again
 
EnableETBE:
    MOV kickstart, 0          ; reset kickstart
    IN AL, DX                 ; read in the value from IER
    OR AL, ENABLE_ETBE_MASK   ; set the ETBE bit in the value
    OUT DX, AL                ; put value back into IER to enable
    JMP FinishPutChar         ; finished with kickstarting
				
SetCarryFlag:
    STC                   ; set the carry flag to indicate char was not put
	JMP Finish

FinishPutChar:
    CLC                   ; unset the carry flag to indicate that a char was
	                      ; put into the queue
    ;JMP Finish
                          
Finish:
	RET
	
SerialPutChar           ENDP

; SetBaudRate
;
; Description:       This function sets the baud rate parameter to its
;                    appropriate value.
;
; Operation:         The function first disables the interrupts to handle the
;                    critical code. It changes the value in LCR to set the baud
;                    bit. It also sets the DLM and the DLL by shifting the high
;                    bit to low bit. It then looks up the baud table to
;                    determine the baud rate divisor. Afterwards, the DLAB is
;                    then reset and the baud is disabled.
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
; Registers Changed: flags, AX, DX
;
; Author:            Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/16  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

SetBaudRate      PROC        NEAR
                 PUBLIC      SetBaudRate
   
    PUSHF                 ; save flags
    CLI                   ; disable interrupts because critical code
    
SetDLAB:      
    MOV     DX, SERIAL_LCR          ; get the LCR address to talk to it
    IN      AL, DX                  ; read in the value from LCR
    OR      AL, ENABLE_BAUD_MASK    ; change baud bit to be set
    OUT     DX, AL                  ; sets DLAB
    ;JMP    WriteBaudDivisor
    
SetDLM:
    PUSH AX
    MOV AL, AH                      ; move the high bit to the low bit
    MOV DX, SERIAL_DLM              ; get the address of DLM
    OUT DX, AL                      ; write in the new value
    POP AX
    
SetDLL:
    MOV DX, SERIAL_DLL              ; get the address of DLL
    OUT DX, AL                      ; write in the new value
    
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
    POPF                   ; retreive flags
    RET

SetBaudRate           ENDP

; SetParity
;
; Description:       This function sets the parity parameter to its appropriate
;                    value.
;
; Operation:         This function reads the current setup in the LCR and resets
;                    it, then looks up the specified parity in the parity table
;                    before setting it in the LCR value. The new value is then
;                    put back in the LCR.
;
; Arguments:         index (BX) - the index of the parity from the parity table
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
; Registers Changed: flags, AX, DX
;
; Author:            Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

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
; Description:       This function handles the 4 interrupts: modem, transmitter,
;                    data ready, and receiver line status. The interrupts are
;                    handled via a jump table with level triggering. After the
;                    interrupt is handled, an EOI value is sent to the EOI
;                    address.
;
; Operation:         The function first reads the value stored in the IIR.
;                    If any interrupt bits are set, the function looks at the
;                    appropriate handler function for the specific interrupt via
;                    the jump table. Afterwards, an EOI vaue is sent to the EOI.
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
; Registers Changed: AX, DB, DX
;
; Author:            Nancy Cao
; Revision History:
;     11/17/15  Nancy Cao   initial comments and pseudocode
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

SerialInterruptHandler   PROC        NEAR
                         PUBLIC      SerialInterruptHandler

    PUSHA                           ; save all registers and flags
    
    MOV     DX, SERIAL_IIR          ; get the IIR address to see interrupt
    IN      AL, DX                  ; read in the value in IIR
    AND     AL, IIR_MASK            ; check the bits to see interrupt occurred
    CMP     AL, 1                   ; check if an interrupt occurred
    JE      FinishHandling          ; if no interrupt occurred end
    ;JMP    ContinueHandling        ; otherwise continue
    
ContinueHandling:
    MOV     BL, AL                  ; make IIR an index for the jump table
    MOV     BH, 0                   ; clear the higher bit of BX for accurate
                                    ; index
    CALL    CS:Jump_Table[BX]	    ; calls function to clear specific interrupt
    
    MOV     DX, EOI                 ; address of EOI
    MOV     AX, EOI_VALUE           ; the value that should be in EOI
    OUT     DX, AL                  ; move EOI value to appropriate address
    ;JMP    FinishHandling
    
FinishHandling:
    POPA                            ; pop all registers and flags
    
    IRET
                                    
SerialInterruptHandler    ENDP

; ModemStatus
;
; Description:       This function handles the modem status interrupt by
;                    looking up the status of the modem control
;                    register and getting the current status. This must be
;                    read to move on to the other interrupts.
;
; Operation:         The function simply reads in the status of the modem stored
;                    in MSR.
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
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

ModemStatus  PROC        NEAR
             PUBLIC      ModemStatus
             
    MOV     DX, SERIAL_MCR          ; get the MSR address to clear interrupt
    IN      AL, DX                  ; get modem status
    
    RET

ModemStatus  ENDP

; Transmitter
;
; Description:       This function handles the trasmitter interrupt by
;                    attempting to dequeue from the queue. If the queue
;                    is empty, the kickstart is just set for the next character.
;                    If not, a character is dequeued from the event queue and
;                    put into the THR.
;
; Operation:         The function first checks if the queue is empty. If so,
;                    it will set the kickstart and return. Otherwise, it will
;                    dequeue the next character in the queue, and put the
;                    dequeued character into THR.
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
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

Transmitter    PROC       NEAR
              PUBLIC     Transmitter
    
    MOV      SI, OFFSET(tx)     ; pass in address of the transfer queue at DS:SI
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

; DataReadyTimeout
;
; Description:       This function looks up the value stored in RBR and
;                    add it to the event queue.
;
; Operation:         The function reads in the value from the RBR register
;                    and passes it into the event queue along with the event
;                    value by using the EnqueueEvent function.
;                    
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
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

DataReadyTimeout  PROC    NEAR
                  PUBLIC  DataReadyTimeout
                  
     MOV    DX, SERIAL_RBR      ; address of the RBR register
     IN     AL, DX              ; get the value at RBR
     MOV    AH, EVENT_RBR       ; the event value
     CALL   EnqueueEvent        ; enqueue value and event value at RBR
     
     RET
     
DataReadyTimeout  ENDP

; ReceiverLineStatus
;
; Description:       This function looks up the value in the LSR to see if there
;                    is an error that occured. If so, the error is
;                    stored into the event queue.
;
; Operation:         The function first reads in the value of the LSR, and
;                    masks out the error bits. If an error occured, the error
;                    is enqueued aong with the event value for errors.
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
;     11/24/15  Nancy Cao   initial code
;     11/30/15  Nancy Cao   updated comments

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