NAME    MOTOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     MOTOR                                  ;
;                          RoboTrike Motor Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    keypad. The public functions included are:
;                        SetMotorSpeed     - sets the speed of the RoboTrike,
;                                            including the speeds of the 3
;                                            wheels, as well as the angle
;                                            of the RoboTrike, including the
;                                            anges of the 3 wheels
;                        GetMotorSpeed     - returns RoboTrike's current
;                                            movement speed
;                        GetMotorDirection - returns RoboTrike's current
;                                            direction/angle
;                        SetLaser          - sets the status of the laser
;                                            (on or off)
;                        GetLaser          - gets the status of the laser
;                                            (on or off)
;                        MotorEventHandler - turns the motors on or off
;                                            depending on the pulse width
;
; Revision History:
;     11/11/15  Nancy Cao          initial comments and pseudocode
;     11/15/15  Nancy Cao          initial code, added pulse counters and tables
;     11/15/15  Nancy Cao          updated comments
;     11/16/15  Nancy Cao          finished coding SetMotorSpeed and
;                                  MotorEventHandler
;     11/18/15  Nancy Cao          updated comments and fixed bugs in updating
;                                  motor speeds
;     12/28/15  Nancy Cao          added empty SetTurretAngle,
;                                  SetRelTurretAngle and SetTurretElevation
;                                  functions for the parser

; local include files
$INCLUDE(MOTOR.INC)     ; motor constants used in motor functions

EXTRN Sin_Table:WORD    ; a table of decimal values of sin(angles)
EXTRN Cos_Table:WORD    ; a table of decimal values of cos(angles)
EXTRN Forcex_Table:WORD ; a table of the x-force vectors of the wheels
EXTRN Forcey_Table:WORD ; a table of the y-force vectors of the wheels
EXTRN Back_Table:BYTE   ; a table of flags to make the wheels go backwards
EXTRN Motor_On:BYTE     ; a table of flags to make the wheels turn on

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; InitMotor
; 
; Description: This function initializes speedRobo to REST_SPEED, angleRobo to
;              DEFAULT_DEGREE, the elements of speedWheels to REST_SPEED, and
;              the elements of dirWheels to FORWARD. The elements of
;              pulseCounter is set to the PULSE_WIDTH.
;
; Operation:   The function sets the initial speed/angle of the RoboTrike to
;              be REST_SPEED AND DEFAULT_DEGREE, since it is not moving nor is
;              it moving in any direction by default. The speed of the
;              wheels are also set to REST_SPEED. The direction of the wheels
;              are set to be FORWARD. The pulseCounters are set to PULSE_WIDTH.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: speedRobo     - speed of the RoboTrike (w)
;                   angleRobo     - direction of the RoboTrike's movement (w)
;                   laserStatus   - laser is either off (set to LASER_OFF) or
;                                   on (set to LASER_ON) (w)
;                   speedWheels   - keeps track of the speed for the 3 wheels
;                                   on the RoboTrike (w)
;                   dirWheels     - keeps track of the direction of the 3 wheels
;                                   on the RoboTrike (w)
;                   pulseCounter  - keeps track of the pulse counters on all
;                                   3 wheels to turn them on and off (w)
; Global Variables: None.
;
; Input:  None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: The speed taken in can only be between MIN_SPEED and MAX_SPEED.
;              The angle taken in can only be between MIN_DEGREE and
;              MAX_DEGREE.
;
; Algorithms: None.
; Data Structures: Arrays (speedWheels, angleWheels).
;
; Registers Changed: BX.
;
; Author: Nancy Cao
; Revision History: 
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments

InitMotor    PROC        NEAR
             PUBLIC      InitMotor

    PUSH BX                           ; save register value to stack

    MOV speedRobo, MIN_SPEED          ; initial speed of RoboTrike is MIN_SPEED
    MOV angleRobo, MIN_DEGREE         ; initial direction is MIN_DEGREE
    MOV laserStatus, LASER_OFF        ; initial laser status is off
    MOV pulseCounter, PULSE_WIDTH     ; set pulse counter to PULSE_WIDTH
    MOV BX, INIT_INDEX                ; set initial index

InitArrays:                           ; set speed of wheels to MIN_SPEED and
    CMP BX, NUM_WHEELS                ; set angle of wheels to MIN_DEGREE                              
    JZ  FinishInit                    ; finished setting speed/angle of wheels
    JNZ InitElement                   ; continue setting speed/angle of wheels

