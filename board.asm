; ============================================================================
; board.asm - Board Representation and Basic Operations
; Chess Engine Project
; ============================================================================
; This module handles the chess board representation using a simple
; mailbox approach (8×8 array, 64 bytes total).
;
; Functions:
;   - board_init:       Initialize board to starting position
;   - board_clear:      Clear entire board
;   - board_get_piece:  Get piece at given square
;   - board_set_piece:  Set piece at given square
;   - board_clear_sq:   Clear specific square
;   - board_copy:       Copy board state (for make/unmake)
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; board_init - Initialize board to standard starting position
;
; Input:  None
; Output: None
; Modifies: FSR0, WREG, temp1
; ============================================================================
board_init:
    ; First, clear the entire board
    CALL    board_clear

    ; Set up white pieces (Rank 1)
    MOVLW   W_ROOK
    MOVWF   board + A1      ; a1 = White Rook
    MOVWF   board + H1      ; h1 = White Rook

    MOVLW   W_KNIGHT
    MOVWF   board + B1      ; b1 = White Knight
    MOVWF   board + G1      ; g1 = White Knight

    MOVLW   W_BISHOP
    MOVWF   board + C1      ; c1 = White Bishop
    MOVWF   board + F1      ; f1 = White Bishop

    MOVLW   W_QUEEN
    MOVWF   board + D1      ; d1 = White Queen

    MOVLW   W_KING
    MOVWF   board + E1      ; e1 = White King

    ; Set up white pawns (Rank 2)
    MOVLW   W_PAWN
    MOVWF   board + A2
    MOVWF   board + B2
    MOVWF   board + C2
    MOVWF   board + D2
    MOVWF   board + E2
    MOVWF   board + F2
    MOVWF   board + G2
    MOVWF   board + H2

    ; Set up black pawns (Rank 7)
    MOVLW   B_PAWN
    MOVWF   board + A8 - 8  ; A7 = 48
    MOVWF   board + B8 - 8  ; B7 = 49
    MOVWF   board + C8 - 8  ; C7 = 50
    MOVWF   board + D8 - 8  ; D7 = 51
    MOVWF   board + E8 - 8  ; E7 = 52
    MOVWF   board + F8 - 8  ; F7 = 53
    MOVWF   board + G8 - 8  ; G7 = 54
    MOVWF   board + H8 - 8  ; H7 = 55

    ; Set up black pieces (Rank 8)
    MOVLW   B_ROOK
    MOVWF   board + A8      ; a8 = Black Rook
    MOVWF   board + H8      ; h8 = Black Rook

    MOVLW   B_KNIGHT
    MOVWF   board + B8      ; b8 = Black Knight
    MOVWF   board + G8      ; g8 = Black Knight

    MOVLW   B_BISHOP
    MOVWF   board + C8      ; c8 = Black Bishop
    MOVWF   board + F8      ; f8 = Black Bishop

    MOVLW   B_QUEEN
    MOVWF   board + D8      ; d8 = Black Queen

    MOVLW   B_KING
    MOVWF   board + E8      ; e8 = Black King

    ; Initialize game state
    CLRF    game_turn               ; White to move
    MOVLW   0x0F                    ; All castling rights
    MOVWF   castle_rights
    MOVLW   NO_SQUARE
    MOVWF   enpassant_square        ; No en passant
    CLRF    halfmove_clock
    MOVLW   0x01
    MOVWF   fullmove_lo
    CLRF    fullmove_hi
    CLRF    game_status             ; Game ongoing
    MOVLW   LEVEL_EVAL              ; Default to Level 2
    MOVWF   ai_level

    ; Store king positions for quick access
    MOVLW   E1
    MOVWF   white_king_sq
    MOVLW   E8
    MOVWF   black_king_sq

    CLRF    in_check
    CLRF    check_count

    RETURN

; ============================================================================
; board_clear - Clear entire board (set all squares to empty)
;
; Input:  None
; Output: None
; Modifies: FSR0, WREG, temp1
; ============================================================================
board_clear:
    ; Use FSR0 to point to board
    MOVLW   LOW board
    MOVWF   FSR0L
    MOVLW   HIGH board
    MOVWF   FSR0H

    ; Clear counter
    MOVLW   BOARD_SIZE
    MOVWF   temp1

    ; Clear loop
