NAME    PARSER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   PARSER                                   ;
;                          RoboTrike Parser Functions                        ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the RoboTrike parser functions.
;                    The public functions included are:
;                        InitSerialChar       - initializes the serial char
;                                               processing
;                        ParseSerialChar      - parses the command from serial
;                    The private functions included are:
;                        GetToken             - gets token type/value of current
;                                               char being parsed
;                        SetCommand           - sets the current command
;                        SetSign              - sets the current sign
;                        AddDigit             - appends a digit to current number
;                        CallCommand          - calls the appropriate function
;                                               depending on current command
;                        ThrowError           - sets the appropriate error that
;                                               was thrown
;                        DoNothing            - do nothing for empty transitions
;                        SetAbsoluteSpeed     - sets the absolute speed of the
;                                               RoboTrike
;                        SetRelativeSpeed     - sets the relative speed of the
;                                               RoboTrike
;                        SetDirection         - sets the direction of the
;                                               RoboTrike
;                        RotateTurretAngle    - rotates the turret
;                        SetTurretElevation   - sets turret elevation
;                        TurnLaserOn          - turns on the laser
;                        TurnLaserOff         - turns off the laser
;                    This code also contains these tables:
;                        JumpTable            - a table of addresses for
;                                               functions that act on the
;                                               RoboTrike
;                        StateTable           - a table of transition states
;                        Token Tables         - a table of tokens and their
;                                               corresponding values
;
; Revision History:
;     11/24/15  Nancy Cao         initial comments and pseudocode
;     12/21/15  Nancy Cao         initial code
;     12/23/15  Nancy Cao         finished coding and updated comments

; local include files
$INCLUDE(PARSER.INC)          ;contains constants for the serial parser

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

EXTRN   SetMotorSpeed:NEAR          ; sets the speed and direction of the motors
EXTRN   GetMotorSpeed:NEAR          ; gets the current speed of the motors
EXTRN   GetMotorDirection:NEAR      ; gets the current direction of the motors
EXTRN   SetTurretAngle:NEAR         ; sets the angle of the turret
EXTRN   SetRelTurretAngle:NEAR      ; sets the angle of the turret relative
                                    ; to the current angle
EXTRN   SetTurretElevation:NEAR     ; sets the elevation of the turret
EXTRN   SetLaser:NEAR               ; sets the laser to be on or off
        
; InitSerialChar
;
; Description:       This function initializes the 5 shared variables:
;                    curCommand, curSign, curNumber, curState and curError.
;
; Operation:         This function sets curCommand to be NO_COMMAND, since no
;                    commands are currently being read. It sets the curSign to
;                    be UNSIGNED by default. It sets the curNumber to be 0,
;                    since no number is read yet and when digits are read, they
;                    will be appended to curNumber. It sets the curState to be
;                    ST_INITIAL, the initial state. It sets the current error
;                    to have NO_ERROR.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curCommand - the current command being parsed (DS, W)
;                    curSign    - the current sign of number being parsed (DS, W)
;                    curNumber  - the number being read for current command (DS, W)
;                    curState   - the current state (DS, W)
;                    curError   - the current error (DS, W)
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
;     11/24/15  Nancy Cao   initial comments and pseudocode
;     12/21/15  Nancy Cao   initial code and comments
;     12/23/15  Nancy Cao   updated code and comments

InitSerialChar      PROC        NEAR
                    PUBLIC      InitSerialChar

    MOV    curCommand, NO_COMMAND       ; no command being read yet
    MOV    curSign, UNSIGNED            ; default to unsigned for numbers
    MOV    curNumber, 0                 ; no numbers read from serial yet
    MOV    curState, ST_INITIAL         ; initial state machine to be beginning
    MOV    curError, NO_ERROR           ; currently no errors present
    
    RET

InitSerialChar    ENDP