InitElement:                          ; initialize elements of speed/angleWheels
    MOV speedWheels[BX], MIN_SPEED    ; set current wheel's speed to MIN_SPEED
    MOV dirWheels[BX], FORWARD        ; set current wheel's direction to FORWARD
    INC BX                            ; go to the next element in the arrays
    JMP InitArrays                    ; continue initializing
    
FinishInit:                           ; finished setting speed/angle of wheels
    POP BX                            ; return register value
    RET

InitMotor           ENDP

; SetMotorSpeed
; 
; Description: This function takes in two arguments, speed and angle.
;              The function sets the general speed and angle of the RoboTrike
;              to be the values passed in these arguments. It then also
;              calculates the individual speed for the NUM_WHEELS wheels on the
;              RoboTrike as well.
;
; Operation:   The function first looks if speedRobo should be reset to a new
;              value. If the passed in speed is not IGNORE_SPEED, then it sets
;              the new speed value for speedRobo. It then checks if angleRobo
;              should be reset to a new value. If the passed in angle is not
;              IGNORE_DEGREE, then it sets the new angle value for angleRobo.
;              Since the angle passed can be a number not between MIN_DEGREE
;              and MAX_DEGREE, the function mods the angle by MAX_DEGREE to find
;              the smallest representative angle. Then it checks if the angle
;              passed in was negative. If so, it finds the equivalent positive
;              angle by adding MAX_DEGREE to it. Once the angle is positive,
;              the angleRobo is set to that angle. The speeds and directions
;              for individual wheels are then calculated. The calculation is
;              broken up to x and y components of the wheel. The function loops
;              NUM_WHEELS times, each time looking at a particular wheel. For
;              each wheel, it multiplies the x-force of the wheel with
;              speedRobo, and then takes that and multiplies it with
;              cos(angleRobo), to find the x-component of the speed of the
;              wheel. It then multiplies the y-force of the wheel with
;              speedRobo, and then takes that and multiplies it with
;              sin(angleRobo), to find the y-components of the speed of the
;              wheel. The x-component speed and y-component speed are then
;              added together, and the result is stored in the speedWheels
;              array. The speed is also checked for negative or positive. If it
;              is positive, FORWARD is stored in the dirWheels array; otherwise
;              BACKWARD is stored.
;
; Arguments:        speed (AX)   - the speed of the RoboTrike
;                   angle (BX)   - the direction of the RoboTrike's movement
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: speedRobo    - speed of the RoboTrike (w)
;                   angleRobo    - direction of the RoboTrike's movement (w)
;                   speedWheels  - keeps track of the speed for the 3 wheels
;                                  on the RoboTrike (w)
;                   dirWheels    - keeps track of the direction of the 3 wheels
;                                  on the RoboTrike (w)
; Global Variables: None.
;
; Input:  None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: The speed taken in can only be between MIN_SPEED and MAX_SPEED.
;              The angle taken in can only be between MIN_DEGREE and MAX_DEGREE.
;
; Algorithms: Linear velocity formulas.
; Data Structures: Arrays (speedWheels, dirWheels).
;
; Registers Changed: AX, BX, CX, DX.
;
; Author: Nancy Cao
; Revision History: 
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments
;     11/16/15  Nancy Cao        updated code
;     11/18/15  Nancy Cao        fixed converting angle and saving correct
;                                speeds for wheels

SetMotorSpeed    PROC        NEAR
                 PUBLIC      SetMotorSpeed    
                 
SetRoboSpeed:
    CMP AX, IGNORE_SPEED               ; check if speed should be ignored
    JZ SetRoboAngle                    ; if speed is ignored value, move on
    ;JMP SaveSpeed
    
SaveSpeed:
    MOV speedRobo, AX                  ; otherwise set speed of the RoboTrike
    ;JMP SetRoboAngle
    
SetRoboAngle:
    CMP BX, IGNORE_DEGREE              ; check if angle should be ignored
    MOV SI, INIT_INDEX                 ; start finding speed/dir of first wheel
    JZ SetWheels                       ; if angle is ignored value, move on
    ;JMP ConvertAngle

ConvertAngle:                          ; convert angle to be between MIN_DEGREE
                                       ; and MAX_DEGREE
    MOV AX, BX                         ; angle will be the numerator
    MOV BX, MAX_DEGREE                 ; MAX_DEGREE will the denominator
    CWD                                ; convert signed angle word to double for
                                       ; signed division
    IDIV BX                            ; angle / MAX_DEGREE
    CMP DX, 0                          ; remainder which is the angel is in DX
    JL ConvertNegAngle                 ; if angle is -, must make it +
    JMP SaveAngle                      ; otherwise go ahead and store the angle
                                       