board_clear_loop:
    CLRF    POSTINC0        ; Clear current square, increment pointer
    DECFSZ  temp1, F        ; Decrement counter
    GOTO    board_clear_loop

    RETURN

; ============================================================================
; board_get_piece - Get piece at specified square
;
; Input:  WREG = square index (0-63)
; Output: WREG = piece code (or EMPTY if square is empty)
; Modifies: FSR0, WREG
; ============================================================================
board_get_piece:
    ; Add square offset to board base address
    ADDLW   LOW board
    MOVWF   FSR0L
    MOVLW   HIGH board
    MOVWF   FSR0H
    BTFSC   STATUS, C       ; Check if carry from low byte addition
    INCF    FSR0H, F        ; Propagate carry to high byte

    ; Read piece from board
    MOVF    INDF0, W

    RETURN

; ============================================================================
; board_set_piece - Set piece at specified square
;
; Input:  curr_square = square index (0-63)
;         curr_piece = piece code to set
; Output: None
; Modifies: FSR0, WREG
; ============================================================================
board_set_piece:
    ; Calculate address: board + curr_square
    MOVF    curr_square, W
    ADDLW   LOW board
    MOVWF   FSR0L
    MOVLW   HIGH board
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Write piece to board
    MOVF    curr_piece, W
    MOVWF   INDF0

    ; If piece is a king, update king position cache
    MOVF    curr_piece, W
    ANDLW   PIECE_MASK
    SUBLW   KING
    BNZ     board_set_piece_done    ; Not a king, we're done

    ; It's a king, update position
    MOVF    curr_piece, W
    ANDLW   COLOR_MASK
    BNZ     board_set_piece_black_king

    ; White king
    MOVF    curr_square, W
    MOVWF   white_king_sq
    GOTO    board_set_piece_done

board_set_piece_black_king:
    MOVF    curr_square, W
    MOVWF   black_king_sq

board_set_piece_done:
    RETURN

; ============================================================================
; board_clear_sq - Clear specific square (set to empty)
;
; Input:  WREG = square index (0-63)
; Output: None
; Modifies: FSR0, WREG
; ============================================================================
board_clear_sq:
    ; Calculate address: board + square
    ADDLW   LOW board
    MOVWF   FSR0L
    MOVLW   HIGH board
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Clear square
    CLRF    INDF0

    RETURN

; ============================================================================
; board_is_square_attacked - Check if a square is attacked by given color
;
; Input:  attack_square = square to check (0-63)
;         attack_color = color of attacking side (0x00 or 0x08)
; Output: WREG = 1 if attacked, 0 if not
;         attack_found = 1 if attacked, 0 if not
; Modifies: Many registers (uses movegen functions)
; ============================================================================
board_is_square_attacked:
    ; This is a complex function that checks if the given square
    ; is under attack by any piece of the given color.
    ; Implementation will be in check.asm as it requires move generation
    ; Placeholder for now
    CLRF    attack_found
    CLRF    WREG
    RETURN

; ============================================================================
; board_square_to_algebraic - Convert square index to algebraic notation
;
; Input:  WREG = square index (0-63)
; Output: temp1 = file character ('a'-'h')
;         temp2 = rank character ('1'-'8')
; Modifies: WREG, temp1, temp2, temp3
; ============================================================================
board_square_to_algebraic:
    MOVWF   temp3           ; Save square

    ; Get file (square % 8)
    ANDLW   0x07
    ADDLW   ASCII_a         ; Convert to 'a'-'h'
    MOVWF   temp1           ; Store file character

    ; Get rank (square / 8)
    MOVF    temp3, W
    SWAPF   WREG, W         ; Divide by 16
    ANDLW   0x0F
    RRNCF   WREG, F         ; Divide by 2 (total divide by 8)
    ADDLW   ASCII_0 + 1     ; Convert to '1'-'8'
    MOVWF   temp2           ; Store rank character

    RETURN

