NAME    DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    DISPLAY                                 ;
;                          RoboTrike Display Functions                       ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:       This program includes the routines for the RoboTrike
;                    display. The public functions included are:
;                        InitDisplay       - initializes the RoboTrike Display
;                                            by clearing out whatever was
;                                            previously displayed on the board
;                        Display           - converts every ASCII value to
;                                            7-seg code which is stored into
;                                            muxBuffer
;                        DisplayNum        - takes a 16-bit signed value and
;                                            outputs it in decimal to display
;                        DisplayHex        - takes a 16-bit unsigned value and
;                                            outputs it in hex to display
;                        Multiplex         - cycles to the next digit to display
;                                            on the LED board
;
; Revision History:
;     10/27/15  Nancy Cao         initial comments and pseudocode
;     11/01/15  Nancy Cao         updated comments
;     11/01/15  Nancy Cao         moved TimerEventHandler to timer.asm
;     11/03/15  Nancy Cao         fixed incrementing CURRENT_DIGIT appropriately
;     11/03/15  Nancy Cao         updated comments

; local include files
$INCLUDE(DISPLAY.INC)        ; display constants ASCII / mux buffer definition
$INCLUDE(CONVERTS.INC)

EXTRN Dec2String:NEAR       ; used to convert decimal to ASCII string
EXTRN Hex2String:NEAR       ; used to convert hexadecimal to ASCII string
EXTRN ASCIISegTable:BYTE    ; a table of conversions from ASCII to 7-seg code

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP

; InitDisplay
; 
; Description: This function clears all bytes stored in numString and
;              and muxBuffer for the next value. Both numString and
;              muxBuffer hold at most MAX_DIGIT bytes, so the function will
;              loop MAX_DIGIT times to clear every byte. The function also
;              initializes the current digit to be 0 (the first digit).
;
; Operation:   The function sets a counter to 0, and initializes the current
;              digit to display to be the first one (0). It then increments the
;              counter through a loop until the counter is no longer less than
;              MAX_DIGIT, meaning it has reached the end of both numString and
;              muxBuffer. Since both numString and muxBuffer are the same size,
;              every iteration a byte at index = counter from both arrays are
;              set to 0.
;
; Arguments:        None.
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: numString - contains the ASCII characters to display
;                   muxBuffer - contains the 7-segment codes translated from
;                               the ASCII characters to display.
; Global Variables: None.
;
; Input:  None.
; Output: An empty display board.
;
; Error Handling: None.
;
; Limitations: None.
;
; Algorithms: None.
; Data Structures: numString (an array that stores every ASCII char to display)
;                  muxBuffer (an array that stores every 7-seg code to display)
;
; Registers Changed: BX
; Stack depth: 1 word.
;
; Author: Nancy Cao
; Revision History:
;     11/01/15  Nancy Cao        initial revision
;     11/01/15  Nancy Cao        added comments
;     11/03/15  Nancy Cao        added comments
;

InitDisplay  PROC        NEAR
             PUBLIC      InitDisplay

	PUSH BX                 ; make sure not to rewrite data in register
    
	MOV BX, 0               ; initialize counter to store all the arrays
    MOV CURRENT_DIGIT, 0    ; first digit to display

EndOfReset:                 ; check if byte is initialized
    CMP BX, MAX_DIGIT       ; check if end of the arrays are reached
	JZ EndDisplayInit       ; if yes, finished clearing out all the bytes
    ;JNZ ResetDisplay       ; otherwise continue initalizing arrays

ResetDisplay:               ; reset display by clearing numString and muxBuffer
	MOV numString[BX], 0    ; clear current byte stored in numString
	MOV muxBuffer[BX], 0    ; clear current byte stored in muxBuffer
	INC BX                  ; increment to next byte to clear
	JMP EndOfReset          ; loop to next byte

EndDisplayInit:             ; all bytes are cleared out
	Pop BX                  ; return old data to register
	RET                     ; finished clearing out display for next value
	
InitDisplay       ENDP