ConvertNegAngle:                      
    ADD DX, MAX_DEGREE                 ; add full rotation to get equivalent
                                       ; positive angle
    ;JMP SaveAngle                     ; store the angle in angleRobo
    
SaveAngle:
    MOV angleRobo, DX                  ; set the general angle of the RoboTrike
    ;JMP SetWheels                     ; find speed/dir of wheel

SetWheels:                             ; calculate speed/direction for every wheel
    CMP SI, NUM_WHEELS                 ; check if we calculated all wheels
    JZ  FinishSetWheels                ; if yes we are done
    ;JNZ SetTrigAngles                  ; otherwise continue

SetTrigAngles:                         ; find sin(angleRobo) and cos(angleRobo)
    MOV BX, angleRobo                  ; angleRobo is the index for table lookup
    SHL BX, 1                          ; Cos_Table and Sin_Table are words so
                                       ; must shift index from byte to word
    MOV AX, CS:Cos_Table[BX]           ; hex of cos(angleRobo) in Cos_Table
    MOV cosAngle, AX                   ; store it in cosAngle for calculations
    
    MOV AX, CS:Sin_Table[BX]           ; hex of sin(angleRobo) in Sin_Table
    MOV sinAngle, AX                   ; store it in sinAngle for calculations
    ;JMP SetCurrentWheel               ; calculate values for current wheel
    
SetCurrentWheel:                       ; calculate values for current wheel
    MOV BX, SI                         ; current wheel's index
    SHL BX, 1                          ; shift index since Forcex_Table,
                                       ; Forcey_Table are words
                                       
    MOV AX, CS:Forcex_Table[BX]        ; x-force vect of current wheel
    SHR speedRobo, 1                   ; half the speed to ignore sign value
    IMUL speedRobo                     ; x-force vect * speed
    MOV AX, DX                         ; truncate to DX since IMUL returns
                                       ; DX|AX with word multiplications
    IMUL cosAngle                      ; (x-force vect * speed) * cos(angleRobo)
    MOV CX, DX                         ; the x-speed of the wheel, truncated
                                       ; to DX since IMUL returns DX|AX with
                                       ; word multiplications

    MOV AX, CS:Forcey_Table[BX]        ; y-force vect of current wheel
    IMUL speedRobo                     ; y-force vect * speed
    SHL speedRobo, 1
    MOV AX, DX                         ; truncate to DX since IMUL returns
                                       ; DX|AX with word multiplications
    IMUL sinAngle                      ; (y-force vect * speed) * sin(angleRobo)
    
    ADD DX, CX                         ; add x and y components of speed to get
                                       ; total speed of current wheel
    SHL DX, 2                          ; truncate the extra sign bits that
                                       ; exist due to multiplying twice
    CMP DH, 0                          ; check if speed is positive or neg
    JG PositiveDirection               ; if positive store FORWARD direction
    JL NegativeDirection               ; otherwise store BACKWARD direction
    ;JMP CheckDirection
    
PositiveDirection:                     ; set speed and forward direction
    MOV speedWheels[SI], DH            ; set speed for current wheel; only
                                       ; truncate to higher bit of final speed
                                       ; since lower DL is just junk values
    MOV dirWheels[SI], FORWARD         ; set wheel to go forward
    INC SI                             ; go to next wheel
    JMP SetWheels                      ; set values for next wheel

NegativeDirection:
    NEG DH                             ; take absolute value of the speed
    MOV speedWheels[SI], DH            ; truncate to higher bit of final speed
                                       ; since lower DL is just junk values
    MOV dirWheels[SI], BACKWARD        ; set wheel to go backward
    INC SI                             ; go to next wheel
    JMP SetWheels                      ; set values for next wheel
    
FinishSetWheels:
    RET

SetMotorSpeed           ENDP

; GetMotorSpeed
; 
; Description: This function returns the current speed setting for the
;              RoboTrike. The value will always be between MIN_SPEED and
;              MAX_SPEED, inclusively. A value of MIN_SPEED returned means the
;              RoboTrike is currently at rest. A value of MAX_SPEED means the
;              RoboTrike is at maximum speed.
;
; Operation:   This function takes the speed set in speedRobo and
;              returns it in AX.
;
; Arguments:        None.
; Return Value:     speed (AX) - the movement speed of the RoboTrike
; Local Variables:  None.
; Shared Variables: speedRobo - the current movement speed of the RoboTrike (r)
; Global Variables: None.
;
; Input: None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: The speed can only be between MIN_SPEED and MAX_SPEED.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: AX
;
; Author: Nancy Cao
; Revision History:
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments

