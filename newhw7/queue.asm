NAME    QUEUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    QUEUE                                   ;
;                               Queue Functions                              ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for a queue. The
;                    public functions included are:
;                        QueueInit  - initalizes a queue from given starting
;                                     address, including pointers to the head
;                                     and tail of the queue, length of queue,
;                                     and size of elements
;                        QueueEmpty - sets zero flag if queue is empty
;                        QueueFull  - sets zero flag if queue is full
;                        Dequeue    - removes the element at the head of the
;                                     queue and returns that element
;                        Enqueue    - adds an element to the tail of the
;                                     queue
;
; Revision History:
;     10/20/15  Nancy Cao         initial comments and pseudocode
;     10/24/15  Nancy Cao         initial writeup
;     10/25/15  Nancy Cao         updated comments
;     10/25/15  Nancy Cao         fixed use of low/high bits of registers
;     10/25/15  Nancy Cao         fixed dequeue and enqueue to store and
;                                 return elements correctly
;     10/25/15  Nancy Cao         simplified code for efficiency, used AND for
;                                 modding

; local include files
$INCLUDE(QUEUE.INC)           ; length of queue and the queue struct definition

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; QueueInit
;
; Description:       This function takes in an address, a length, an
;                    element size, and initializes the queue. The
;                    queue structure is initialized to the location of
;                    the address. The queue contains a pointer that points
;                    to the head of the queue, and another pointer that
;                    points to the end/tail of the queue. The length and
;                    element size is also stored within the queue.
;
; Operation:         The function takes in an address from SI, where the
;                    queue should be initialized; a length from AX, which
;                    is how big the array of the queue should be in bytes;
;                    and size of an element, either a byte or a word (the
;                    size is either 0, indicating a byte, or 1, indicating
;                    a word). The function stores the indicies of the head
;                    and tail pointers to the array which is part of the
;                    queue struct. The head pointer points to the next value
;                    to be removed from the queue. The tail pointer points to
;                    the last value to be removed from the queue. It then
;                    stores the length of the queue. Afterwards, it reads the
;                    size flag. If the flag is 0, 1 is stored as the size (for
;                    1 byte). If the flag is 1, 2 is stored as the size (for a
;                    word or 2 bytes). A byte is left empty; it is needed to
;                    be able to determine if queue is empty or full.
;
; Arguments:         SI           – the address where the queue struct should
;                                   be initialized
;                    AX           - the length of the queue; the max number of
;                                   items that can be stored in the queue
;                    BL           - the size of one item; can be either a byte
;                                   (s = 0) or a word (s != 0)
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  [SI].headptr - the pointer to head/beginning of queue
;                                   (index of an array)
;                    [SI].tailptr - the pointer to tail/end of queue (index
;                                   of an array)
;                    [SI].len     - the max size of the queue
;                    [SI].s       - the size of elements (1 byte or 2 bytes)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Limitations:       Max length of queue can only be 256 bytes. Queue can
;                    only store bytes or words.
;
; Algorithms:        None.
; Data Structures:   Circular queue structure (with head pointer, tail pointer,
;                    length, size, and array representing the actual queue)
;
; Registers Changed: N/A.
;
; Author: Nancy Cao
; Revision History:
;     10/20/2015     initial comments and pseudocode
;     10/24/2015     initial writeup
;     10/25/2015     updated comments
;     10/25/2015     updated size initalization and comments for it

QueueInit  PROC        NEAR
           PUBLIC      QueueInit
           
SetValues:                           ; set values 
		MOV    [SI].headPtr, 0       ; initialize head to beginning of queue
		MOV    [SI].tailPtr, 0       ; queue empty so set tail to head
		MOV    [SI].len, AX          ; store max length of queue from arg
        CMP    BL, 0                 ; check if byte (BL = 0) or word (BL = 1)
        JZ     ByteElement           ; elements are byte (BL = 0)
        JMP    WordElement           ; otherwise elements are word (BL = 1)
 
