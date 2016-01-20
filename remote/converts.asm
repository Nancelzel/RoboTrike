NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the conversion functions
;                    Dec2String and Hex2String. Dec2String converts a 16-bit
;                    signed value into signed decimal in ASCII string.
;                    Hex2String converts a 16-bit unsigned value into a
;                    hexadecimal in ASCII string.
;
; Input:             None.
; Output:            None.
;
; User Interface:    No user interface.
; Error Handling:    None.
;
; Algorithms:        Divide 16-bit value by powers of 10 to get the quotients
;                    and remainders, which are the digits of the decimal.
;                    Divide 16-bit value by powers of 16 to get the quotients
;                    and remainders, which are the digits of the hexadecimal.
; Data Structures:   None.
;
; Known Bugs:        None.
; Limitations:       None.
;
; Revision History:
;     10/12/15  Nancy Cao         initial comments with pseudocode
;     10/17/15  Nancy Cao         initial writeup
;     10/17/15  Nancy Cao         fixed address mistakes
;     10/18/15  Nancy Cao         negated negative values and jumps

; local include files
$INCLUDE(CONVERTS.INC)

CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP


; Dec2String
;
; Description:       This function takes in a 16-bit signed value and a
;                    specified address. The 16-bit signed value is
;                    determined to be positive or negative, then converts
;                    it into a decimal. The ASCII representation of every
;                    digit is figured out along the way and stored in the
;                    specified address one by one, with the address being
;                    incremented each time. There should be at most 5
;                    ASCII digits plus the sign.
;
; Operation:         The function first determines whether the 16-bit
;                    signed value is positive or negative by comparing it
;                    to 0 and then observing the flags. If the value is
;                    determined positive, a “+” is added to the address a;
;                    otherwise a “-” is added to address a. The bits in the
;                    are flipped before converted. The address is
;                    incremented for the next byte. Then, there is loop that
;                    divides the value by the largest power of 10 possible
;                    (10^4 or 10000) to get the remainder, which is used for
;                    the next iteration of division. The quotient is the value
;                    of the lowest decimal digit value. This is added to the
;                    current address at a and then a is incremented. The
;                    power is then divided by 10 (to get 1000), which is
;                    used to divide the remainder in the next iteration.
;                    This continues until the power is no longer greater
;                    than 0. At the end, a null terminator is added to
;                    the specified address.
;
; Arguments:         n – 16-bit signed value to convert into a decimal
;                    a – the address where the string decimal version of n
;				     should be stored
; Return Value:      None.
;
; Local Variables:   value – copy of the passed binary value to convert
;                    digit – computed digit from value to save as a string
;				     pwr10 – current power of 10 being computed
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Divide 16-bit value by powers of 10 to get the quotients
;                    and remainders, which are the digits of the decimal.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX, DI, SI
; Stack Depth:       0 words.
;
; Author: Nancy Cao
; Last Modified: 10/18/2015

Dec2String      PROC        NEAR
                PUBLIC      Dec2String
				
Dec2StringInit:                       ;initialization of registers
        MOV    DI, AX                 ;DI = value to convert
        MOV    CX, MAX_DEC_POW        ;pwr10 = 10^4 (10000) to divide value
        JMP    PosOrNeg               ;check if value is positive or negative
		
PosOrNeg:                             ;check if value is positive or negative
        CMP    DI, 0                  ;set sign flags to check if value is +/-
        JGE    AddPos                 ;if flag positive add positive sign
        JMP    AddNeg                 ;otherwise add negative sign

AddPos:                               ;add positive sign
        MOV    AL, PLUS               ;add positive sign to register
        MOV    BYTE PTR [SI], AL      ;add positive sign into byte-sized address
        INC    SI                     ;increase address for next byte
        JMP    Dec2StringLoop         ;start looping to get digits

AddNeg:                               ;add negative sign
        MOV    AL, MINUS              ;add negative sign to register
        MOV    BYTE PTR [SI], AL      ;add negative sign into byte-sized address
        INC    SI                     ;increase address for next byte
        NEG    DI                     ;negate the bits for negative value
        JMP    Dec2StringLoop         ;start looping to get digits
		
Dec2StringLoop:                       ;loop condition; getting digits in value
        CMP    CX, 0                  ;check is pwr10 > 0
        JLE    EndDec2StringLoop      ;if not, have gotten all digits, done
        JMP    Dec2StringLoopBody     ;else, get the next digit
		
