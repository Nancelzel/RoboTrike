;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  PARSER.INC                                ;
;                               Parser Definitions                           ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the serial parser functions.
; Revision History:
;      12/21/15  Nancy Cao    initial code and comment
;

; State definitions
;    note that these MUST match the layout of the transition table

ST_INITIAL      EQU   0   ; initial state
ST_ABS_SPEED    EQU   1   ; set absolute speed
ST_REL_SPEED    EQU   2   ; set relative speed
ST_DIRECTION    EQU   3   ; set direction of movement
ST_ROTATE       EQU   4   ; rotate turret 
ST_ELEVATE      EQU   5   ; elevate turret
ST_LASER_ON     EQU   6   ; fire laser
ST_LASER_OFF    EQU   7   ; turn laser off
ST_SIGN         EQU   8   ; set sign of number parsed
ST_DIGIT        EQU   9   ; append digit
ST_ERROR        EQU   10  ; error state
ST_END          EQU   11  ; end state

; Token Type Definitions
;    note that these MUST match the layout of the transition table

TOKEN_ABS_SPEED EQU   0  ; 'S'
TOKEN_REL_SPEED EQU   1  ; 'V'
TOKEN_DIRECTION EQU   2  ; 'D'
TOKEN_ROTATE    EQU   3  ; 'T'
TOKEN_ELEVATE   EQU   4  ; 'E'
TOKEN_LASER_ON  EQU   5  ; 'F'
TOKEN_LASER_OFF EQU   6  ; 'O'
TOKEN_SIGN      EQU   7  ; '+' or '-'
TOKEN_DIGIT     EQU   8  ; '0' to '9'
TOKEN_RETURN    EQU   9  ; '<RETURN>'
TOKEN_SPACE     EQU   10 ; ' '
TOKEN_OTHER     EQU   11 ; other possible tokens

NUM_TOKEN_TYPES EQU   12 ; number of token types

; Get Token
TOKEN_MASK	    EQU	  01111111B	;mask high bit of token

; Command Definitions

NO_COMMAND      EQU   -1
SET_ABS_SPEED   EQU   0
SET_REL_SPEED   EQU   1
SET_DIRECTION   EQU   2
ROTATE          EQU   3
SET_ELEVATION   EQU   4
SET_LASER_ON    EQU   5
SET_LASER_OFF   EQU   6
                  
; general definitions

NO_ERROR        EQU   0   ; flag for no parser error
OVERFLOW_ERROR  EQU   1   ; flag for overflow error
CHAR_ERROR      EQU   2   ; flag for character errors

UNSIGNED        EQU   0   ; flag for unsign value
POSITIVE        EQU   1   ; flag for positive
NEGATIVE        EQU   -1  ; flag for negative

MIN_SPEED       EQU 0           ; the speed of the RoboTrike at rest
MAX_SPEED       EQU 65534       ; the fastest the RoboTrike can travel
MIN_ELEVATION   EQU   -60       ; the lowest the turret can go
MAX_ELEVATION   EQU   60        ; the highest the turret can go
IGNORE_SPEED    EQU   65535     ; current speed shouldn't change
IGNORE_DEGREE   EQU   -32768    ; current degree shouldn't change
LASER_OFF       EQU   0         ; flag for laser is off
LASER_ON        EQU   1         ; flag for Laser on