; Display
; 
; Description: This function takes in an argument that references the address of
;              the <null> terminated string that is no more than 5 ASCII
;              characters long (for a decimal) or 4 ASCII characters long (for
;              a hex). The address refers to a MAX_DIGIT length array
;              (numString) that stores the string. It translates the string into
;              7-segment code. The 7-segment code is then stored in a shared
;              muxBuffer, whose length is also MAX_DIGIT. If the translated
;              ASCII characters end up being more than MAX_DIGIT long, the rest
;              of the digits are truncated to fit the display board. If the
;              translated ASCII characters do not fill up the display board,
;              the digits are left justified and unused digits are left blank.
;
; Operation:   The function is passed in an address of the <null> terminated
;              string, which is stored in an array called numString which is at
;              most MAX_DIGIT bytes long. There is a counter that signifies
;              which ASCII character is currently being translated into the
;              7-segment code. The loop first checks if the counter has reached
;              MAX_DIGIT. If so, the loop terminates and the function returns,
;              since the display board will not be able to display any more
;              characters. If not, the loop retreives the current ASCII
;              character to translate. If the ASCII character is the <null>
;              terminator, the end of the string is reached, and the loop
;              exits. If not, the function uses XLAT to look in the
;              7-segment lookup table and figure out the 7-segment code
;              representation on the display for that character, then stores it
;              into the muxBuffer. If all the ASCII characters are translated
;              without truncation, the function checks if there are any unused
;              spaces after the end of the string displayed. If so, these
;              unused spaces are set to blanks (0) using another loop to
;              MAX_DIGIT.
;
; Arguments:        str (SI)  - the address of <null> terminated string to
;                               output to the LED display
; Return Value:     None.
; Local Variables:  None.
; Shared Variables: muxBuffer - contains the 7-segment codes for all the ASCII
;                               characters to display.
; Global Variables: None.
;
; Input: None.
; Output: Digits on the LED display board
;
; Error Handling: None.
;
; Limitations: Can display at most MAX_DIGIT.
;
; Algorithms: None.
; Data Structures: muxBuffer (an array that stores every 7-segment code).
;
; Registers Changed: AX, BX, CX, DX
;
; Author: Nancy Cao
; Revision History:
;     10/27/15  Nancy Cao        initial comments and pseudocode
;     10/31/15  Nancy Cao        initial revision
;     11/01/15  Nancy Cao        updated comments

Display      PROC        NEAR
             PUBLIC      Display             

    PUSH SI                  ; save current value stored in SI to stack
    PUSH BX
             
InitializeCounter:           ; sets char count to 0 before looping ASCII chars
	MOV DI, 0                ; # of iterations through the ASCII string
    ;JMP CheckCharDisplayed  ; proceed to translate characters
	
CheckCharDisplayed:          ; check if display is completely used by chars
	CMP DI, MAX_DIGIT        ; board can display at most MAX_DIGIT chars
	JZ  FinishConverting     ; if iterated more than MAX_DIGIT chars then done
	JMP StringToSegcode      ; otherwise convert current string char to segcode

StringToSegcode:             ; ASCII char to seg code from lookup table
	MOV AL, ES:[SI]          ; the current ASCII character to translate to code
    CMP AL, ASCII_NULL       ; check if we reached the end of the string
	JZ  FinishConverting     ; if yes we are done converting the ASCII string
    ;JNZ ContinueConverting  ; if not continue converting
    
ContinueConverting:
    MOV BX, OFFSET(ASCIISegTable)  ; import 7-seg table for converion using xlat
	XLAT CS:ASCIISegTable    ; translate current character to 7-seg code
	MOV muxBuffer[DI], AL    ; store 7-seg code into buffer
	INC DI                   ; increase counter to next byte in buffer for store
    INC SI                   ; the next ASCII character to translate to code
	JMP CheckCharDisplayed   ; loop and do the same with next character
	
FinishConverting:            ; done loading buffer
    CMP DI, MAX_DIGIT        ; check if translated string fills up board
    JL  FillZero             ; if not, clear the rest from previous displays
    JMP Done                 ; otherwise, conversion is done

FillZero:                    ; fill unused digits as blanks
    MOV muxBuffer[DI], 0     ; fill current digit as a blank display
    INC DI                   ; increment to the next digit to output as blank
    JMP FinishConverting     ; go back to check if rest of board is cleared

Done:
    POP BX
    POP SI                   ; restore previous register value
	RET                      ; return

Display       ENDP

; DisplayNum
; 
; Description: This function takes in a 16-bit signed value, converts it to
;              a decimal in ASCII form with a <null> terminated string which is
;              at most 5 characters in addition to the + or - sign, and
;              passes the string into the Display function defined above.
;              The conversion references the Dec2String function found in
;              converts.asm. The string is left justified.
;
; Operation:   This function passes in the 16-bit signed value stored in AX,
;              and calls Dec2String, which is defined in converts.asm.
;              Dec2String converts the 16-bit signed value into a decimal,
;              and returns it as a sign and at most 5 character ASCII digits,
;              ending with a <null> terminator. This result is then passed into
;              the Display function defined above, which will display the ASCII
;              digits onto the LED display.
;
; Arguments:         n (AX) - the 16-bit signed value that is to be output in
;                             decimal form
; Return Value:      None.
; Local Variables:   a (BX) - address where the ASCII form of the decimal
;                             with the null terminator is stored
; Shared Variables:  numString - contains the ASCII characters to display
; Global Variables:  None.
;
; Input:  None.
; Output: The decimal value of n on the LED display board.
;
; Error Handling: None.
;
; Limitations: Can only display at most 5 digits and the sign value on the
;              board due to limitations of Dec2String.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: SI
;
; Author: Nancy Cao
; Revision History:
;     10/27/15  Nancy Cao        initial comments and pseudocode
;     10/31/15  Nancy Cao        initial revision