Dec2StringLoopBody:                   ;get a digit
        MOV    DX, 0                  ;clear DX to set up for value / pwr10
        MOV    AX, DI                 ;load current value
        DIV    CX                     ;digit (AX) = value / pwr10
        ADD    AX, ZERO               ;change digit to ASCII
        MOV    BYTE PTR [SI], AL      ;move ASCII character into address
        INC    SI                     ;increase address for next byte
        MOV    DI, DX                 ;remainder value for next iteration
        MOV    AX, CX                 ;set to update pwr10
        MOV    BX, 10                 ;to divide pwr10 by 10
        MOV    DX, 0                  ;clear DX to set up for pwr10 / 10
        DIV    BX                     ;pwr10 (AX) = pwr10 / 10
        MOV    CX, AX                 ;use new pwr10 for next iteration
        JMP    Dec2StringLoop         ;keep looping (end check is at top)

EndDec2StringLoop:                    ;done converting
        MOV    AL, ASCII_NULL         ;prepare to add null terminator
        MOV    BYTE PTR [SI], AL      ;add null terminator
        INC    SI                     ;increase address for next byte
        RET

Dec2String	ENDP




; Hex2String
;
; Description:       This function takes in a 16-bit unsigned value and a
;                    specified address. The 16-bit unsigned value is
;                    converted into a hexadecimal. The ASCII representation
;                    of every digit is figured out along the way and stored
;                    in the specified address one by one, with the address
;                    being incremented each time. There should be at most 4
;                    ASCII digits.
;
; Operation:         The function has a loop that divides the value by the
;                    largest power of 16 possible (16^3 or 4096) to get the
;                    remainder, which is used for the next iteration of
;                    division. The quotient is the value of the lowest
;                    hexdecimal digit value. If the quotient is greater than
;                    9, the function converts the number to the respective
;                    letter (A for 10, B for 11, etc…). The corresponding
;                    character is added to the address a. The power is then
;                    divided by 16 (to get 256), which is used to divide the
;                    remainder in the next iteration. This continues until
;                    the power is no longer greater than 0. At the end, a
;                    null terminator is stored at the specified address.
;
; Arguments:         n – 16-bit unsigned value to convert into a hexadecimal
;                    a – the address where the string hexadecimal version of n
;                        should be stored
; Return Value:      None.
;
; Local Variables:   value – copy of the passed binary value to convert
;                    digit – computed digit from value to save as a string
;                    pwr10 - current power of 16 being computed
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Divide 16-bit value by powers of 16 to get the quotients
;                    and remainders, which are the digits of the hexadecimal.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX, DI, SI
; Stack Depth:       0 words.
;
; Author:            Nancy Cao
; Last Modified:     10/18/2015

Hex2String      PROC        NEAR
                PUBLIC      Hex2String

Hex2StringInit:                        ;initialization of registers
        MOV    DI, AX                  ;DI = value to convert
		MOV    CX, MAX_HEX_POW         ;pow16 = 16^3 (4096) to divide value
		JMP    Hex2StringLoop          ;start looping to get digits
		
Hex2StringLoop:                        ;loop condition; getting digits in value
        CMP    CX, 0                   ;check if pwr16 > 0
		JLE    EndHex2StringLoop       ;if not, have gotten all digits, done
		JMP    Hex2StringLoopBody      ;else, get the next digit
		
Hex2StringLoopBody:                    ;get a digit
        MOV    DX, 0                   ;clear DX to setup for value / pwr16
        MOV    AX, DI                  ;load current value
        DIV    CX                      ;digit (AX) = value / pwr16
		CMP    AX, 9                   ;check if digit > 9
		JG     Letter                  ;convert letter into ASCII
		JMP    Number                  ;convert number into ASCII

Letter:                                ;convert letter and store
        SUB    AX, 10                  ;change hex letter to ASCII
        ADD    AX, LETTER_A            ;change hex letter to ASCII
        MOV    BYTE PTR [SI], AL       ;move ASCII character into address
        INC    SI                      ;increase address for next byte
        JMP    Hex2StringLoopBody2     ;update pwr16
		
Number:                                ;convert number and store
        ADD   AX, ZERO                 ;change hex digit to ASCII
        MOV   BYTE PTR [SI], AL        ;move ASCII character into address
        INC   SI                       ;increase address for next byte
        JMP   Hex2StringLoopBody2      ;update pwr16
		
Hex2StringLoopBody2:                   ;prepare for next iteration
        MOV    DI, DX                  ;remainder value for next iteration
        MOV    AX, CX                  ;set to update pwr16
        MOV    BX, 16                  ;to divide pwr16 by 16
        MOV    DX, 0                   ;clear DX to set up for pwr16 / 16
        DIV    BX                      ;pwr16 (AX) = pwr16 / 16
        MOV    CX, AX                  ;use new pwr16 for next iteration
        JMP    Hex2StringLoop          ;keep looping (end check is at top)

EndHex2StringLoop:                     ;done converting
        MOV    AL, ASCII_NULL          ;prepare to add null terminator
        MOV    BYTE PTR [SI], AL       ;add null terminator
        INC    SI                      ;increase address for next byte
        RET

Hex2String	ENDP



CODE    ENDS



        END
