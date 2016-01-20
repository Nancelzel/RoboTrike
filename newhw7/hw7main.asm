NAME    HW7MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW6MAIN                                  ;
;                            Homework #7 Test Code                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the motor functions for Homework #6. It
;                   calls Glen's test code, which will set the laser to various
;                   values to turn it on and off as well as various speeds and
;                   angles. IGNORE_SPEED value and IGNORE_DEGREE values are
;                   tests, as well as the boundaries for speed and degree.
;                   Once the speed and direction for the motors are processed,
;                   the MotorEventHandler will store the necessary bits to
;                   set the motors to appropriate direction/speed, and the laser
;                   on/off. 18 tests are in Glen's code, each of which can be
;                   run by pressing a key of the 16-key keypad to cycle through
;                   the tests. The test code is displayed on the 8-digit display
;                   board, on the very left digit. On the oscilloscope, the 8
;                   bits are shown, with waves indicating whether the bit is set
;                   or not. It also displays the duty cycles of bit 1, bit 3,
;                   and bit 5, which indicates the speeds of the motors and how
;                   often they are turned on depending on the pulse wave
;                   modulation.
;
; Input:            Key presses on the 16-key keyboard.
; Output:           The test code is displayed on the 8-digit display board.
;                   On the oscilloscope the bits set and unset are shown,
;                   as well as the waves and duty cycle indicating the speed of
;                   the motors (rate of motors on) via the pulse wave
;                   modulation.
;
; User Interface:   The user can press various keys on the keypad. A key press
;                   will cause the test code to iterate to the next test. There
;                   are a total of 18 tests, labelled 0, 1, 2, 3, 4, 5, 6, 7, 8,
;                   9, A, b, C, d, E, F, H, J.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      None.
;
; Revision History:
;    11/17/15       Nancy Cao               initial code
;    11/18/15       Nancy Cao               updated comments

EXTRN InitCS:NEAR          ; used to initialize chip select
EXTRN ClrIRQVectors:NEAR   ; used to install IllegalEventHandler for all
                           ; interrupt vectors in the interrupt vector table.
EXTRN InstallInt2Handler:NEAR  ; installs event handler
EXTRN InitSerial:NEAR      ; sets the speed and direction of the motor to be 0.
                          ; also sets the wheels to be 0 and going forwards, and
                          ; the laser to be off
EXTRN InitInt2:NEAR     ; initializes the timer
EXTRN SerialIOTest:NEAR      ; tests the motors


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP



START:  

MAIN:
        MOV     AX, STACK               ; initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(TopOfStack)

        MOV     AX, DATA                ; initialize the data segment
        MOV     DS, AX


        CALL    InitCS                  ; initialize the 80188 chip selects
                                        ; assumes LCS and UCS already setup
       
        CALL    ClrIRQVectors           ; clear interrupt vector table
        
        CALL    InitInt2
        
        CALL    InstallInt2Handler    

        CALL    InitSerial              ; set default speed/direction/laser
                                        
        STI                             ; and finally allow interrupts.
        
        CALL    SerialIOTest                 ; test if everything is working properly
        
Forever:
        JMP    Forever                  ; sit in an infinite loop, nothing to
                                        ; do in the background routine
        HLT                             ; never executed (hopefully)
        
        
CODE ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

DATA    ENDS


;the stack

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS



        END     START