; ============================================================================
; board_algebraic_to_square - Convert algebraic notation to square index
;
; Input:  temp1 = file character ('a'-'h' or 'A'-'H')
;         temp2 = rank character ('1'-'8')
; Output: WREG = square index (0-63), or 0xFF if invalid
; Modifies: WREG, temp3, temp4
; ============================================================================
board_algebraic_to_square:
    ; Convert file character to 0-7
    MOVF    temp1, W
    SUBLW   ASCII_a         ; Check if lowercase
    BNC     board_alg_try_upper

    ; Lowercase
    MOVF    temp1, W
    SUBLW   ASCII_a
    NEGF    WREG            ; Make positive
    GOTO    board_alg_check_file

board_alg_try_upper:
    ; Try uppercase
    MOVF    temp1, W
    SUBLW   ASCII_A
    NEGF    WREG

board_alg_check_file:
    MOVWF   temp3           ; Store file (0-7)

    ; Validate file (0-7)
    MOVLW   7
    SUBWF   temp3, W
    BC      board_alg_invalid   ; file > 7

    ; Convert rank character to 0-7
    MOVF    temp2, W
    SUBLW   ASCII_0 + 1
    NEGF    WREG
    MOVWF   temp4           ; Store rank (0-7)

    ; Validate rank (0-7)
    MOVLW   7
    SUBWF   temp4, W
    BC      board_alg_invalid   ; rank > 7

    ; Calculate square = rank * 8 + file
    MOVF    temp4, W
    RLNCF   WREG, F         ; rank * 2
    RLNCF   WREG, F         ; rank * 4
    RLNCF   WREG, F         ; rank * 8
    ADDWF   temp3, W        ; + file

    RETURN

board_alg_invalid:
    MOVLW   NO_SQUARE
    RETURN

; ============================================================================
; board_piece_to_char - Convert piece code to ASCII character
;
; Input:  WREG = piece code
; Output: WREG = ASCII character
; Modifies: WREG
; ============================================================================
board_piece_to_char:
    MOVWF   temp1           ; Save piece

    ; Check if empty
    MOVF    temp1, W
    ANDLW   PIECE_MASK
    BZ      board_p2c_empty

    ; Get color
    MOVF    temp1, W
    ANDLW   COLOR_MASK
    MOVWF   temp2           ; temp2 = color (0x00 or 0x08)

    ; Get piece type
    MOVF    temp1, W
    ANDLW   PIECE_MASK

    ; Use jump table
    ADDWF   PCL, F

    ; Jump table (indexed by piece type 1-6)
    GOTO    board_p2c_empty     ; 0 (shouldn't happen)
    GOTO    board_p2c_pawn      ; 1
    GOTO    board_p2c_knight    ; 2
    GOTO    board_p2c_bishop    ; 3
    GOTO    board_p2c_rook      ; 4
    GOTO    board_p2c_queen     ; 5
    GOTO    board_p2c_king      ; 6

board_p2c_pawn:
    MOVLW   'P'
    GOTO    board_p2c_apply_color

board_p2c_knight:
    MOVLW   'N'
    GOTO    board_p2c_apply_color

board_p2c_bishop:
    MOVLW   'B'
    GOTO    board_p2c_apply_color

board_p2c_rook:
    MOVLW   'R'
    GOTO    board_p2c_apply_color

board_p2c_queen:
    MOVLW   'Q'
    GOTO    board_p2c_apply_color

board_p2c_king:
    MOVLW   'K'
    GOTO    board_p2c_apply_color

board_p2c_apply_color:
    ; If black, convert to lowercase (add 0x20)
    MOVWF   temp3           ; Save character
    MOVF    temp2, F        ; Test color
    BZ      board_p2c_white ; White (uppercase)

    ; Black (lowercase)
    MOVLW   0x20
    ADDWF   temp3, F

board_p2c_white:
    MOVF    temp3, W
    RETURN

board_p2c_empty:
    MOVLW   ' '
    RETURN

; ============================================================================
; End of board.asm
; ============================================================================
