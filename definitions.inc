; ============================================================================
; definitions.inc - Constants, Macros, and Definitions
; Chess Engine Project
; ============================================================================

; ============================================================================
; PIECE ENCODINGS (4-bit piece type + 1-bit color)
; ============================================================================
EMPTY       EQU 0x00
PAWN        EQU 0x01
KNIGHT      EQU 0x02
BISHOP      EQU 0x03
ROOK        EQU 0x04
QUEEN       EQU 0x05
KING        EQU 0x06

; Color bit (bit 3)
WHITE       EQU 0x00
BLACK       EQU 0x08

; Complete piece encodings
W_PAWN      EQU 0x01    ; 0000 0001
W_KNIGHT    EQU 0x02    ; 0000 0010
W_BISHOP    EQU 0x03    ; 0000 0011
W_ROOK      EQU 0x04    ; 0000 0100
W_QUEEN     EQU 0x05    ; 0000 0101
W_KING      EQU 0x06    ; 0000 0110

B_PAWN      EQU 0x09    ; 0000 1001
B_KNIGHT    EQU 0x0A    ; 0000 1010
B_BISHOP    EQU 0x0B    ; 0000 1011
B_ROOK      EQU 0x0C    ; 0000 1100
B_QUEEN     EQU 0x0D    ; 0000 1101
B_KING      EQU 0x0E    ; 0000 1110

; Piece type mask
PIECE_MASK  EQU 0x07    ; Mask to get piece type
COLOR_MASK  EQU 0x08    ; Mask to get color

; ============================================================================
; BOARD CONSTANTS
; ============================================================================
BOARD_SIZE  EQU 64      ; 8x8 board
NO_SQUARE   EQU 0xFF    ; Invalid square marker