GetMotorSpeed    PROC        NEAR
                 PUBLIC      GetMotorSpeed

    MOV AX, speedRobo           ; return value of RoboTrike speed in AX
    RET
             
GetMotorSpeed    ENDP
             
             
; GetMotorDirection
; 
; Description: This function returns the current direction setting for the
;              RoboTrike. The value will always be between MIN_DEGREE and
;              MAX_DEGREE, inclusively. A value of MIN_DEGREE returned means the
;              RoboTrike is currently going straight ahead relative to its
;              orientation. Angles are considered clockwise.
;
; Operation:   This function takes the angle set in angleRobo and
;              returns it in AX.
;
; Arguments:        None.
; Return Value:     angle (AX) - the direction of the RoboTrike
; Local Variables:  None.
; Shared Variables: angleRobo - the current direction of the RoboTrike (r)
; Global Variables: None.
;
; Input: None.
; Output: None.
;
; Error Handling: None.
;
; Limitations: The angle can only be between MIN_DEGREE and MAX_DEGREE.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: AX
;
; Author: Nancy Cao
; Revision History:
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments

GetMotorDirection    PROC        NEAR
                     PUBLIC      GetMotorDirection

    MOV AX, angleRobo           ; return the direction of the RoboTrike in AX
    RET
             
GetMotorDirection    ENDP

; SetLaser
; 
; Description: This function takes in an argument called offon, which
;              stores either LASER_OFF (meaning the laser should be off), or
;              another number (meaning the laser should be on). The function
;              will turn the laser on or off according to what the value of
;              offon is.
;
; Operation:   This function takes in offon, which is either LASER_OFF or
;              another number.. If it is LASER_OFF, the function will turn the
;              laser off, and if it is not LASER_OFF, the function will turn
;              the laser on.
;
; Arguments:        offon (AX)  - indicates whether laser is off (LASER_OFF) or
;                                 on (!= LASER_OFF)
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: laserStatus - stores LASER_OFF (meaning laser is off) or
;                                 another number (meaning laser is on) (w)
; Global Variables: None.
;
; Input: None.
; Output: Laser is turned on or off.
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
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments

SetLaser    PROC        NEAR
            PUBLIC      SetLaser

    MOV laserStatus, AX           ; set the status of the laser to be on/off

    RET
             
SetLaser    ENDP

; GetLaser
; 
; Description: This function takes no arguments, and returns either LASER_OFF or
;              not LASER_OFF, depending on what is stored in laserStatus. If
;              LASER_OFF is stored, the laser is turned off, and LASER_OFF will
;              be returned. Otherwise, another number that is not LASER_OFF is
;              stored, which means the laser is on. This number is returned
;              instead.
;
; Operation:   This function looks at the value of laserStatus. If it
;              is LASER_OFF, the laser is off, and the function will return
;              LASER_OFF. If it is not, the laser is on, and the function will
;              return that number instead.
;
; Arguments:        None
; Return Value:     status (AX) - indicates laser is off (LASER_OFF) or
;                                 on (!= LASER_OFF)
; Local Variables:  None.
; Shared Variables: laserStatus - stores LASER_OFF (meaning laser is off)
;                                 or another number (meaning laser is on) (r)
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
; Registers Changed: AX
;
; Author: Nancy Cao
; Revision History:
;     11/11/15  Nancy Cao        initial comments and pseudocode
;     11/15/15  Nancy Cao        initial code and updated comments

GetLaser    PROC        NEAR
            PUBLIC      GetLaser

    MOV AX, laserStatus           ; return the status of the laser
    RET
             
GetLaser    ENDP


; MotorEventHandler
; 
; Description: This function uses timer interrupts to output to the motors.
;              A pulse width counter is kept to figure out when to turn
;              certain wheels on and off. The function looks at the speed and
;              direction of every wheel to figure out whether to flag bits
;              to turn a wheel clockwise/counterclockwise, whether they should
;              be on or off, and whether the laser should be on or off.
;
; Operation:   This function first decrements the pulse counter. If the
;              pulse counter reaches 0, the pulse counter is reset. Otherwise,
;              the function loops through NUM_WHEELS time to look at each wheel.
;              For each wheel, its direction is first examined. If its direction
;              is FORWARD, the bit corresponding to the direction of that wheel
;              is not set. If its direction is BACKWARD, the bit corresponding
;              to to the direction of that wheel is set. Then it looks at its
;              speed and compares it to the pulse counter. As long as the speed
;              is higher than the pulse counter, the wheel should stay on, and
;              the bit corresponding to that is set. Otherwise it is not set.
;              After all the wheels have been gone through, the function checks
;              if the laser status equals LASER_OFF. If not, the laser is on,
;              and the bit corresponding to the laser is set.
;              Here are the bits corresponding to different commands:
;              00000001 - sets reverse for wheel 1
;              00000010 - turns on wheel 1
;              00000100 - sets reverse for wheel 2
;              00001000 - turns on wheel 2
;              00010000 - sets reverse for wheel 3
;              00100000 - turns on wheel 3
;              10000000 - sets laser on
;
; Arguments:        None
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: pulseCounter - (w)
; Global Variables: None.
;
; Input: None.
; Output: 8-bit of commands for the motors.
;
; Error Handling: None.
;
; Limitations: None.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: AX
;
; Author: Nancy Cao
; Revision History:
;     11/16/15  Nancy Cao        initial code and comments

