NAME    EVENTQ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 EventQueue                                 ;
;                       RoboTrike EventQueue Functions                       ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the event queue functions used
;                    by the RoboTrike. The public functions included are:
;                        InitEventQueue     - initializes the event queue
;                                             (public)
;                        EnqueueEvent       - enqueues an event (public)
;                        DequeueEvent       - dequeues an event (public)
;                        
;
; Revision History:
;     12/01/15  Nancy Cao         initial comments and pseudocode
;     12/25/15  Nancy Cao         initial code and updated comments

; local include files
$INCLUDE(QUEUE.INC)         ; queue constants used for the queue

EXTRN QueueInit:NEAR        ; used to initialize the queue, set the head and the
                            ; tail at appropriate locations
EXTRN QueueEmpty:NEAR       ; used to check if the queue is empty
EXTRN QueueFull:NEAR        ; used to check if the queue is full
EXTRN Dequeue:NEAR          ; used to remove an element from the queue and return
                            ; that element if the queue is not already empty
EXTRN Enqueue:NEAR          ; used to put an element into the queue if the queue
                            ; is not already full
EXTRN SetCriticalError:NEAR ; sets a critical error
                          


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; InitEventQueue
; 
; Description: This function initializes the event queue. The address, type of
;              event queue (byte or word), and length of the queue is
;              initialized.
;
; Operation:   This function sets the address to be the address of the event
;              queue. It sets the event queue to be of type word, and the length
;              of the queue to be LENGTH_TEST. The event queue is initialized
;              by calling the QueueInit.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: q - the event queue (DS, W)
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
; Registers Changed: SI, BX, CX
;
; Author: Nancy Cao
; Revision History:
;     12/25/15  Nancy Cao        initial code and comments
;

InitEventQueue          PROC        NEAR
                        PUBLIC      InitEventQueue

    MOV     SI, OFFSET(q)           ; pass in address of q at DS:SI
    MOV     BX, 1                   ; make event queue a word queue
    MOV     CX, LENGTH_TEST         ; pass in length of event queue
    CALL    QueueInit               ; initialize q event queue

    RET
    
InitEventQueue    ENDP

; EnqueueEvent
;
; Description:       This function enqueues the next event to the event queue
;                    if the event queue is not yet full. If it is full, a
;                    critical error is set instead.
;
; Operation:         The function first checks if the event queue is full. If
;                    it is, a critical error is set, and the function returns
;                    without enqueuing the event. Otherwise, the event is
;                    enqueued before the function returns.
;
; Arguments:         eventValue (AL) - the event value
;                    eventType  (AH) - the event type
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  q - the event queue (DS, R/W)
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
; Registers Changed: Zero flag, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/25/15  Nancy Cao   initial code and comments

EnqueueEvent     PROC        NEAR
                 PUBLIC      EnqueueEvent

FullQueue:                  ; check if the event queue is full
    MOV    SI, OFFSET(q)    ; get the address of the event queue
    CALL   QueueFull        ; check if the event queue is full
    JZ     CriticalError    ; if zero flag is set event queue is full, must
                            ; set critical error
    JNZ    AddEvent         ; otherwise go ahead and enqueue the event
    
CriticalError:              ; set a critical error because of full event queue
    CALL   SetCriticalError
    JMP    FinishEnqueue
    
AddEvent:                   ; enqueue the event
    CALL   Enqueue          ; enqueues the event
    ;JMP   FinishEnqueue
    
FinishEnqueue:
    RET
	
EnqueueEvent     ENDP

; DequeueEvent
;
; Description:       This function dequeues the next event in the event queue
;                    if the event queue is not empty. If it is empty, the
;                    function does nothing.
;
; Operation:         The function first checks if the event queue is empty. If
;                    it is, the function returns without dequeuing any events.
;                    Otherwise, an event is dequeued and returned.
;
; Arguments:         None.
; Return Value:      eventValue (AL) - the event value
;                    eventType  (AH) - the event type
;
; Local Variables:   None.
; Shared Variables:  q - the event queue (DS, R/W)
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
; Registers Changed: Zero flags, SI
;
; Author:            Nancy Cao
; Revision History:
;     12/25/15  Nancy Cao   initial comments and pseudocode

DequeueEvent     PROC        NEAR
                 PUBLIC      DequeueEvent

EmptyQueue:                 ; check if the event queue is empty
    MOV    SI, OFFSET(q)    ; get the address of the event queue
    CALL   QueueEmpty       ; check if the event queue is empty
    JZ     FinishDequeue    ; if zero flag is set event queue is empty, so do
                            ; nothing
    ;JNZ    RemoveEvent     ; otherwise go ahead and dequeue the next event
    
RemoveEvent:                ; dequeue the next event
    CALL   Dequeue          ; dequeues the next event, event value/type stored
                            ; in AX to return
    ;JMP   FinishDequeue
    
FinishDequeue:
    RET
                 
DequeueEvent     ENDP

CODE ENDS    
           
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

q QUEUE <>                          ; the event queue that keeps track of event
                                    ; value and type

DATA    ENDS

END