; ParseSerialChar
;
; Description:       This function re-initializes the parser if the end state
;                    or an error state is reached. It then reads the next token,
;                    which corresponds to the next character read from the
;                    serial, and determines the next state and action to perform
;                    based on the StateTable. A number is returned signifying
;                    any error that occurred while parsing the character.
;
; Operation:         This function first checks the state to make sure that it
;                    is not at the end, meaning the entire command has been
;                    processed successfully, or that the state is not at an
;                    error, meaning that the command read was bad. If either
;                    case occurs, the parser is reset for the next command
;                    read. Otherwise, another token with its type and value is
;                    received via GetToken, which is the representative of the
;                    next character read from the serial. From this token, the
;                    the function determines which state to transition to by
;                    looking up in the StateTable. The state determined based
;                    on the token is re-assigned to the current state.
;                    Afterwards, the action corresponding to the token is
;                    performed. In the end, the current error, if any, is
;                    returned.
;
; Arguments:         c (AL) - the current character to parse
; Return Value:      AX     - status of the parsing operation; NO_ERROR is
;                             returned if there is no parsing error; otherwise
;                             a non-zero value is returned (OVERFLOW_ERROR or
;                             CHAR_ERROR)
;
; Local Variables:   None.
; Shared Variables:  curState - the current state (DS, R/W)
;                    curError - the curret error associated with the character,
;                               if any (DS, R/W)
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
;     11/24/15  Nancy Cao   initial comments and pseudocode
;     12/21/15  Nancy Cao   initial code and comments
;     12/23/15  Nancy Cao   finished code and updated comments
;     12/24/15  Nancy Cao   updated comments
;     01/02/16  Nancy Cao   fixed minor bug to set CL to initial state

ParseSerialChar      PROC        NEAR
                     PUBLIC      ParseSerialChar
          
    PUSH CX
    PUSH DX
    
GetCurrentState:
    MOV CL, curState         ; get the current state of machine
    ;JMP CheckState
                    
CheckState:                  ; check if at end or error state
    CMP CL, ST_END           ; see if at the end state
    JE  ResetSerialChar      ; if so re-initialize serial parser
    
    CMP CL, ST_ERROR         ; see if in the error state
    JE  ResetSerialChar      ; if so re-initialize serial parser
    JMP DoNextToken          ; otherwise look for next token
    
ResetSerialChar:             ; reset shared variables for next command
    CALL InitSerialChar      ; re-initialize
    MOV CL, ST_INITIAL       ; set to initial state
    ;JMP DoNextToken         ; get the next token
    
DoNextToken:                 ; get the next token type and value
    CALL GetToken            ; get the token type and value
    MOV  DH, AH              ; move token type to DH
    MOV  CH, AL              ; move token value to CH
    ;JMP ComputeTransition

ComputeTransition:			 ; figure out what transition to do
    MOV	AL, NUM_TOKEN_TYPES	 ; find row in the table
    MUL	CL                   ; AX is start of row for current state
    ADD	AL, DH               ; get the actual transition
    ADC	AH, 0                ; propagate low byte carry into high byte

    IMUL BX, AX, SIZE TRANSITION_ENTRY   ; now convert to table offset
    ;JMP DoTransition
 
DoTransition:                ; do the transition and move to the next state
	MOV	CL, CS:StateTable[BX].NEXTSTATE ; search for transition in the state
                                        ; table
    MOV curState, CL         ; update the current state
    ;JMP DoAction

DoAction:                         ; do the action
    MOV  AL, CH                   ; get token value and pass as argument
    CALL CS:StateTable[BX].ACTION ; do the action
    ;JMP EndParseSerialChar       ; done

EndParseSerialChar:
    MOV AL, curError              ; return the error from reading the character,
                                  ; if any
    MOV AH, 0                     ; clear higher bit of AX
    
    POP DX
    POP CX
    
    RET
    
                    
ParseSerialChar     ENDP                    

; GetToken
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
;
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX - table pointer, points at lookup tables.
;
; Shared Variables: None.
;
; Global Variables: None.
;
; Input:            None.
;
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
;
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Used:   AX, BX.
;
; Stack Depth:      0 words.
;
; Author:           Glen George
; Last Modified:    Feb. 26, 2003


GetToken        PROC    NEAR


    PUSH BX
    
InitGetToken:				;setup for lookups
	AND	AL, TOKEN_MASK		;strip unused bits (high bit)
	MOV	AH, AL			;and preserve value in AH

TokenTypeLookup:                        ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable	;have token type in AL
	XCHG	AH, AL			;token type in AH, character in AL