DisplayNum   PROC        NEAR
             PUBLIC      DisplayNum

LEA  SI, numString          ; load the address for Dec2String arguments

PUSH DS                     ; save current DS memory
POP  ES                     ; switch to ES memory to pass value to display

PUSH ES                     ; save register values on stack before conversion
PUSH SI
CALL Dec2String             ; convert 16-bit value (n) to decimal ASCII chars
POP  SI                     ; restore register values from stack
POP  ES

CALL Display                ; display ASCII chars; function works on ES:SI

RET

DisplayNum       ENDP

; DisplayHex
; 
; Description: This function takes in a 16-bit unsigned value, converts it to
;              a hexadecimal in ASCII form with a <null> terminated string which
;              is at most 5 characters long, and passes the string into the
;              Display function defined above. The conversion references the
;              Hex2String function found in converts.asm. It is left justified.
;
; Operation:   This function passes in the 16-bit unsigned value stored in AX,
;              and calls Hex2String, which is defined in converts.asm.
;              Hex2String converts the 16-bit unsigned value to a hexadecimal,
;              and returns it as at most 4 character ASCII digits,
;              ending with a <null> terminator. This result is then passed into
;              the Display function defined above, which will display the ASCII
;              digits onto the LED display.
;
; Arguments:         n (AX)   - the 16-bit unsigned value that is to be output
;                               in hexadecimal form
; Return Value:      None.
; Local Variables:   a        - address where the ASCII form of hexaadecimal
;                               with null terminator is stored
; Shared Variables:  numString - contains the ASCII characters to display
; Global Variables:  time - the number of milliseconds that have passed
;
; Input:  None.
; Output: The hexadecimal value of n on the LED display board.
;
; Error Handling: None.
;
; Limitations: Can only display at most 4 digits on board due to limitations
;              of Hex2String.
;
; Algorithms: None.
; Data Structures: None.
;
; Registers Changed: SI
;	
; Author: Nancy Cao
; Revision History:
;     10/27/15  Nancy Cao        initial comments and pseudocode
;     10/31/15  Nancy Cao        initial code
;

DisplayHex   PROC        NEAR
             PUBLIC      DisplayHex

LEA  SI, numString         ; load the address for Hex2String arguments

PUSH DS                     ; save current DS memory
POP  ES                     ; switch to ES memory to pass value to display

PUSH ES                     ; save register in stack before conversion
PUSH SI
CALL Hex2String             ; convert 16-bit value (n) to decimal ASCII chars
POP  SI                     ; return register from stack
POP  ES

CALL Display                ; display ASCII chars; function works on ES:SI

RET

DisplayHex       ENDP


; Multiplex
; 
; Description: This function determines what is the next digit to display on
;              the board. It reads from a shared buffer that contains
;              the 7-segment codes for the current ASCII string to be displayed.
;
; Operation:   The function increments the current digit that is being displayed
;              The function then accesses the digit at that particular
;              index in the buffer and retrieves the 7-segment value. The
;              function goes through every byte in the 7-segment value and
;              outputs it to the board.
;
; Arguments:       None.
; Return Value:    None.
; Local Variables: None.
; Shared Variables: muxBuffer      - contains the 7-segment codes for all the ASCII
;                                    characters to display.
;                   MAX_DIGIT      - the max number of digits that can be
;                                    displayed on the board
;                   CURRENT_DIGIT  - the current digit to display
; Global Variables: None.
;
; Input: None.
; Output: A digit on the LED display board.
;
; Error Handling: None.
;
; Limitations: Can only display 1 digit at a time.
;
; Algorithms: None.
; Data Structures: Buffer (an array).
;
; Registers Changed: BX, AX, DX.
;
; Author: Nancy Cao
; Revision History:
;     10/27/15  Nancy Cao        initial comments and pseudocode
;     11/01/15  Nancy Cao        initial revision
;     11/03/15  Nancy Cao        incremented current digit properly
;

Multiplex    PROC        NEAR
             PUBLIC      Multiplex
      
INC  CURRENT_DIGIT                 ; move to the next digit to display
AND  CURRENT_DIGIT, MAX_DIGIT - 1  ; wrap around index in case out of bounds
MOV   BX, CURRENT_DIGIT            ; current digit displayed
MOV   AL, muxBuffer[BX]            ; retrieve next digit
MOV   DX, BX                       ; the current digit
OUT   DX, AL                       ; output digit on board
RET

Multiplex       ENDP
	
CODE ENDS

;the data segment

DATA    SEGMENT PUBLIC  'DATA'

numString       DB MAX_DIGIT DUP (?)   ; holds Max_Digit ASCII vals to display
muxBuffer       DB MAX_DIGIT DUP (?)   ; holds Max_Digit 7-seg codes to display
CURRENT_DIGIT   DW     ?               ; the current digit to display from mux


DATA    ENDS

END
