NAME    KEYPAD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    KEYPAD                                  ;
;                          RoboTrike Keypad Functions                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    keypad. The public functions included are:
;                        InitKeypad        -  initializes the RoboTrike Keypad
;                                             by clearing out whatever was
;                                             previously displayed on the board
;                        Keyscan            - 
;
; Revision History:
;     11/03/15  Nancy Cao         initial comments and pseudocode
;     11/08/15  Nancy Cao         added code and comment
;     11/10/15  Nancy Cao         added masking to the higher bit of key pressed
;     11/11/15  Nancy Cao         fixed row incrementing issues

; local include files
$INCLUDE(KEYPAD.INC)        ; display constants ASCII / mux buffer definition

EXTRN EnqueueEvent:NEAR          ; used to initialize chip select

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP


; InitKeypad
; 
; Description: This function initializes the 16-key keypad by resetting
;              the counter that keeps track of debounced keys to
;              DEBOUNCE_COUNTER_START and the index of the current row to
;              examine for pressed keys to be 0, the beginning.
;
; Operation:   The function resets the counter to DEBOUCNE_COUNTER_START, and
;              sets the current row index to be 0 for the 16-key keypad.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: debouncedCounter - keeps track of how long a key has been
;                                      pressed down
; Global Variables: None.
;
; Input:  None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: There are only 16 keys, 4 keys for each of the 4 rows.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: None.
;
; Author: Nancy Cao
; Revision History:
;     11/07/15  Nancy Cao        initial comments and pseudocode
;     11/08/15  Nancy Cao        added code and updated comments

InitKeypad   PROC        NEAR
             PUBLIC      InitKeypad

    PUSH BX
             
InitializeCounters:                           ; initialize counters
    CMP BX, KEYS_PER_ROW                      ; see if we finished last key
    JZ  FinishInitializeCounters              ; if yes all row counters done
    
    MOV debounceCounter[BX], DEBOUNCE_COUNTER_START ; otherwise keep setting
                                                    ; debounceCounter to
                                                    ; DEBOUNCE_COUNTER_START
    INC BX                                          ; go to the next element
                                                    ; in debounceCounter
    
FinishInitializeCounters:                           ; everything initialized
    MOV currentRow, STARTING_ROW_INDEX             ; set the row index to
                                                    ; STARTING_ROW_INDEX
    POP BX                                          ; return value to register
    RET


InitKeypad       ENDP


; Keyscan
; 
; Description: This function either checks for a new key(s) being pressed on the 
;              current row if none is currently pressed or debounces the
;              currently pressed key(s). If it debounces a key it calls the
;              EnqueueEvent function, which will store the key events and key
;              values into a buffer called EventBuf.
;
; Operation:   This function retreives the address of the current row to
;              examine, and retreives the value of the current row. If the
;              value of the current row equals the DEFAULT_ROW_VALUE, then none
;              of the values in that row are being pressed, and the function can
;              just move onto the next row and finish. If the current row does
;              not equal DEFAULT_ROW_VALUE, then at least one key is being
;              pressed in the current row. If this is the case, the debounced
;              counter is decremented. If the counter does not reach 0, then the
;              key(s) in the row have not been pressed long enough, so the
;              the function just returns without moving on (since the function
;              needs to reexamine the same row over and over again until
;              debouncing happens on the keys). If the counter does reach 0,
;              then the key(s) in the row have been debounced. In this case, the
;              function goes through every key in the row, and decides if the
;              lowest bit key is pressed or not pressed before moving onto the
;              next lowest bit. If the key is pressed, the key event and the key
;              value (which is the number of the key) is passed into the
;              EnqueueEvent function, which stores these two values next to each
;              other into a buffer called EventBuf. Afterwards, debouncing is
;              done, the keys are successfully registered as presses, and
;              the function increments to the next row to examine if any keys
;              are being pressed there.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  key_event (AH)  - the key event of the key being pressed
;                   key_value (AL)  - the key value of the key being pressed
; Shared Variables: debouncedBuffer - keeps track of which keys are being
;                                     pressed and debounced.
;                   EventBuf        - stores key events and key values
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
; Data Structures: Arrays (EventBuf)
;
; Registers Changed: AX
;
; Author: Nancy Cao
; Revision History:
;     11/03/15  Nancy Cao        initial comments and pseudocode
;     11/08/15  Nancy Cao        added code and updated comments
;     11/10/15  Nancy Cao        cleared out higher bit of key press byte
;     11/11/15  Nancy Cao        fixed row incrementing issues

