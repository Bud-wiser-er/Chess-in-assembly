; ============================================================================
; check.asm - Check, Checkmate, and Stalemate Detection
; Chess Engine Project
; ============================================================================
; This module detects check, checkmate, and stalemate conditions.
;
; Functions:
;   - is_in_check:          Check if current side's king is in check
;   - is_checkmate:         Check for checkmate
;   - is_stalemate:         Check for stalemate
;   - has_legal_moves:      Check if current side has any legal moves
;   - is_square_attacked:   Check if square is attacked by given color
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; is_in_check - Check if current side's king is in check
;
; Input:  game_turn = current player
; Output: WREG = 1 if in check, 0 if not
;         in_check flag updated
; ============================================================================
is_in_check:
    ; Get current king position
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     check_black_king

    ; White's turn - check white king
    MOVF    white_king_sq, W
    MOVWF   attack_square

    ; Check if attacked by black
    MOVLW   BLACK
    MOVWF   attack_color
    GOTO    check_is_attacked

check_black_king:
    MOVF    black_king_sq, W
    MOVWF   attack_square

    ; Check if attacked by white
    MOVLW   WHITE
    MOVWF   attack_color

check_is_attacked:
    CALL    is_square_attacked

    ; Update in_check flag
    MOVWF   in_check

    RETURN

; ============================================================================
; is_square_attacked - Check if square is attacked by given color
;
; Input:  attack_square = square to check
;         attack_color = color of attacking side (0x00 or 0x08)
; Output: WREG = 1 if attacked, 0 if not
; ============================================================================
is_square_attacked:
    ; Check for attacks from each piece type

    ; Check for pawn attacks
    CALL    check_pawn_attack
    MOVF    attack_found, F
    BNZ     attack_detected

    ; Check for knight attacks
    CALL    check_knight_attack
    MOVF    attack_found, F
    BNZ     attack_detected

    ; Check for bishop/queen diagonal attacks
    CALL    check_diagonal_attack
    MOVF    attack_found, F
    BNZ     attack_detected

    ; Check for rook/queen orthogonal attacks
    CALL    check_orthogonal_attack
    MOVF    attack_found, F
    BNZ     attack_detected

    ; Check for king attacks
    CALL    check_king_attack
    MOVF    attack_found, F
    BNZ     attack_detected

    ; No attack found
    CLRF    attack_found
    CLRF    WREG
    RETURN

attack_detected:
    MOVLW   0x01
    MOVWF   attack_found
    RETURN

; ============================================================================
; check_pawn_attack - Check if square is attacked by enemy pawn
; ============================================================================
check_pawn_attack:
    CLRF    attack_found

    ; Pawns attack diagonally
    ; White pawns attack up-left and up-right (from their perspective)
    ; Black pawns attack down-left and down-right

    MOVF    attack_color, W
    ANDLW   COLOR_MASK
    BNZ     check_black_pawn_attack

check_white_pawn_attack:
    ; White pawns attack from SW and SE (relative to target square)
    ; Check SW
    MOVF    attack_square, W
    ANDLW   0x07                ; Get file
    BZ      check_white_pawn_se ; File A, skip SW

    MOVF    attack_square, W
    ADDLW   DIR_SW
    CALL    board_get_piece
    SUBLW   W_PAWN
    BZ      check_pawn_found

check_white_pawn_se:
    ; Check SE
    MOVF    attack_square, W
    ANDLW   0x07
    SUBLW   7
    BZ      check_pawn_done     ; File H, skip SE

    MOVF    attack_square, W
    ADDLW   DIR_SE
    CALL    board_get_piece
    SUBLW   W_PAWN
    BZ      check_pawn_found

    GOTO    check_pawn_done

check_black_pawn_attack:
    ; Black pawns attack from NW and NE
    MOVF    attack_square, W
    ANDLW   0x07
    BZ      check_black_pawn_ne

    MOVF    attack_square, W
    ADDLW   DIR_NW
    CALL    board_get_piece
    SUBLW   B_PAWN
    BZ      check_pawn_found

check_black_pawn_ne:
    MOVF    attack_square, W
    ANDLW   0x07
    SUBLW   7
    BZ      check_pawn_done

    MOVF    attack_square, W
    ADDLW   DIR_NE
    CALL    board_get_piece
    SUBLW   B_PAWN
    BZ      check_pawn_found

    GOTO    check_pawn_done

check_pawn_found:
    MOVLW   0x01
    MOVWF   attack_found

check_pawn_done:
    RETURN

; ============================================================================
; check_knight_attack - Check if square is attacked by enemy knight
; ============================================================================
check_knight_attack:
    CLRF    attack_found

    ; Create expected knight piece code
    MOVF    attack_color, W
    IORLW   KNIGHT
    MOVWF   temp1               ; temp1 = expected knight

    ; Check all 8 knight move offsets
    ; (Simplified - checking only valid squares)
    MOVF    attack_square, W
    ADDLW   17                  ; +2 ranks, +1 file
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   15                  ; +2 ranks, -1 file
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   10                  ; +1 rank, +2 files
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   6                   ; +1 rank, -2 files
    CALL    check_piece_at_square

    ; (Additional offsets for down movements would go here)

    RETURN

; ============================================================================
; check_diagonal_attack - Check for bishop or queen on diagonals
; ============================================================================
check_diagonal_attack:
    CLRF    attack_found

    ; Create expected piece codes
    MOVF    attack_color, W
    IORLW   BISHOP
    MOVWF   temp1               ; temp1 = bishop

    MOVF    attack_color, W
    IORLW   QUEEN
    MOVWF   temp2               ; temp2 = queen

    ; Check all four diagonal directions
    MOVLW   DIR_NE
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_NW
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_SE
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_SW
    MOVWF   temp3
    CALL    check_sliding_attack

    RETURN

