;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  KEYPAD.INC                                ;
;                              KEYPAD Definitions                            ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the keypad functions.
;

; Addresses

KEY_ROW_ONE            EQU 80H  ; address of the 1st row of the keypad

; General definitions

DEBOUNCE_COUNTER_START EQU 100      ; # times key debounces to be pressed
DEFAULT_ROW_VALUE      EQU 0fH      ; the default value when no keys are pressed
KEY_PRESS_MASK         EQU 0fH      ; used to mask out the higher bit of key pad byte input
KEY_EVENT              EQU 1H       ; the key event to pass to the EnqueueEvent
KEYS_PER_ROW           EQU 4        ; the number of keys per key rows
KEYS_PER_ROW_BIT       EQU 2        ; the number of keys per row bit
NUM_ROWS               EQU 4        ; the number of rows on the keypad
REPEAT_RATE            EQU 500      ; the auto repeat constant (2 Hz)
STARTING_ROW_INDEX     EQU 0        ; the starting row index of the row