ByteElement:                         ; store size based on size flag = 0
        MOV    [SI].s, 1             ; size of element is 1 byte
        JMP    Return                ; finish initalizing

WordElement:                         ; store size based on size flag = 1
        MOV    [SI].s, 2             ; size of element is 1 word (2 byte)
        JMP    Return                ; finish initalizing
        
Return:                              ; time to return
        RET

QueueInit	    ENDP


; QueueEmpty
;
; Description:       This function takes in the address of where the queue
;                    is located, and checks if the queue is empty. The
;                    function will set the zero flag if the queue is empty,
;                    and unset the zero if the queue is not.
;
; Operation:         The function takes an address that points to the queue
;                    and checks if the queue is empty.  In other
;                    words, if its head pointer is the same as its tail
;                    pointer, then there are no elements between them, and
;                    the queue is empty. If the queue is empty, the
;                    zero flag should be set . Otherwise, the queue is
;                    not empty, and the zero flag should be unset.
;
; Arguments:         SI           - the address where the queue should be
;                                   checked if it is empty or not
; Return Value:      None.
;
; Local Variables:   AL           - head pointer to compare with tail pointer
; Shared Variables:  [SI].headptr - the pointer to head of queue
;                    [SI].tailptr - the pointer to tail of queue
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Limitations:       N/A.
;
; Algorithms:        None.
; Data Structures:   Circular queue structure (with head pointer, tail pointer,
;                    length, size, and array representing the actual queue)
;
; Registers Changed: zero flag, AX
;
; Author:            Nancy Cao
; Revision History:
;     10/20/2015     initial comments and pseudocode
;     10/24/2015     initial writeup
;     10/25/2015     pushed and popped registers
;     10/25/2015     updated comments

QueueEmpty      PROC        NEAR
                PUBLIC      QueueEmpty

DetermineEmpty:                  ; determines if there are no elements in queue
        PUSH   AX                ; use AX register

		MOV    AL, [SI].headPtr	 ; AL = head pointer to compare tail pointer
		CMP    AL, [SI].tailPtr  ; set zero flag if head and tail are same
                                 ; head == tail means there are no values
                                 ; between head and tail

        POP    AX                ; free AX register from stack

		RET

QueueEmpty	    ENDP


; QueueFull
;
; Description:       This function takes in an address that points to the queue
;                    and checks if the queue is full. The zero flag is set if
;                    the queue is full, and unset if the queue is not.
;
; Operation:         The function takes an address that points to the queue
;                    and checks if the queue is full. In other
;                    words, if the head pointer is the same as the tail
;                    pointer + size of element stored, then the queue is full,
;                    and the zero flag is set. Otherwise, the queue is not full,
;                    and the zero flag is unset.
;
; Arguments:         SI           - the address where the queue should be
;                                   checked if it is full or not
; Return Value:      None.
;
; Local Variables:   AL           - tail pointer, used to compare with head
; Shared Variables:  [SI].headptr - the pointer to head of queue
;                    [SI].tailptr - the pointer to tail of queue
;                    [SI].s       - size of the queue (byte or word)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Limitations:       None.
;
; Algorithms:        None.
; Data Structures:   Circular queue structure (with head pointer, tail pointer,
;                    length, size, and array representing the actual queue)
;
; Registers Changed: zero flag, AX
;
; Author:            Nancy Cao
; Revision History:
;     10/20/2015     initial comments and pseudocode
;     10/24/2015     initial writeup
;     10/25/2015     fixed use of low/high bits of registers
;     10/25/2015     pushed and popped registers
;     10/25/2015     updated comments

QueueFull      PROC        NEAR
               PUBLIC      QueueFull