TokenValueLookup:			;get the token value
    MOV     BX, OFFSET(TokenValueTable)  ;BX points at table
	XLAT	CS:TokenValueTable	;have token value in AL

EndGetToken:                     	;done looking up type and value
    
    POP BX
    
    RET

GetToken            ENDP


; SetCommand
;
; Description:       This function sets the current command being read from
;                    the parser (indicated by index number).
;
; Operation:         This function takes the current index number set in AL
;                    and sets it to the current command for later lookup in
;                    in the JumpTable to perform the command, if the entire
;                    command is processed successfully.
;
; Arguments:         command (AL) - token value that corresponds to the current
;                                   command character value being parsed
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curCommand - the current command (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetCommand      PROC        NEAR

    MOV curCommand, AL     ; curCommand = command index passed in
    RET

SetCommand      ENDP

; SetSign
;
; Description:       This function sets the current sign of the number being
;                    read from the parser.
;
; Operation:         This function takes the current value set in AL and sets it
;                    to the current sign which will be used later to figure out
;                    whether the number passed in is positive or negative. The
;                    sign can be either UNSIGNED, POSITIVE, or NEGATIVE.
;
; Arguments:         sign (AL) - token value that corresponds to the current
;                                sign character value being parsed
; Return Value:      AX        - flag whether there was an error parsing the
;                                character or not
;
; Local Variables:   None.
; Shared Variables:  curSign - the current sign for the number argument (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetSign      PROC        NEAR

    MOV curSign, AL   ; curSign = sign
    RET

SetSign      ENDP

; AddDigit
;
; Description:       This function appends the current digit parsed to the
;                    current number stored as an argument for the current
;                    command.
;
; Operation:         This function multiplies the current number by 10 so that
;                    a 0 digit is introduced to the number. The function checks
;                    that this size of a number does not result in an overflow.
;                    If it does, an overflow error value is returned to
;                    ParseSerialChar, and the current state is changed to be
;                    an error state. Otherwise, the function checks that the
;                    current number is positive or negative. If it is negative,
;                    the digit is negated first before being appended.
;                    Otherwise, it is appended without being negated.
;                    Afterwards, the function checks again if there is overflow
;                    after appending it. If yes, an overflow error value is
;                    returned to ParseSerialChar. The current state is changed
;                    to be an error state. Otherwise, no error is returned and
;                    the digit is appended successfully.
;
; Arguments:         digit (AL) - token value that corresponds to the current
;                                 digit value being parsed
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curSign   - the sign for the current umber argument (DS, R)
;                    curNumber - the current number argument for the command (DS, W)
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
;     12/24/15  Nancy Cao   updated comments
;     01/02/16  Nancy Cao   fixed to check negative sign

AddDigit      PROC        NEAR

CreateNewDigitSpace:
    MOV  BL, AL           ; store digit that will be appended to the number
    MOV  AX, curNumber    ; the current number moved to AX for multiplication
    MOV  CX, 10           ; to multiply the current number with to create a new
                          ; digit space
    MOV  DX, 0            ; clear DX for multiplication
    IMUL CX               ; curNumber = curNumber * 10
    JO   SetOverflowError ; if there is overflow from this action set appropriate
                          ; error
    ;JMP CheckSign        ; otherwise check the sign of the number before
                          ; appending the digit
    
CheckSign:
    MOV BH, 0             ; clear the higher bit of BX
    CMP curSign, NEGATIVE ; check if number if negative
    JNE  AppendDigit      ; go ahead and append the digit if not negative
    ;JMP NegateDigit      ; otherwise negate the digit first before appending it

NegateDigit:
    NEG BX                ; negate the digit
    ;JMP AppendDigit      ; append the digit
                          
AppendDigit:              ; append digit to the current number
    ADD AX, BX            ; attempt to append digit to the current number
    JO SetOverflowError   ; if there is overflow from this action set appropriate
                          ; error
    MOV curNumber, AX     ; curNumber = the new number with appended digit
    JMP FinishAddDigit    ; we are done
    
SetOverflowError:                ; set error to overflow
    MOV curState, ST_ERROR       ; go to error state
    MOV curError, OVERFLOW_ERROR ; change current error to overflow error
    JMP FinishAddDigit           ; we are done

FinishAddDigit:
    RET

AddDigit      ENDP

; CallCommand
;
; Description:       This function calls the appropriate command from the
;                    JumpTable according to the index stored in curCommand.
;
; Operation:         The current command is taken and shifted appropriately to
;                    convert from byte index to word index since JumpTable is a
;                    word table. Afterwards, the command is looked up in the
;                    JumpTable and called. The current state is set to be at the
;                    ending state, since the command was executed successfully.
;
; Arguments:         digit (AL) - token value that corresponds to the current
;                                 digit value being parsed
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curCommand - the command to execute (DS, R)
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
;     12/24/15  Nancy Cao   updated comments

CallCommand      PROC        NEAR

GetCommandIndex:
    MOV  BL, curCommand          ; get the current command index
    MOV  BH, 0                   ; clear higher bit of BX
    SHL  BX, 1                   ; shift left by one since function jump
                                 ; table is a word
    ;JMP CallFunction
    
CallFunction:
    CALL CS:JumpTable[BX]        ; find the current function to call
    RET                             

CallCommand    ENDP

; ThrowError
;
; Description:       This function sets the error to be a parser character
;                    error.
;
; Operation:         This function sets the error to be a CHAR_ERROR.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curError - the current error (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

ThrowError      PROC        NEAR

    MOV curError, CHAR_ERROR   ; curError = CHAR_ERROR
    RET

ThrowError    ENDP

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

; SetAbsoluteSpeed
;
; Description:       This function sets the speed of the motor without changing
;                    the direction of the motor, and no error is returned.
;
; Operation:         This function takes the current number and makes it the
;                    argument for SetMotorSpeed function. The angle of the
;                    RoboTrike is set to be IGNORE_DEGREE. Afterwards,
;                    the state is changed to be at the end state and no errors
;                    are returned.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curNumber  - the number being read for current command (DS, R)
;                    curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetAbsoluteSpeed      PROC        NEAR

CallSetMotorSpeed:
    MOV     AX, curNumber       ; get the current number that is the speed
                                ; as an argument to SetMotorSpeed
    MOV     BX, IGNORE_DEGREE   ; motor angles remain unchanged, passed as an
                                ; argument to SetMotorSpeed
    CALL    SetMotorSpeed       ; set motor speeds

    RET

SetAbsoluteSpeed      ENDP

; SetRelativeSpeed
;
; Description:       This function sets the speed of the motor relative to the
;                    current speed without changing the direction of the motor.
;                    If MAX_SPEED or MIN_SPEED is reached, the speed is set to
;                    those instead. No error is returned.
;
; Operation:         This function gets the current motor speed, then checks
;                    the sign of the number argument. If the sign is negative,
;                    then the number is subtracted from the current speed, and
;                    is checked that the speed is not lower than MIN_SPEED. If
;                    it is lower than MIN_SPEED, then the speed is set to
;                    MIN_SPEED instead. If the sign is positive, then the number
;                    is added to the current speed, and is checked that the
;                    speed is not greater than MAX_SPEED. If it is greater than
;                    MAX_SPEED, then the speed is set to MAX_SPEED instead.
;                    Afterwards, the angle argument is set to be IGNORE_DEGREE,
;                    since the angle should not be changed, before calling
;                    SetMotorSpeed. At the end, the state is changed to the
;                    end state, and no error is returned.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curSign    - the current sign of number being parsed (DS, R)
;                    curNumber  - the number being read for current command (DS, R)
;                    curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetRelativeSpeed      PROC        NEAR

    PUSH AX
    PUSH BX
GetCurrentSpeed:          ; check the current speed
    CALL GetMotorSpeed    ; get the current speed of the motor in AX
    CMP curSign, NEGATIVE ; check if number if negative
    JE CheckSpeedZero     ; if yes check if speed goes to MIN_SPEED
    JG CheckSpeedMax     ; if no check if speed goes to MAX_SPEED
    
CheckSpeedZero:           ; if speed is being decreased check if it reaches
                          ; MIN_SPEED
    NEG curNumber         ; negate number first to account for negative value
    SUB AX, curNumber     ; subtract the passed in speed from the current speed
    JC SetSpeedZero      ; if yes set the speed to MIN_SPEED
    JNC SetSpeed          ; otherwise go ahead and set the speed
 
SetSpeedZero:             ; set the speed to be MIN_SPEED
    MOV AX, MIN_SPEED     ; speed = MIN_SPEED
    JMP SetSpeed          ; call SetMotorSpeed
  
CheckSpeedMax:            ; if speed is being increased check if it reaches
                          ; MAX_SPEED
    ADD AX, curNumber     ; add the passed in speed from the current speed
    JC  SetSpeedMax       ; if there was overflow then set the speed to MAX_SPEED
    JMP SetSpeed          ; otherwise go ahead and set the speed
    
SetSpeedMax:              ; set the speed to be MAX_SPEED
    MOV AX, MAX_SPEED     ; speed = MAX_SPEED
    JMP SetSpeed          ; call SetMotorSpeed
 
SetSpeed:                 ; set the speed of the motors
    MOV BX, IGNORE_DEGREE ; don't change the angle of the RoboTrike
    CALL SetMotorSpeed    ; set the speed
    
    POP BX
    POP AX

    RET

SetRelativeSpeed     ENDP

; SetDirection
;
; Description:       This function sets the direction of the RoboTrike without
;                    changing the speed of its motors.
;
; Operation:         This function takes the current number, which is the
;                    degree the RoboTrike should turn. The number is modded by
;                    360 to prevent out of bound degrees and then added to
;                    the current degree of the motor angle (get from
;                    GetMotorDirection function). The speed is set to be ignored
;                    (IGNORE_SPEED) as an argument to SetMotorSpeed, and the
;                    direction argument is set to be the calculated new angle,
;                    before SetMotorSpeed is called. Afterwards, the state is
;                    changed to the ending state and no error is returned.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curNumber  - the number being read for current command (DS, R)
;                    curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetDirection      PROC        NEAR

GetNewAngle:
    MOV AX, curNumber         ; retrieve the new direction to add/subtract
                              ; to current direction
    MOV BX, 360               ; to prepare to mod the new direction
    CWD                       ; convert signed angle word to double for
                              ; signed division
    IDIV BX                   ; mod the number by 360 to prevent out of bounds;
                              ; new angle in DX
    CALL GetMotorDirection    ; get the current motor angle
    ADD  AX, DX               ; add current motor angle with given angle
    ;JMP ChangeDirection
    
ChangeDirection:
    MOV  BX, AX               ; make the new angle argument for SetMotorSpeed
    MOV  AX, IGNORE_SPEED     ; prevent speed changing by passing IGNORE_SPEED
                              ; as an argument
    CALL SetMotorSpeed        ; set new direction in motors
    
FinishSetDirection:
    RET

SetDirection      ENDP

; RotateTurretAngle
;
; Description:       This function determines whether the turret should be
;                    rotated absolutely or relatively based on the sign of the
;                    number argument and then calls the appropriate function
;                    to set the new turret angle.
;
; Operation:         This function first sets the current number as the argument
;                    to either SetTurretAngle or SetRelTurretAngle. It then
;                    checks whether the current number is signed or unsigned.
;                    If it is unsigned, SetTurretAngle is called. If it is
;                    signed, SetRelTurretAngle is called instead. At the end,
;                    the state is set to be the end and no error is returned
;                    to ParseSerialChar.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curSign    - the current sign of number being parsed (DS, R)
;                    curNumber  - the number being read for current command (DS, R)
;                    curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

RotateTurretAngle      PROC        NEAR

CheckAngleType:
    MOV AX, curNumber           ; moving number to be argument of either
                                ; SetTurretAngle or SetRelTurretAngle
    CMP curSign, UNSIGNED       ; check sign of number
    JE  AbsoluteRotate          ; if no sign then rotate absolute angle
    JNE RelativeRotate          ; otherwise rotate relative angle
    
AbsoluteRotate:
    CALL SetTurretAngle         ; rotate absolute angle
    JMP  FinishRotate           ; finished rotating turret

RelativeRotate:
    CALL SetRelTurretAngle      ; rotate relative angle
    ;JMP FinishRotate           ; finished rotating turret
    
FinishRotate:
    RET

RotateTurretAngle      ENDP    

; SetElevation
;
; Description:       This function sets the elevation of the turret and returns
;                    no error.
;
; Operation:         This function gets the current number and sets it as the
;                    argument for SetTurretElevation. SetTurretElevation is then
;                    called, the state is changed to end, and no error is
;                    returned to ParseSerialChar.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

SetElevation      PROC        NEAR

    MOV AX, curNumber            ; move current number to be argument for
                                 ; SetTurretElevation
    CALL SetTurretElevation      ; set the turret elevation

    RET

SetElevation     ENDP

; TurnLaserOn
;
; Description:       This function turns the turret laser on and returns no
;                    error.
;
; Operation:         This function passes LASER_ON to the SetLaser function,
;                    calls the SetLaser function, changes the state to the
;                    ending state, and then returns no error.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments

TurnLaserOn      PROC        NEAR

    MOV  AX, LASER_ON     ; set argument to be LASER_ON (non-zero) before calling
                          ; SetLaser
    CALL SetLaser         ; fire laser
    
    RET

TurnLaserOn      ENDP

; TurnLaserOff
;
; Description:       This function turns the turret laser off and returns no
;                    error.
;
; Operation:         This function passes LASER_OFF to the SetLaser function,
;                    calls the SetLaser function, changes the state to the
;                    ending state, and then returns no error.
;
; Arguments:         None.
; Return Value:      AX         - flag whether there was an error parsing the
;                                 character or not
;
; Local Variables:   None.
; Shared Variables:  curState   - the current state (DS, W)
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
;     12/24/15  Nancy Cao   updated comments


TurnLaserOff      PROC        NEAR

    MOV  AX, LASER_OFF    ; set argument to be LASER_OFF (0) before calling SetLaser
    CALL SetLaser         ; turn off laser
    
    RET

TurnLaserOff     ENDP
    
JumpTable LABEL WORD
    DW        OFFSET(SetAbsoluteSpeed)     ; set RoboTrike absolute speed
    DW        OFFSET(SetRelativeSpeed)     ; set RoboTrike relative speed
    DW        OFFSET(SetDirection)         ; set RoboTrike direction
    DW        OFFSET(RotateTurretAngle)    ; rotate turret angle
    DW        OFFSET(SetElevation)         ; set turret elevation
    DW        OFFSET(TurnLaserOn)          ; turn laser on
    DW        OFFSET(TurnLaserOff)         ; turn laser off

    
; StateTable
; Description: This state table defines the state machine for the parser. The
;              rows are associated with the state and the columns are associated
;              with the token values. This table is used to check which state
;              to go next based on current state (curState) and token passed and
;              which function to call as a result.
; Revision History:
;     12/21/15   Nancy Cao   initial code and comment
    
TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION      DW      ?               ;first action for the transition
TRANSITION_ENTRY      ENDS
   
    

;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC
%*DEFINE(TRANSITION(nxtst, act))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act)>
)

StateTable		LABEL		TRANSITION_ENTRY
    
    ;Current State = ST_INITIAL                     Input Token Type   
    %TRANSITION(ST_ABS_SPEED, SetCommand)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_REL_SPEED, SetCommand)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_DIRECTION, SetCommand)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ROTATE,    SetCommand)         ; TOKEN_ROTATE
    %TRANSITION(ST_ELEVATE,   SetCommand)         ; TOKEN_ELEVATE
    %TRANSITION(ST_LASER_ON,  SetCommand)         ; TOKEN_LASER_ON
    %TRANSITION(ST_LASER_OFF, SetCommand)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIGIT
    %TRANSITION(ST_INITIAL,   DoNothing)          ; TOKEN_RETURN
    %TRANSITION(ST_INITIAL,   DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_ABS_SPEED                   Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_SIGN,      SetSign)            ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_ABS_SPEED, DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_REL_SPEED                   Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_SIGN,      SetSign)            ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_REL_SPEED, DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_DIRECTION                   Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_SIGN,      SetSign)            ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_DIRECTION, DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_ROTATE                      Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_SIGN,      SetSign)            ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_ROTATE,    DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_ELEVATE                     Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_SIGN,      SetSign)            ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_ELEVATE,   DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_LASER_ON                    Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIGIT
    %TRANSITION(ST_END,       CallCommand)        ; TOKEN_RETURN
    %TRANSITION(ST_LASER_ON,  DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_LASER_OFF                   Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIGIT
    %TRANSITION(ST_END,       CallCommand)        ; TOKEN_RETURN
    %TRANSITION(ST_LASER_OFF, DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_SIGN                        Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_RETURN
    %TRANSITION(ST_sign,      DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_DIGIT                       Input Token Type   
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_DIGIT,     AddDigit)           ; TOKEN_DIGIT
    %TRANSITION(ST_END,       CallCommand)        ; TOKEN_RETURN
    %TRANSITION(ST_DIGIT,     DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_ERROR			            Input Token Type
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ABS_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_REL_SPEED
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIRECTION
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ROTATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_ELEVATE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_ON
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_LASER_OFF
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_SIGN
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_DIGIT
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_RETURN
    %TRANSITION(ST_ERROR,     DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_ERROR,     ThrowError)         ; TOKEN_OTHER
    
    ;Current State = ST_END                         Input Token Type
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_ABS_SPEED
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_REL_SPEED
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_DIRECTION
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_ROTATE
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_ELEVATE
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_LASER_ON
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_LASER_OFF
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_SIGN
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_DIGIT
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_RETURN
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_SPACE
    %TRANSITION(ST_END,       DoNothing)          ; TOKEN_OTHER
    
    
; Token Tables
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;
; Author:           Glen George
; Last Modified:    Feb. 26, 2003

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_OTHER, 0)		;<null>  (end of string)
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_SPACE, 9)		;TAB
        %TABENT(TOKEN_OTHER, 10)	    ;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_RETURN, 13)	;carriage return
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_SPACE, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_SIGN, POSITIVE)		;+  (positive sign)
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_SIGN, NEGATIVE)		;-  (negative sign)
        %TABENT(TOKEN_OTHER, 0)		;.  (decimal point)
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_DIGIT, 0)		;0  (digit)
        %TABENT(TOKEN_DIGIT, 1)		;1  (digit)
        %TABENT(TOKEN_DIGIT, 2)		;2  (digit)
        %TABENT(TOKEN_DIGIT, 3)		;3  (digit)
        %TABENT(TOKEN_DIGIT, 4)		;4  (digit)
        %TABENT(TOKEN_DIGIT, 5)		;5  (digit)
        %TABENT(TOKEN_DIGIT, 6)		;6  (digit)
        %TABENT(TOKEN_DIGIT, 7)		;7  (digit)
        %TABENT(TOKEN_DIGIT, 8)		;8  (digit)
        %TABENT(TOKEN_DIGIT, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_DIRECTION, SET_DIRECTION)	;D, is actually a function index for set direction
        %TABENT(TOKEN_ELEVATE, SET_ELEVATION)   ;E, is actually a function index for set elevation
        %TABENT(TOKEN_LASER_ON, SET_LASER_ON)   ;F, is actually the on state for setting laser on
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_LASER_OFF, SET_LASER_OFF) ;O, is actually the off state for the laser
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_ABS_SPEED, SET_ABS_SPEED)	;S, is actually a function index for setting absolute speed
        %TABENT(TOKEN_ROTATE, ROTATE)		;T
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_REL_SPEED, SET_REL_SPEED)	;V, is actually a function index for setting relative speed
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_DIRECTION, SET_DIRECTION) ;d, is actually a function index for set direction
        %TABENT(TOKEN_ELEVATE, SET_ELEVATION)   ;e, is actually a function index for set elevation
        %TABENT(TOKEN_LASER_ON, SET_LASER_ON)   ;f, is actually the on state for setting laser on
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_LASER_OFF, SET_LASER_OFF)		;o, is actually the off state for the laser
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_ABS_SPEED, SET_ABS_SPEED)	;s, is actually a function index for setting absolute speed
        %TABENT(TOKEN_ROTATE, ROTATE)		;t
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_REL_SPEED, SET_REL_SPEED)	;v, is actually a function index for setting relative speed
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)


; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE

; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE
    
CODE ENDS    
           
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

curCommand     DB    ?  ; the current command being parsed from the serial
curSign        DB    ?  ; the sign of the number
curNumber      DW    ?  ; the number to apply to the command
curState       DB    ?  ; the current state of the parser
curError       DB    ?  ; the current error of the parser

DATA    ENDS

END