; Square indices (a1=0, b1=1, ..., h8=63)
; Rank 1 (White's back rank)
A1          EQU 0
B1          EQU 1
C1          EQU 2
D1          EQU 3
E1          EQU 4
F1          EQU 5
G1          EQU 6
H1          EQU 7

; Rank 2
A2          EQU 8
B2          EQU 9
C2          EQU 10
D2          EQU 11
E2          EQU 12
F2          EQU 13
G2          EQU 14
H2          EQU 15

; Rank 8 (Black's back rank)
A8          EQU 56
B8          EQU 57
C8          EQU 58
D8          EQU 59
E8          EQU 60
F8          EQU 61
G8          EQU 62
H8          EQU 63

; ============================================================================
; MOVE FLAGS (Byte 2 of move structure)
; ============================================================================
MOVE_CAPTURE    EQU 0x80    ; Bit 7: Capture flag
MOVE_PROMOTION  EQU 0x40    ; Bit 6: Promotion flag
MOVE_CASTLE     EQU 0x20    ; Bit 5: Castling flag
MOVE_ENPASSANT  EQU 0x10    ; Bit 4: En passant flag

; Promotion pieces (bits 3-2)
PROMO_QUEEN     EQU 0x00
PROMO_ROOK      EQU 0x04
PROMO_BISHOP    EQU 0x08
PROMO_KNIGHT    EQU 0x0C

; ============================================================================
; CASTLING RIGHTS FLAGS
; ============================================================================
CASTLE_WK   EQU 0x01    ; White kingside
CASTLE_WQ   EQU 0x02    ; White queenside
CASTLE_BK   EQU 0x04    ; Black kingside
CASTLE_BQ   EQU 0x08    ; Black queenside

; ============================================================================
; GAME STATUS
; ============================================================================
STATUS_ONGOING      EQU 0
STATUS_CHECKMATE    EQU 1
STATUS_STALEMATE    EQU 2
STATUS_DRAW         EQU 3

; ============================================================================
; AI DIFFICULTY LEVELS
; ============================================================================
LEVEL_RANDOM    EQU 1
LEVEL_EVAL      EQU 2
LEVEL_MINIMAX   EQU 3

; ============================================================================
; EVALUATION CONSTANTS
; ============================================================================
VAL_PAWN    EQU 100
VAL_KNIGHT  EQU 300
VAL_BISHOP  EQU 300
VAL_ROOK    EQU 500
VAL_QUEEN   EQU 900
VAL_KING    EQU 0       ; King has no material value (invaluable)

EVAL_MIN    EQU 0x8000  ; -32768 (checkmate for us)
EVAL_MAX    EQU 0x7FFF  ; +32767 (checkmate for opponent)

; ============================================================================
; BUFFER SIZES
; ============================================================================
MAX_MOVES       EQU 70      ; Maximum moves to store (70*4 = 280 bytes)
UART_RX_SIZE    EQU 64      ; UART receive buffer
UART_TX_SIZE    EQU 128     ; UART transmit buffer
MINIMAX_DEPTH   EQU 3       ; Search depth for Level 3
MINIMAX_STACK   EQU 50      ; Stack size for minimax (50*4 = 200 bytes)

; ============================================================================
; DIRECTION OFFSETS (for move generation)
; ============================================================================
; Note: Board is represented as 0-63, where:
; - Adding 8 moves up one rank
; - Adding 1 moves right one file
; - Subtracting 8 moves down one rank
; - Subtracting 1 moves left one file

DIR_N       EQU 8       ; North (up)
DIR_S       EQU -8      ; South (down)
DIR_E       EQU 1       ; East (right)
DIR_W       EQU -1      ; West (left)
DIR_NE      EQU 9       ; Northeast
DIR_NW      EQU 7       ; Northwest
DIR_SE      EQU -7      ; Southeast
DIR_SW      EQU -9      ; Southwest

; ============================================================================
; UART CONSTANTS
; ============================================================================
BAUD_RATE   EQU 9600
FOSC        EQU 16000000    ; 16 MHz internal oscillator

; ============================================================================
; MACROS
; ============================================================================

; Macro: GET_FILE - Get file (column) from square (0-7)
; Input: square in WREG
; Output: file in WREG (0-7, where 0=a, 7=h)
GET_FILE    MACRO
    ANDLW   0x07
    ENDM

; Macro: GET_RANK - Get rank (row) from square (0-7)
; Input: square in WREG
; Output: rank in WREG (0-7, where 0=rank 1, 7=rank 8)
GET_RANK    MACRO
    SWAPF   WREG, W
    ANDLW   0x07
    RRNCF   WREG, F
    ENDM

; Macro: MAKE_SQUARE - Create square from file and rank
; Input: file in WREG, rank in temp register
; Output: square in WREG
MAKE_SQUARE MACRO   rank_reg
    RLNCF   rank_reg, W
    RLNCF   WREG, W
    RLNCF   WREG, W
    ADDWF   WREG, F     ; WREG now has rank*8 + file
    ENDM

; Macro: GET_PIECE_TYPE - Get piece type without color
; Input: piece in WREG
; Output: piece type in WREG
GET_PIECE_TYPE  MACRO
    ANDLW   PIECE_MASK
    ENDM

; Macro: GET_PIECE_COLOR - Get piece color
; Input: piece in WREG
; Output: color in WREG (0x00 or 0x08)
GET_PIECE_COLOR MACRO
    ANDLW   COLOR_MASK
    ENDM

; Macro: IS_EMPTY - Check if square is empty
; Input: piece in WREG
; Output: Z flag set if empty
IS_EMPTY    MACRO
    ANDLW   0xFF
    ENDM

; Macro: PUSH16 - Push 16-bit value onto software stack
; Input: FSR1 points to stack, value in reg_hi:reg_lo
PUSH16  MACRO   reg_hi, reg_lo
    MOVF    reg_lo, W
    MOVWF   POSTINC1
    MOVF    reg_hi, W
    MOVWF   POSTINC1
    ENDM

; Macro: POP16 - Pop 16-bit value from software stack
; Input: FSR1 points to stack
; Output: value in reg_hi:reg_lo
POP16   MACRO   reg_hi, reg_lo
    MOVF    POSTDEC1, W
    MOVWF   reg_hi
    MOVF    POSTDEC1, W
    MOVWF   reg_lo
    ENDM

; Macro: DELAY_MS - Simple delay (approximate)
; Input: count in WREG (milliseconds)
DELAY_MS    MACRO   count
    LOCAL   loop1, loop2
    MOVLW   count
    MOVWF   delay_count
loop1:
    MOVLW   250
    MOVWF   delay_temp
loop2:
    DECFSZ  delay_temp, F
    GOTO    loop2
    DECFSZ  delay_count, F
    GOTO    loop1
    ENDM

; ============================================================================
; ASCII CONSTANTS (for display and parsing)
; ============================================================================
ASCII_0     EQU 0x30
ASCII_9     EQU 0x39
ASCII_A     EQU 0x41
ASCII_Z     EQU 0x5A
ASCII_a     EQU 0x61
ASCII_z     EQU 0x7A
ASCII_SPACE EQU 0x20
ASCII_CR    EQU 0x0D
ASCII_LF    EQU 0x0A

; ============================================================================
; End of definitions.inc
; ============================================================================
