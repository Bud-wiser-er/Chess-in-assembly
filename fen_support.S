; ============================================================================
; fen_support.S - FEN (Forsyth-Edwards Notation) Parser and Generator
; PIC18F45K22 Chess Engine
; ============================================================================
; This module provides FEN string parsing and generation for chess positions.
;
; FEN Format: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
;
; Components:
;   1. Piece placement (rank 8 to rank 1, '/' separates ranks)
;   2. Active color ('w' or 'b')
;   3. Castling rights ('K'=white kingside, 'Q'=white queenside,
;                       'k'=black kingside, 'q'=black queenside, '-'=none)
;   4. En passant target square (e.g., 'e3' or '-')
;   5. Halfmove clock (moves since last pawn move or capture)
;   6. Fullmove number (starts at 1, increments after black's move)
;
; Functions:
;   - fen_parse:     Parse FEN string and set board position
;   - fen_generate:  Generate FEN string from current position
;   - fen_rx_line:   Receive FEN from UART
;   - fen_tx_line:   Transmit FEN via UART
; ============================================================================

    PROCESSOR 18F45K22
    #include <xc.inc>

; ============================================================================
; External Variables (from chess_engine_complete.S)
; ============================================================================
; Assumed to be defined in main program:
;   board           - 64 byte array
;   game_turn       - 0=white, 1=black
;   castle_rights   - Bit flags for castling
;   enpassant_square - Target square or 0xFF
;   halfmove_clock  - Halfmove counter
;   fullmove_lo/hi  - Move number

; ============================================================================
; FEN Buffer Variables
; ============================================================================
PSECT udata_bank0
    fen_buffer:         DS 96   ; FEN string buffer (max ~90 chars)
    fen_ptr:            DS 1    ; Current position in buffer
    fen_rank:           DS 1    ; Current rank (0-7)
    fen_file:           DS 1    ; Current file (0-7)
    fen_square:         DS 1    ; Current square index
    fen_char:           DS 1    ; Current character
    fen_piece:          DS 1    ; Piece value

PSECT code

; ============================================================================
; fen_parse - Parse FEN string and update board
; Input:  fen_buffer = FEN string (null-terminated)
; Output: Board and game state updated
; ============================================================================
fen_parse:
    ; Initialize
    clrf    BANKMASK(fen_ptr)
    movlw   7                   ; Start at rank 7 (FEN rank 8)
    movwf   BANKMASK(fen_rank)
    clrf    BANKMASK(fen_file)

    ; Clear board first
    call    board_clear

; Parse piece placement (first field)
fen_parse_board_loop:
    ; Get next character
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    movwf   BANKMASK(fen_char)

    ; Increment pointer
    incf    BANKMASK(fen_ptr), F

    ; Check for space (end of piece placement)
    movf    BANKMASK(fen_char), W
    sublw   ' '
    bz      fen_parse_active_color

    ; Check for slash (next rank)
    movf    BANKMASK(fen_char), W
    sublw   '/'
    bnz     fen_not_slash

    ; Move to next rank
    decf    BANKMASK(fen_rank), F
    clrf    BANKMASK(fen_file)
    bra     fen_parse_board_loop

fen_not_slash:
    ; Check if it's a digit (empty squares)
    movf    BANKMASK(fen_char), W
    sublw   '9'
    bn      fen_not_digit

    movf    BANKMASK(fen_char), W
    sublw   '0'
    bn      fen_is_digit
    bra     fen_parse_board_loop

fen_is_digit:
    ; Skip N empty squares
    movf    BANKMASK(fen_char), W
    sublw   '0'
    negf    WREG
    addwf   BANKMASK(fen_file), F
    bra     fen_parse_board_loop

fen_not_digit:
    ; It's a piece character - decode it
    call    fen_char_to_piece
    movwf   BANKMASK(fen_piece)

    ; Calculate square index: rank * 8 + file
    movf    BANKMASK(fen_rank), W
    mullw   8
    movf    PRODL, W
    addwf   BANKMASK(fen_file), W
    movwf   BANKMASK(fen_square)

    ; Set piece on board
    movf    BANKMASK(fen_square), W
    addlw   LOW (board)
    movwf   FSR0L
    movlw   HIGH (board)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    BANKMASK(fen_piece), W
    movwf   INDF0

    ; Move to next file
    incf    BANKMASK(fen_file), F
    bra     fen_parse_board_loop

; Parse active color (second field)
fen_parse_active_color:
    ; Get character after space
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    incf    BANKMASK(fen_ptr), F

    ; 'w' = 0 (white), 'b' = 1 (black)
    sublw   'w'
    bz      fen_set_white

    movlw   1
    movwf   BANKMASK(game_turn)
    bra     fen_skip_space_2

fen_set_white:
    clrf    BANKMASK(game_turn)

; Skip space
fen_skip_space_2:
    incf    BANKMASK(fen_ptr), F

; Parse castling rights (third field)
fen_parse_castling:
    clrf    BANKMASK(castle_rights)

fen_parse_castling_loop:
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    movwf   BANKMASK(fen_char)
    incf    BANKMASK(fen_ptr), F

    ; Check for space (end of castling)
    sublw   ' '
    bz      fen_parse_enpassant

    ; Check for 'K'
    movf    BANKMASK(fen_char), W
    sublw   'K'
    bnz     fen_not_K
    bsf     BANKMASK(castle_rights), 0  ; White kingside
    bra     fen_parse_castling_loop

fen_not_K:
    ; Check for 'Q'
    movf    BANKMASK(fen_char), W
    sublw   'Q'
    bnz     fen_not_Q
    bsf     BANKMASK(castle_rights), 1  ; White queenside
    bra     fen_parse_castling_loop

fen_not_Q:
    ; Check for 'k'
    movf    BANKMASK(fen_char), W
    sublw   'k'
    bnz     fen_not_k
    bsf     BANKMASK(castle_rights), 2  ; Black kingside
    bra     fen_parse_castling_loop

fen_not_k:
    ; Check for 'q'
    movf    BANKMASK(fen_char), W
    sublw   'q'
    bnz     fen_parse_castling_loop
    bsf     BANKMASK(castle_rights), 3  ; Black queenside
    bra     fen_parse_castling_loop

; Parse en passant (fourth field)
fen_parse_enpassant:
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W

    ; Check for '-' (no en passant)
    sublw   '-'
    bz      fen_no_enpassant

    ; TODO: Parse algebraic square (e.g., "e3")
    ; For now, set to no en passant
fen_no_enpassant:
    movlw   0xFF
    movwf   BANKMASK(enpassant_square)

    ; Skip remaining fields (halfmove, fullmove)
    ; We'll just use defaults for now
    clrf    BANKMASK(halfmove_clock)
    movlw   1
    movwf   BANKMASK(fullmove_lo)
    clrf    BANKMASK(fullmove_hi)

    return

; ============================================================================
; fen_generate - Generate FEN string from current board
; Output: fen_buffer = FEN string (null-terminated)
; ============================================================================
fen_generate:
    clrf    BANKMASK(fen_ptr)

    ; Start from rank 7 (FEN rank 8)
    movlw   7
    movwf   BANKMASK(fen_rank)

fen_gen_rank_loop:
    clrf    BANKMASK(fen_file)
    clrf    temp1                   ; Empty square counter

fen_gen_file_loop:
    ; Calculate square: rank * 8 + file
    movf    BANKMASK(fen_rank), W
    mullw   8
    movf    PRODL, W
    addwf   BANKMASK(fen_file), W
    movwf   BANKMASK(fen_square)

    ; Get piece at square
    movf    BANKMASK(fen_square), W
    addlw   LOW (board)
    movwf   FSR0L
    movlw   HIGH (board)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    movwf   BANKMASK(fen_piece)

    ; Check if empty
    bz      fen_gen_empty_square

    ; Non-empty square - output any pending empty count
    movf    temp1, W
    bz      fen_gen_output_piece

    ; Output empty count
    addlw   '0'
    call    fen_put_char
    clrf    temp1

fen_gen_output_piece:
    ; Convert piece to character
    movf    BANKMASK(fen_piece), W
    call    fen_piece_to_char
    call    fen_put_char

    bra     fen_gen_next_file

fen_gen_empty_square:
    incf    temp1, F

fen_gen_next_file:
    incf    BANKMASK(fen_file), F
    movf    BANKMASK(fen_file), W
    xorlw   8                   ; Check if file == 8 (past 'h')
    bnz     fen_gen_file_loop   ; Continue if not yet 8

    ; End of rank - output empty count if any
    movf    temp1, W
    bz      fen_gen_rank_separator
    addlw   '0'
    call    fen_put_char
    clrf    temp1

fen_gen_rank_separator:
    ; Add '/' unless it's the last rank
    movf    BANKMASK(fen_rank), W
    bz      fen_gen_active_color

    movlw   '/'
    call    fen_put_char

    decf    BANKMASK(fen_rank), F
    bra     fen_gen_rank_loop

; Generate active color
fen_gen_active_color:
    movlw   ' '
    call    fen_put_char

    movf    BANKMASK(game_turn), W
    bz      fen_gen_white_turn

    movlw   'b'
    call    fen_put_char
    bra     fen_gen_castling

fen_gen_white_turn:
    movlw   'w'
    call    fen_put_char

; Generate castling rights
fen_gen_castling:
    movlw   ' '
    call    fen_put_char

    movf    BANKMASK(castle_rights), W
    bz      fen_gen_no_castling

    ; Check each castling bit and output character
    btfss   BANKMASK(castle_rights), 0
    bra     check_WQ
    movlw   'K'
    call    fen_put_char

check_WQ:
    btfss   BANKMASK(castle_rights), 1
    bra     check_BK
    movlw   'Q'
    call    fen_put_char

check_BK:
    btfss   BANKMASK(castle_rights), 2
    bra     check_BQ
    movlw   'k'
    call    fen_put_char

check_BQ:
    btfss   BANKMASK(castle_rights), 3
    bra     fen_gen_enpassant
    movlw   'q'
    call    fen_put_char

    bra     fen_gen_enpassant

fen_gen_no_castling:
    movlw   '-'
    call    fen_put_char

; Generate en passant
fen_gen_enpassant:
    movlw   ' '
    call    fen_put_char
    movlw   '-'
    call    fen_put_char

    ; Generate halfmove and fullmove (simple version)
    movlw   ' '
    call    fen_put_char
    movlw   '0'
    call    fen_put_char

    movlw   ' '
    call    fen_put_char
    movlw   '1'
    call    fen_put_char

    ; Null terminate
    clrf    WREG
    call    fen_put_char

    return

; ============================================================================
; Helper Functions
; ============================================================================

; Convert FEN character to piece value
fen_char_to_piece:
    ; Input: W = character
    ; Output: W = piece value
    movwf   temp1

    ; White pieces (uppercase)
    sublw   'P'
    bz      fen_char_is_WP
    movf    temp1, W
    sublw   'N'
    bz      fen_char_is_WN
    movf    temp1, W
    sublw   'B'
    bz      fen_char_is_WB
    movf    temp1, W
    sublw   'R'
    bz      fen_char_is_WR
    movf    temp1, W
    sublw   'Q'
    bz      fen_char_is_WQ
    movf    temp1, W
    sublw   'K'
    bz      fen_char_is_WK

    ; Black pieces (lowercase)
    movf    temp1, W
    sublw   'p'
    bz      fen_char_is_BP
    movf    temp1, W
    sublw   'n'
    bz      fen_char_is_BN
    movf    temp1, W
    sublw   'b'
    bz      fen_char_is_BB
    movf    temp1, W
    sublw   'r'
    bz      fen_char_is_BR
    movf    temp1, W
    sublw   'q'
    bz      fen_char_is_BQ
    movf    temp1, W
    sublw   'k'
    bz      fen_char_is_BK

    retlw   0x00    ; Empty

fen_char_is_WP:
    retlw   0x01
fen_char_is_WN:
    retlw   0x02
fen_char_is_WB:
    retlw   0x03
fen_char_is_WR:
    retlw   0x04
fen_char_is_WQ:
    retlw   0x05
fen_char_is_WK:
    retlw   0x06
fen_char_is_BP:
    retlw   0x09
fen_char_is_BN:
    retlw   0x0A
fen_char_is_BB:
    retlw   0x0B
fen_char_is_BR:
    retlw   0x0C
fen_char_is_BQ:
    retlw   0x0D
fen_char_is_BK:
    retlw   0x0E

; Convert piece value to FEN character
fen_piece_to_char:
    ; Input: W = piece value
    ; Output: W = character
    movwf   temp1

    andlw   0x0F
    sublw   0x01
    bz      fen_piece_is_pawn
    movf    temp1, W
    andlw   0x0F
    sublw   0x02
    bz      fen_piece_is_knight
    movf    temp1, W
    andlw   0x0F
    sublw   0x03
    bz      fen_piece_is_bishop
    movf    temp1, W
    andlw   0x0F
    sublw   0x04
    bz      fen_piece_is_rook
    movf    temp1, W
    andlw   0x0F
    sublw   0x05
    bz      fen_piece_is_queen
    movf    temp1, W
    andlw   0x0F
    sublw   0x06
    bz      fen_piece_is_king

    retlw   '?'

fen_piece_is_pawn:
    btfsc   temp1, 3        ; Check black bit
    retlw   'p'
    retlw   'P'

fen_piece_is_knight:
    btfsc   temp1, 3
    retlw   'n'
    retlw   'N'

fen_piece_is_bishop:
    btfsc   temp1, 3
    retlw   'b'
    retlw   'B'

fen_piece_is_rook:
    btfsc   temp1, 3
    retlw   'r'
    retlw   'R'

fen_piece_is_queen:
    btfsc   temp1, 3
    retlw   'q'
    retlw   'Q'

fen_piece_is_king:
    btfsc   temp1, 3
    retlw   'k'
    retlw   'K'

; Put character into FEN buffer
fen_put_char:
    ; Input: W = character
    movwf   temp1

    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    temp1, W
    movwf   INDF0

    incf    BANKMASK(fen_ptr), F
    return

; ============================================================================
; UART Functions for FEN
; ============================================================================

; Receive FEN string from UART
fen_rx_line:
    clrf    BANKMASK(fen_ptr)

fen_rx_loop:
    ; Wait for character
    btfss   PIR1, 5         ; RC1IF
    bra     fen_rx_loop

    movf    RCREG1, W

    ; Check for CR or LF
    sublw   0x0D
    bz      fen_rx_done
    movf    RCREG1, W
    sublw   0x0A
    bz      fen_rx_done

    ; Store character
    movf    RCREG1, W
    movwf   temp1

    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    temp1, W
    movwf   INDF0

    incf    BANKMASK(fen_ptr), F

    ; Check for buffer overflow
    movf    BANKMASK(fen_ptr), W
    sublw   95
    bnz     fen_rx_loop

fen_rx_done:
    ; Null terminate
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    clrf    INDF0

    return

; Transmit FEN string via UART
fen_tx_line:
    clrf    BANKMASK(fen_ptr)

fen_tx_loop:
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    bz      fen_tx_done

    ; Wait for TX ready
fen_tx_wait:
    btfss   PIR1, 4         ; TX1IF
    bra     fen_tx_wait

    movwf   TXREG1

    incf    BANKMASK(fen_ptr), F
    bra     fen_tx_loop

fen_tx_done:
    ; Send CR+LF
    movlw   0x0D
fen_tx_cr_wait:
    btfss   PIR1, 4
    bra     fen_tx_cr_wait
    movwf   TXREG1

    movlw   0x0A
fen_tx_lf_wait:
    btfss   PIR1, 4
    bra     fen_tx_lf_wait
    movwf   TXREG1

    return

; ============================================================================
; board_clear - Clear board to empty
; ============================================================================
board_clear:
    movlw   64
    movwf   temp1

    movlw   LOW (board)
    movwf   FSR0L
    movlw   HIGH (board)
    movwf   FSR0H

board_clear_loop:
    clrf    INDF0
    incf    FSR0L, F
    btfsc   STATUS, 0
    incf    FSR0H, F

    decfsz  temp1, F
    bra     board_clear_loop

    return

    END