DetermineType:
        PUSH   AX                   ; stack AX to prevent overwrite

		MOV    AL, [SI].tailPtr     ; AL = tail pointer to compare head
        ADD    AL, [SI].s           ; add + size for next element's pointer
        AND    AL, LENGTH_TEST
		CMP    [SI].headPtr, AL     ; sets zero flag if tail is right behind
                                    ; head, which means the queue is full

        POP    AX                   ; free AX from stack

		RET

QueueFull	   ENDP


; Dequeue
;
; Description:       This function takes in an address that is the head of
;                    the queue, and tries to remove the value at that address.
;                    If the queue turns out to be empty, the function will
;                    wait until the queue is no longer empty. Then the function
;                    will store the value in the return register AX (if it is a
;                    word) or AL (if it is a byte). It will increment the head
;                    pointer appropriately, wrapping around the queue if it
;                    goes out of bounds.
;
; Operation:         The function has a loop that calls on another function,
;                    QueueEmpty, which checks is the queue is empty. If
;                    QueueEmpty returns a zero flag that has been set, the
;                    queue is empty, and the loop will not exit, since there is
;                    nothing to remove from the queue. Once the queue has a
;                    value (QueueEmpty returns a zero flag that has not been
;                    set), the loop will exit. The function will temporarily
;                    save the head pointer and update to what the next value
;                    of head pointer will be after removal of the current head
;                    pointer. If the head pointer goes out of bounds, the
;                    function will mod the index and wrap it around the queue.
;                    It will also access and save the value stored
;                    at the current head pointer, after it determines whether
;                    a byte or a word, so it knows to whether save it in the
;                    return registers AX or AL. At the end, the current pointer
;                    is assigned the new, calculated pointer from before.
;
; Arguments:         SI           - the address where the queue should be
;                                   checked if it is full or not
; Return Value:      None.
;
; Local Variables:   AL           - tail pointer, used to compare with head
;                    BX           - copy of head pointer to access array
;                    CL           - copy of head pointer to update
; Shared Variables:  [SI].headptr - the pointer to head of queue
;                    [SI].tailptr - the pointer to tail of queue
;                    [SI].s       - size of the queue (byte or word)
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Limitations:       None.
;
; Algorithms:        None.
; Data Structures:   Circular queue structure (with head pointer, tail pointer,
;                    length, size, and array representing the actual queue)
;
; Registers Changed: zero flag, AX, BX, CX
;
; Author:            Nancy Cao
; Revision History:
;     10/20/2015     initial comments and pseudocode
;     10/24/2015     initial writeup
;     10/25/2015     fixed use of low/high bits of registers
;     10/25/2015     updated comments
;     10/25/2015     changed code to actually access array

Dequeue        PROC        NEAR
               PUBLIC      Dequeue
			   
EmptyQueue:                                ; check if queue is empty
        CALL   QueueEmpty                  ; use defined function to check
        JZ     EmptyQueue                  ; loop until queue is not empty, or
                                           ; pointers will be messed up
        JNZ    UpdateHeadPointer           ; queue has a value to remove now

UpdateHeadPointer:                         ; increment head pointer
        MOV    BH, 0                       ; clear BH from old instructions
        MOV    BL, [SI].headPtr            ; BL = head pointer to access array
        MOV    CL, [SI].headPtr            ; CL = head pointer to update
        ADD    CL, [SI].s                  ; pointer + size for next index
        AND    CL, LENGTH_TEST             ; mod headptr, in case out of bound
                                           ; loop to the beginning of queue
        CMP    [SI].s, 1                   ; determine if element to remove is
                                           ; byte or word
        JZ     ReturnByte                  ; the elements in queue are bytes
        JMP    ReturnWord                  ; the elements in queue are words
    
ReturnByte:                                ; return removed byte
        MOV    AL, [SI].array1Ds[BX]       ; store byte to return register AL
        JMP    Finished                    ; about to return function

ReturnWord:                                ; return removed word
        MOV    AX, Word Ptr [SI].array1Ds[BX] ; store word to return register AX
        JMP    Finished                    ; about to return function

