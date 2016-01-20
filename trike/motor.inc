;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MOTOR.INC                                 ;
;                              MOTOR  Definitions                            ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the motor functions.
;

; Addresses

PORTB                  EQU 181H      ; address of Port B

; General definitions

NUM_WHEELS             EQU 3         ; the number of wheels on the RoboTrike
MIN_SPEED              EQU 0         ; the speed of the RoboTrike at rest
MAX_SPEED              EQU 65534     ; the fastest the RoboTrike can travel
MIN_DEGREE             EQU 0         ; the default direction of the RoboTrike
MAX_DEGREE             EQU 360       ; the max directional degree turn
FORWARD                EQU 0         ; flag for wheel moving forward
BACKWARD               EQU 1         ; flag for wheel moving backwards
IGNORE_SPEED           EQU 65535     ; current speed shouldn't change
IGNORE_DEGREE          EQU -32768    ; current degree shouldn't change
LASER_OFF              EQU 0         ; indication that laser is off
LASER_ON               EQU 10000000B ; flag for Laser On
PULSE_WIDTH            EQU 128       ; the pulse width of the timer
INIT_INDEX             EQU 0         ; the initial index when looping arrays