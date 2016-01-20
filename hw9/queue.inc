;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   QUEUE.INC                                ;
;                               Queue Definitions                            ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the queue functions.
;
; Revision History:
;     10/24/15  Nancy Cao      initial revision

; definitions
LENGTH_TEST   EQU 255               ; length of the queue

; Queue structure

QUEUE         STRUC
    headPtr   DB ?                  ; index of head/first element of queue
	tailPtr   DB ?                  ; index of tail/last element of queue
	len       DW ?                  ; length of queue in bytes
	s         DB ?                  ; size of elements in queue (1 or 2 bytes)
	array1Ds  DB 256 DUP (?)        ; 1D array designed to hold max 256 bytes
QUEUE         ENDS