Finished:                                  ; return funtion
        MOV [SI].headPtr, CL               ; set head pointer after increment
        
		RET

Dequeue	       ENDP
		
; Enqueue
;
; Description:       This function takes in an address that is the tail of
;                    the queue, and tries to add the value stored in either AX
;                    (if it is a word) or AL (if it is a byte) at that address.
;                    If the queue turns out to be full, the function will
;                    wait until the queue is no longer full. Then the function
;                    will add the value from register AX (if it is a
;                    word) or AL (if it is a byte) onto the tail of the queue,
;                    and increment the tail pointer appropriately, wrapping
;                    around the queue if necessary, if it goes out of bounds.
;
; Operation:         The function has a loop that calls on another function,
;                    QueueFull, which checks is the queue is full. If
;                    QueueFull returns a zero flag that has been set, the
;                    queue is full, and the loop will not exit, since there is
;                    no space to add to the queue. Once the queue has space,
;                    (QueueFull returns a zero flag that has not been
;                    set), the loop will exit. The function will temporarily
;                    save the tail pointer and update to what the next value
;                    of tail pointer will be after removal of the current head
;                    pointer. If the tail pointer goes out of bounds, the
;                    function will mod the index and wrap it around the queue.
;                    It will also access and save the value stored
;                    at the current head pointer, after it determines whether
;                    a byte or a word, so it knows to whether save it in AX
;                    or AL. At the end, the current pointer is assigned the new,
;                    calculated pointer from before.
;
; Arguments:         SI           - the address where the tail of the queue
;                                   should be
;                    AL           - the byte that is to be added to the tail
;                                   of queue OR
;                    AX           - the word that is to be added to the tail
;                                   of queue
; Return Value:      None.
;
; Local Variables:   AL           - tail pointer, used to compare with head
;                    BX           - copy of tail pointer to access array
;                    CL           - copy of tail pointer to update
; Shared Variables:  [SI].headptr - the pointer to head of queue
;                    [SI].tailptr - the pointer to tail of queue
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   Circular queue structure (with head pointer, tail pointer,
;                    length, size, and array representing the actual queue)
;
; Author:            Nancy Cao
;     10/20/2015     initial comments and pseudocode
;     10/24/2015     initial writeup
;     10/25/2015     fixed use of low/high bits of registers
;     10/25/2015     updated comments
;     10/25/2015     changed code to actually access array

Enqueue        PROC        NEAR
               PUBLIC      Enqueue
			   
FullQueue:                                 ; check if queue is full
        CALL   QueueFull                   ; check if queue is full
		JZ     FullQueue                   ; loop until queue is not full
		JNZ    AddElement                  ; queue has space now to add elements
		
AddElement:                                ; add element at tail of queue        
        MOV    BH, 0                       ; clear BH from old instructions
        MOV    BL, [SI].tailPtr            ; BL = tail pointer to access array
        MOV    CL, [SI].tailPtr            ; CL = tail pointer to update
        ADD    CL, [SI].s                  ; pointer + size for next index
        AND    CL, LENGTH_TEST             ; mod tailptr, in case out of bound
                                           ; loop to the beginning of queue
        CMP    [SI].s, 1                   ; determine if element to add is
                                           ; byte or word
        JZ     AddByte                     ; the elements in queue are bytes
        JMP    AddWord                     ; the elements in queue are words

AddByte:                                   ; add byte to end of queue
        MOV    [SI].array1Ds[BX], AL          ; access AL value and add to tail
		JMP    FinishUpdate                ; about to return function
        
AddWord:                                   ; add word to end of queue
        MOV    Word Ptr [SI].array1Ds[BX], AX ; access AX value and add to tail
        JMP    FinishUpdate                ; about to return function
		
FinishUpdate:                              ; return function
        MOV    [SI].tailPtr, CL            ; set head pointer after increment
        
        RET

Enqueue        ENDP

CODE    ENDS

        END