Keyscan      PROC        NEAR
             PUBLIC      Keyscan

    PUSH AX
    PUSH DX
    
CheckKeyValue:
    MOV  DH, 0                            ; clear higher bit of DX for accurate
                                          ; address
    MOV  DL, currentRow                   ; set index of the current row to
                                          ; lower bit of DX for the IN instruct.
    ADD  DL, KEY_ROW_ONE                  ; find the appropriate address for row
    IN   AL, DX                           ; check the keys on current row
    AND  AL, KEY_PRESS_MASK               ; clear higher bit of key press byte
    CMP  AL, DEFAULT_ROW_VALUE            ; check if keys are being pressed
    JE   FinishedRow                      ; if not there is no debouncing
    JNE  KeysPressed                      ; if yes debounce on the keys

KeysPressed:
    DEC  debounceCounter                  ; decrement the debounce counter
    JZ   StartKeyDebounced                ; if counter now 0, debouncing has
                                          ; happened. must find the keys that
                                          ; are pressed, set event/values and
                                          ; call EnqueueEvent
    JNZ  Finished                         ; otherwise we are done

StartKeyDebounced:
    MOV  CL, 0                            ; start looking at first key in row
    NOT  AL                               ; flip all the bits to test each bit
    JMP  KeyDebounced                     ; check which keys to enqueue
    
KeyDebounced:
    CMP  CL, KEYS_PER_ROW                 ; check if all keys on row are looked
    JE   FinishedDebounce                 ; if yes done finding pressed keys
    
    TEST AL, 1                            ; otherwise check lowest bit to
                                          ; see if lowest key pressed
    JNZ   EnqueueKey                      ; if key pressed (lowest bit matches 1) add to the EventBuf
    
    SHR  AL, 1                            ; next lowest bit for next key
    INC  CL                               ; increment key index
    JMP  KeyDebounced                     ; look at next key in row

EnqueueKey:
    
    MOV  AH, KEY_EVENT                    ; pass key event to EnqueueEvent
    MOV  DL, currentRow                   ; set index of current row to DL for
                                          ; multiplication
    SHL  DL, KEYS_PER_ROW_BIT             ; multiply current row by KEYS_PER_ROW
    ADD  DL, CL                           ; and add current keys examined figure
                                          ; out the key value pressed
    MOV  AL, DL                           ; pass key value to Enqueue Event
    
    CALL EnqueueEvent                     ; store key event/value into EventBuf
    
    JMP FinishedDebounce
 
FinishedRow:
    INC  currentRow                       ; time to read the next row of keys
    AND  currentRow, NUM_ROWS - 1         ; wrap the index for out of bounds
    MOV  debounceCounter, DEBOUNCE_COUNTER_START ; reset counter for next row
    JMP  Finished
    
FinishedDebounce:
    MOV  debounceCounter, REPEAT_RATE     ; set the repeat rate of key
                                          ; to be REPEAT_RATE
    ;JMP Finished

Finished:    
    POP DX
    POP AX
    
    RET

Keyscan       ENDP

CODE ENDS

;the data segment

DATA    SEGMENT PUBLIC  'DATA'

debounceCounter   DW     ?               ; # times key debounces to be pressed
currentRow        DB     ?               ; the current row to read keys from


DATA    ENDS

END
