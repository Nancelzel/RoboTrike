;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  SERIALR.INC                               ;
;                         Serial I/O Routine Definitions                     ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the serial I/O routine functions.
;

; Addresses

SERIAL_BAUD     EQU     100H       ; baud rate generator divisor (R/W)
SERIAL_THR      EQU     100H       ; transmitter holding register (R/W)
SERIAL_RBR      EQU     100H       ; receiver buffer register (R/W)
SERIAL_DLL      EQU     100H
SERIAL_DLM      EQU     101H
SERIAL_IER      EQU     101H       ; interrupt enable register (R/W)
SERIAL_IIR      EQU     102H       ; interrupt identification register (R/W)
SERIAL_LCR      EQU     103H       ; line control register (R/W)
SERIAL_MCR      EQU     104H       ;
SERIAL_LSR      EQU     105H       ; line status register (R/W)
SERIAL_MSR      EQU     106H       ; modem status register (R/W)
EOI             EQU     0FF22H     ; address of EOI


; Line Control Register

ENABLE_BAUD_MASK   EQU     10000000B  ; enable access to the baud rate divisor
DISABLE_BAUD_MASK  EQU     01111111B  ; mask to disable access to the baud rate divisor
ENABLE_PARITY      EQU     00011100B  ; enable all parity bits
ENABLE_ETBE_MASK   EQU     00000010B  ; enable access to the ETBE
DISABLE_ETBE_MASK  EQU     00001101B  ; mask to disable access to the ETBE
SERIAL_SETUP       EQU     00000011B  ; 0-------  access Rx/Tx data registers
                                      ; -0------  no break output
                                      ; --000---  no parity
                                      ; -----0--  one stop bit
                                      ; ------11  8 data bits

; Interrupt Enable/Disable Register

SERIAL_DIS_IRQ  EQU     00000000B  ; disable all interrupts
SERIAL_IN_IRQ   EQU     00001111B  ; enables the four interrupts:
                                   ; modem status (bit 3)
                                   ; receiver line status (bit 2),
                                   ; transmitter holding register empty (bit 1)
                                   ; receiver data ready/char timeout (bit 0)
                                   
; general definitions

DEFAULT_BAUD    EQU     2         ; the index of the default baud divisor
DEFAULT_PARITY  EQU     0         ; the index of the parity
IIR_MASK        EQU     111B      ; mask out all the bits of IIR except bottom
                                  ; 3 bits
ERROR_MASK      EQU     00011110B ; used to mask out the error in LSR
EOI_VALUE       EQU     14        ; value of EOI to pass
EVENT_RBR       EQU     2         ; RBR event occured
EVENT_ERROR     EQU     3         ; error event occurd