MotorEventHandler   PROC        NEAR
                    PUBLIC      MotorEventHandler
               
    MOV BX, INIT_INDEX           ; the index of the first wheel
    MOV AL, 0                    ; output depends on direction, pulse and laser
    ;JMP StartPulsing
               
StartPulsing:
    DEC pulseCounter             ; lower counter of pulsing by 1
    JS  ResetPulseCounter        ; if the counter reaches 0 reset it
    ;JNS NextPulse               ; otherwise figure out flags to output to PORTB

NextPulse:
    CMP BX, NUM_WHEELS
    JZ CheckLaser                ; check to see if laser should be on or off
    MOV CL, speedWheels[BX]      ; the absolute speed of the wheel
    CMP dirWheels[BX], BACKWARD  ; check if current wheel is going backwards
    JZ FlagBackwards             ; if direction is BACKWARD need to flag wheel
                                 ; going backwards
    JNZ  FlagOn                  ; otherwise skip to flagging if wheel should be
                                 ; on or off
    
FlagBackwards:
    MOV DL, CS:Back_Table[BX]    ; backwards flag for current wheel
    OR AL, DL                    ; add flag to output bits
    ;JMP FlagOn                  ; must also flag wheel to be on/off

FlagOn:
    CMP CL, pulseCounter         ; if speed is higher than pulse counter, turn
                                 ; wheel on; otherwise turn it off
    JG TurnOn                    ; speed is higher, so turn on wheel
    INC BX                       ; go to next wheel
    JMP NextPulse                ; flag bits for next wheel

TurnOn:
    MOV DL, CS:Motor_On[BX]      ; flag to turn on current wheel
    OR AL, DL                    ; add flag to output bits
    INC BX                       ; go to next wheel
    JMP NextPulse                ; flag bits for next wheel
    
CheckLaser:
    CMP laserStatus, LASER_OFF   ; check if laser is off
    JZ FinishOutput              ; if laser is off we are done
    ;JNZ TurnLaserOn             ; if laser is on flag to turn on laser
    
TurnLaserOn:
    OR AL, LASER_ON              ; add flag to output bits
    ;JMP FinishOutput            ; send flags to PORTB
 
FinishOutput:
    MOV DX, PORTB                ; port address B
    OUT DX, AL                   ; send flags to PORTB
    JMP FinishedPulsing          
    
ResetPulseCounter:
    MOV pulseCounter, PULSE_WIDTH; reset the pulse counter
    ;JMP FinishedPulsing

FinishedPulsing:
    RET
               
MotorEventHandler    ENDP               

; optional functions not implemented

SetTurretAngle      PROC        NEAR
                    PUBLIC      SetTurretAngle
        NOP
        RET
SetTurretAngle      ENDP

SetRelTurretAngle   PROC        NEAR
                    PUBLIC      SetRelTurretAngle
        NOP
        RET
SetRelTurretAngle   ENDP

SetTurretElevation  PROC        NEAR
                    PUBLIC      SetTurretElevation
        NOP
        RET
SetTurretElevation  ENDP

               
CODE ENDS    
           
;the data segment

DATA    SEGMENT PUBLIC  'DATA'

speedRobo       DW     ?              ; the speed of the entire RoboTrike
angleRobo       DW     ?              ; the angle of the entire RoboTrike
laserStatus     DW     ?              ; laser is off (LASER_OFF) or on (other #)
sinAngle        DW     ?              ; sin(angleRobo)
cosAngle        DW     ?              ; cos(angleRobo)
speedWheels     DB NUM_WHEELS DUP (?) ; NUM_WHEELS speed values for wheels
dirWheels       DB NUM_WHEELS DUP (?) ; DEFAULT_DIR direction values for wheels
pulseCounter    DB     ?              ; counter for the pulse rate of wheels

DATA    ENDS

END