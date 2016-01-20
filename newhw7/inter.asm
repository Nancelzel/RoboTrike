    NAME INTER

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     INTER                                  ;
;                         RoboTrike Interrupt Functions                      ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    interrupt. The public functions included are:
;                        ClrIRQVectors        - clears the interrupt vector
;                                               table
;                        IllegalEventHandler  - handles any illegal activity
;
; Revision History:
;     11/17/15  Nancy Cao         initial revision

; local include files
$INCLUDE(TIMER.INC)        ; display constants for timers
$INCLUDE(INTER.INC)        ; display constants for interrupts

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP

; ClrIRQVectors
;
; Description:      This functions installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table.  Note
;                   that TOTAL_VECTOR_NUM are initialized so the code must be
;                   located above 400H.  The initialization skips  (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
;
; Author:            Nancy Cao
; Revision History:
;     11/01/15  Nancy Cao   initial revision and comments
;     11/05/15  Nancy Cao   updated comments
;     11/12/15  Nancy Cao   updated comments

ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors


InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to skip RESERVED_VECS (VECTOR_SIZE bytes each)

        MOV     CX, TOTAL_VECTOR_NUM    ;up to TOTAL_VECTOR_NUM to initialize


ClrVectorLoop:                  ;loop clearing each vector
				;check if should store the vector
	CMP SI, VECTOR_SIZE * FIRST_RESERVED_VEC
	JB	DoStore		;if before start of reserved field - store it
	CMP	SI, VECTOR_SIZE * LAST_RESERVED_VEC
	JBE	DoneStore	;if in the reserved vectors - don't store it
	;JA	DoStore		;otherwise past them - so do the store

DoStore:                        ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + BYTE_SIZE], SEG(IllegalEventHandler)

DoneStore:			;done storing the vector
        ADD     SI, VECTOR_SIZE     ;update pointer to next vector

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET


ClrIRQVectors   ENDP




; IllegalEventHandler
;
; Description:       This procedure is the event handler for illegal
;                    (uninitialized) interrupts.  It does nothing - it just
;                    returns after sending a non-specific EOI.
;
; Operation:         Send a non-specific EOI and return.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            EOI.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
;
; Author:            Nancy Cao
; Revision History:
;     11/01/15  Nancy Cao   initial revision and comments
;     11/05/15  Nancy Cao   updated comments
;     11/12/15  Nancy Cao   updated comments

IllegalEventHandler     PROC    NEAR
                        PUBLIC  IllegalEventHandler

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-specific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP

CODE ENDS

END