;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  TIMER.INC                                 ;
;                              Timer Definitions                             ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the timer functions.
;
; Revision History:
;     11/01/15   Nancy Cao      initial revisions and comments
;     11/12/15   Nancy Cao      removed some constants and updated comments

; Interrupt Vectors
Tmr2Vec         EQU     19               ;interrupt vector for Timer 2

; definitions

INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer
INTCtrlrCVal    EQU     00001H          ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)
Tmr2Ctrl        EQU     0FF66H          ;address of Timer 2 Control Register
Tmr2MaxCnt      EQU     0FF62H          ;address of Timer 2 Max Count A Register
Tmr2Count       EQU     0FF60H          ;address of Timer 2 Count Register
Tmr2CtrlVal     EQU     0E001H          ;value to write to Timer 2 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  interrupts
                                        ;----000000-0000-  reserved
                                        ;---0------0-----  read only
                                        ;---------------1  continuous mode
COUNTS_PER_MS   EQU     3840            ;number of timer counts per 1 ms for 30 Hz (assumes 18.432 MHz clock)
MOTOR_FREQ      EQU      480             ;COUNTER_PER_MS/ 15