; ============================================================================
; check_orthogonal_attack - Check for rook or queen on ranks/files
; ============================================================================
check_orthogonal_attack:
    CLRF    attack_found

    ; Create expected piece codes
    MOVF    attack_color, W
    IORLW   ROOK
    MOVWF   temp1               ; temp1 = rook

    MOVF    attack_color, W
    IORLW   QUEEN
    MOVWF   temp2               ; temp2 = queen

    ; Check all four orthogonal directions
    MOVLW   DIR_N
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_S
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_E
    MOVWF   temp3
    CALL    check_sliding_attack

    MOVLW   DIR_W
    MOVWF   temp3
    CALL    check_sliding_attack

    RETURN

; ============================================================================
; check_king_attack - Check if square is attacked by enemy king
; ============================================================================
check_king_attack:
    CLRF    attack_found

    ; Create expected king piece code
    MOVF    attack_color, W
    IORLW   KING
    MOVWF   temp1

    ; Check all 8 adjacent squares
    MOVF    attack_square, W
    ADDLW   DIR_N
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_S
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_E
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_W
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_NE
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_NW
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_SE
    CALL    check_piece_at_square

    MOVF    attack_square, W
    ADDLW   DIR_SW
    CALL    check_piece_at_square

    RETURN

; ============================================================================
; check_sliding_attack - Check for sliding piece in given direction
;
; Input:  temp1 = first piece type (e.g., bishop)
;         temp2 = second piece type (e.g., queen)
;         temp3 = direction offset
; ============================================================================
check_sliding_attack:
    MOVF    attack_square, W
    MOVWF   temp4               ; temp4 = current square

check_slide_loop:
    ; Move in direction
    MOVF    temp3, W
    ADDWF   temp4, F

    ; Check bounds
    MOVF    temp4, W
    CALL    movegen_is_valid_sq
    BZ      check_slide_done

    ; Get piece at square
    MOVF    temp4, W
    CALL    board_get_piece
    MOVWF   temp5

    ; Check if empty
    ANDLW   PIECE_MASK
    BZ      check_slide_loop    ; Empty, continue

    ; Found a piece - check if it's attacking
    MOVF    temp5, W
    SUBWF   temp1, W
    BZ      check_slide_found   ; Match first piece type

    MOVF    temp5, W
    SUBWF   temp2, W
    BZ      check_slide_found   ; Match second piece type

    ; Different piece, stop searching
    GOTO    check_slide_done

check_slide_found:
    MOVLW   0x01
    MOVWF   attack_found

check_slide_done:
    RETURN

; ============================================================================
; check_piece_at_square - Check if specific piece is at square
;
; Input:  WREG = square to check
;         temp1 = expected piece
; ============================================================================
check_piece_at_square:
    ; Validate square first
    CALL    movegen_is_valid_sq
    BZ      check_piece_done

    ; Get piece
    CALL    board_get_piece
    SUBWF   temp1, W
    BNZ     check_piece_done

    ; Found it!
    MOVLW   0x01
    MOVWF   attack_found

check_piece_done:
    RETURN

; ============================================================================
; is_checkmate - Check if current position is checkmate
;
; Output: WREG = 1 if checkmate, 0 if not
; ============================================================================
is_checkmate:
    ; First, must be in check
    CALL    is_in_check
    MOVWF   temp1
    BZ      not_checkmate       ; Not in check

    ; Check if any legal moves exist
    CALL    has_legal_moves
    BZ      is_checkmate_yes    ; No legal moves = checkmate

not_checkmate:
    CLRF    WREG
    RETURN

is_checkmate_yes:
    MOVLW   0x01
    RETURN

; ============================================================================
; is_stalemate - Check if current position is stalemate
;
; Output: WREG = 1 if stalemate, 0 if not
; ============================================================================
is_stalemate:
    ; Must NOT be in check
    CALL    is_in_check
    BNZ     not_stalemate       ; In check, not stalemate

    ; Check if any legal moves exist
    CALL    has_legal_moves
    BNZ     not_stalemate       ; Has legal moves, not stalemate

    ; No legal moves and not in check = stalemate
    MOVLW   0x01
    RETURN

not_stalemate:
    CLRF    WREG
    RETURN

; ============================================================================
; has_legal_moves - Check if current side has any legal moves
;
; Output: WREG = number of legal moves (0 if none)
; ============================================================================
has_legal_moves:
    ; Generate all pseudo-legal moves
    CALL    movegen_all

    ; Check if any are legal (don't leave king in check)
    CLRF    legal_move_count
    CLRF    move_index

has_legal_loop:
    ; Check if we've examined all moves
    MOVF    move_index, W
    SUBWF   move_count, W
    BZ      has_legal_done      ; No more moves

    ; Get move from list
    MOVF    move_index, W
    RLNCF   WREG, F             ; * 2
    RLNCF   WREG, F             ; * 4
    ADDLW   LOW move_list
    MOVWF   FSR0L
    MOVLW   HIGH move_list
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Load move
    MOVF    POSTINC0, W
    MOVWF   curr_from
    MOVF    POSTINC0, W
    MOVWF   curr_to
    MOVF    POSTINC0, W
    MOVWF   curr_flags

    ; Check if legal
    CALL    is_legal_move
    BZ      has_legal_next      ; Illegal, skip

    ; Legal move found
    INCF    legal_move_count, F

has_legal_next:
    INCF    move_index, F
    GOTO    has_legal_loop

has_legal_done:
    MOVF    legal_move_count, W
    RETURN

; ============================================================================
; End of check.asm
; ============================================================================
