; ============================================================================
; makemove.asm - Make and Unmake Move Operations
; Chess Engine Project
; ============================================================================
; This module handles making and unmaking moves on the board.
; Critical for both game play and AI search.
;
; Functions:
;   - make_move:        Execute a move on the board
;   - unmake_move:      Undo a move
;   - is_legal_move:    Check if move is legal (doesn't leave king in check)
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; make_move - Execute a move on the board
;
; Input:  curr_from = from square
;         curr_to = to square
;         curr_flags = move flags
; Output: Board updated, game state updated
; Modifies: Many registers
; ============================================================================
make_move:
    ; Save current move to last_move for undo and display
    MOVF    curr_from, W
    MOVWF   last_from
    MOVF    curr_to, W
    MOVWF   last_to
    MOVF    curr_flags, W
    MOVWF   last_flags

    ; Get the moving piece
    MOVF    curr_from, W
    CALL    board_get_piece
    MOVWF   temp1               ; temp1 = moving piece

    ; Handle captures (save captured piece)
    BTFSC   curr_flags, 7       ; Test capture bit
    GOTO    make_move_capture

    CLRF    last_capture
    GOTO    make_move_normal

make_move_capture:
    ; Check for en passant (special case)
    BTFSC   curr_flags, 4       ; Test en passant bit
    GOTO    make_move_enpassant

    ; Normal capture
    MOVF    curr_to, W
    CALL    board_get_piece
    MOVWF   last_capture
    GOTO    make_move_normal

make_move_enpassant:
    ; En passant capture - captured pawn is NOT on target square
    ; Determine captured pawn square based on side to move
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     make_move_ep_black

    ; White capturing black pawn
    MOVF    curr_to, W
    ADDLW   DIR_S               ; Black pawn is one rank below
    CALL    board_get_piece
    MOVWF   last_capture

    ; Clear the captured pawn square
    MOVF    curr_to, W
    ADDLW   DIR_S
    CALL    board_clear_sq
    GOTO    make_move_normal

make_move_ep_black:
    ; Black capturing white pawn
    MOVF    curr_to, W
    ADDLW   DIR_N               ; White pawn is one rank above
    CALL    board_get_piece
    MOVWF   last_capture

    ; Clear the captured pawn square
    MOVF    curr_to, W
    ADDLW   DIR_N
    CALL    board_clear_sq

make_move_normal:
    ; Clear the from square
    MOVF    curr_from, W
    CALL    board_clear_sq

    ; Handle promotion
    BTFSC   curr_flags, 6       ; Test promotion bit
    GOTO    make_move_promotion

    ; Normal move - place piece on to square
    MOVF    curr_to, W
    MOVWF   curr_square
    MOVF    temp1, W
    MOVWF   curr_piece
    CALL    board_set_piece
    GOTO    make_move_special

make_move_promotion:
    ; Determine promoted piece
    MOVF    curr_flags, W
    ANDLW   0x0C                ; Get promotion bits
    MOVWF   temp2

    ; Get piece color
    MOVF    temp1, W
    ANDLW   COLOR_MASK
    MOVWF   temp3

    ; Create promoted piece
    MOVF    temp2, W
    RRNCF   WREG, F
    RRNCF   WREG, F             ; Shift right by 2
    ADDLW   QUEEN               ; Add base (PROMO_QUEEN=0 -> QUEEN)
    IORWF   temp3, W            ; Combine with color

    ; Place promoted piece
    MOVWF   curr_piece
    MOVF    curr_to, W
    MOVWF   curr_square
    CALL    board_set_piece

make_move_special:
    ; Handle castling
    BTFSC   curr_flags, 5       ; Test castling bit
    GOTO    make_move_castle

    ; Update en passant square
    ; Clear old en passant
    MOVLW   NO_SQUARE
    MOVWF   enpassant_square

    ; Check if pawn double push (creates en passant opportunity)
    MOVF    temp1, W
    ANDLW   PIECE_MASK
    SUBLW   PAWN
    BNZ     make_move_update_state ; Not a pawn

    ; Check if double push
    MOVF    curr_from, W
    SUBWF   curr_to, W          ; to - from
    MOVWF   temp2

    ; White pawn double push = +16
    MOVF    temp2, W
    SUBLW   16
    BZ      make_move_white_double

    ; Black pawn double push = -16
    MOVF    temp2, W
    ADDLW   16
    BZ      make_move_black_double

    GOTO    make_move_update_state

make_move_white_double:
    ; Set en passant square (between from and to)
    MOVF    curr_from, W
    ADDLW   DIR_N
    MOVWF   enpassant_square
    GOTO    make_move_update_state

make_move_black_double:
    MOVF    curr_from, W
    ADDLW   DIR_S
    MOVWF   enpassant_square
    GOTO    make_move_update_state

make_move_castle:
    ; Move the rook as well
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     make_move_castle_black

    ; White castling
    MOVF    curr_to, W
    SUBLW   G1
    BZ      make_move_white_kingside

    ; White queenside
    MOVLW   A1
    CALL    board_get_piece     ; Get rook
    MOVWF   temp2
    MOVLW   A1
    CALL    board_clear_sq      ; Clear rook square
    MOVLW   D1
    MOVWF   curr_square
    MOVF    temp2, W
    MOVWF   curr_piece
    CALL    board_set_piece     ; Place rook on d1
    GOTO    make_move_update_state

make_move_white_kingside:
    MOVLW   H1
    CALL    board_get_piece
    MOVWF   temp2
    MOVLW   H1
    CALL    board_clear_sq
    MOVLW   F1
    MOVWF   curr_square
    MOVF    temp2, W
    MOVWF   curr_piece
    CALL    board_set_piece
    GOTO    make_move_update_state

make_move_castle_black:
    ; Black castling
    MOVF    curr_to, W
    SUBLW   G8
    BZ      make_move_black_kingside

    ; Black queenside
    MOVLW   A8
    CALL    board_get_piece
    MOVWF   temp2
    MOVLW   A8
    CALL    board_clear_sq
    MOVLW   D8
    MOVWF   curr_square
    MOVF    temp2, W
    MOVWF   curr_piece
    CALL    board_set_piece
    GOTO    make_move_update_state

make_move_black_kingside:
    MOVLW   H8
    CALL    board_get_piece
    MOVWF   temp2
    MOVLW   H8
    CALL    board_clear_sq
    MOVLW   F8
    MOVWF   curr_square
    MOVF    temp2, W
    MOVWF   curr_piece
    CALL    board_set_piece

make_move_update_state:
    ; Update castling rights
    CALL    update_castling_rights

    ; Update halfmove clock (50-move rule)
    BTFSC   curr_flags, 7       ; Capture?
    GOTO    make_move_reset_halfmove

    MOVF    temp1, W
    ANDLW   PIECE_MASK
    SUBLW   PAWN
    BZ      make_move_reset_halfmove ; Pawn move?

    ; Increment halfmove clock
    INCF    halfmove_clock, F
    GOTO    make_move_update_fullmove

make_move_reset_halfmove:
    CLRF    halfmove_clock

make_move_update_fullmove:
    ; Increment fullmove number if black just moved
    MOVF    game_turn, W
    ANDLW   0x01
    BZ      make_move_switch_turn ; White's turn, don't increment

    ; Increment fullmove
    INCF    fullmove_lo, F
    BTFSC   STATUS, Z
    INCF    fullmove_hi, F

make_move_switch_turn:
    ; Switch turn
    MOVLW   0x01
    XORWF   game_turn, F        ; Toggle turn

    RETURN

; ============================================================================
; unmake_move - Undo the last move
;
; Input:  last_from, last_to, last_flags, last_capture
; Output: Board restored to previous state
; ============================================================================
unmake_move:
    ; This is a simplified undo - full implementation would save
    ; all game state (castling rights, en passant, etc.)
    ; For AI search, we'd push/pop this state

    ; Get piece from destination
    MOVF    last_to, W
    CALL    board_get_piece
    MOVWF   temp1

    ; Handle promotion (convert back to pawn)
    BTFSC   last_flags, 6       ; Promotion?
    GOTO    unmake_promo

unmake_normal:
    ; Move piece back
    MOVF    last_from, W
    MOVWF   curr_square
    MOVF    temp1, W
    MOVWF   curr_piece
    CALL    board_set_piece

    ; Clear destination
    MOVF    last_to, W
    CALL    board_clear_sq

    ; Restore captured piece
    BTFSC   last_flags, 7       ; Capture?
    GOTO    unmake_capture

    GOTO    unmake_done

unmake_promo:
    ; Convert promoted piece back to pawn
    MOVF    temp1, W
    ANDLW   COLOR_MASK          ; Keep color
    IORLW   PAWN                ; Make it a pawn
    MOVWF   curr_piece

    MOVF    last_from, W
    MOVWF   curr_square
    CALL    board_set_piece

    MOVF    last_to, W
    CALL    board_clear_sq

unmake_capture:
    ; Check for en passant
    BTFSC   last_flags, 4
    GOTO    unmake_ep

    ; Normal capture - restore piece
    MOVF    last_to, W
    MOVWF   curr_square
    MOVF    last_capture, W
    MOVWF   curr_piece
    CALL    board_set_piece
    GOTO    unmake_castle

unmake_ep:
    ; Restore captured pawn to correct square
    MOVF    game_turn, W        ; Note: turn already switched
    ANDLW   0x01
    BZ      unmake_ep_was_black ; Was black's turn (now white)

    ; Was white's turn, restore white pawn
    MOVF    last_to, W
    ADDLW   DIR_N
    MOVWF   curr_square
    MOVF    last_capture, W
    MOVWF   curr_piece
    CALL    board_set_piece
    GOTO    unmake_castle

unmake_ep_was_black:
    MOVF    last_to, W
    ADDLW   DIR_S
    MOVWF   curr_square
    MOVF    last_capture, W
    MOVWF   curr_piece
    CALL    board_set_piece

unmake_castle:
    ; Unmove rook if castling
    BTFSS   last_flags, 5
    GOTO    unmake_restore_state

    ; Determine which castling and unmove rook
    ; (Implementation details omitted for brevity)

unmake_restore_state:
    ; Switch turn back
    MOVLW   0x01
    XORWF   game_turn, F

    ; Note: Full implementation should restore:
    ; - castling_rights
    ; - enpassant_square
    ; - halfmove_clock
    ; - fullmove_number
    ; These would be pushed onto a stack before make_move

unmake_done:
    RETURN

; ============================================================================
; update_castling_rights - Update castling rights based on move
;
; Input:  curr_from, curr_to, moving piece
; Output: castle_rights updated
; ============================================================================
update_castling_rights:
    ; If king moves, lose all castling rights for that side
    MOVF    temp1, W
    ANDLW   PIECE_MASK
    SUBLW   KING
    BNZ     update_castle_rook

    ; King moved
    MOVF    temp1, W
    ANDLW   COLOR_MASK
    BNZ     update_castle_black_king

    ; White king moved - clear white castling
    MOVLW   ~(CASTLE_WK | CASTLE_WQ)
    ANDWF   castle_rights, F
    RETURN

update_castle_black_king:
    ; Black king moved
    MOVLW   ~(CASTLE_BK | CASTLE_BQ)
    ANDWF   castle_rights, F
    RETURN

update_castle_rook:
    ; Check if rook moved from starting square
    MOVF    curr_from, W
    SUBLW   A1
    BZ      update_castle_wq_rook

    MOVF    curr_from, W
    SUBLW   H1
    BZ      update_castle_wk_rook

    MOVF    curr_from, W
    SUBLW   A8
    BZ      update_castle_bq_rook

    MOVF    curr_from, W
    SUBLW   H8
    BZ      update_castle_bk_rook

    RETURN

update_castle_wq_rook:
    MOVLW   ~CASTLE_WQ
    ANDWF   castle_rights, F
    RETURN

update_castle_wk_rook:
    MOVLW   ~CASTLE_WK
    ANDWF   castle_rights, F
    RETURN

update_castle_bq_rook:
    MOVLW   ~CASTLE_BQ
    ANDWF   castle_rights, F
    RETURN

update_castle_bk_rook:
    MOVLW   ~CASTLE_BK
    ANDWF   castle_rights, F
    RETURN

; ============================================================================
; is_legal_move - Check if move is legal (doesn't leave king in check)
;
; Input:  curr_from, curr_to, curr_flags
; Output: WREG = 1 if legal, 0 if illegal
; ============================================================================
is_legal_move:
    ; Make the move
    CALL    make_move

    ; Check if our king is in check
    ; (This requires is_in_check function from check.asm)
    CALL    is_in_check

    ; Save result
    MOVWF   temp1

    ; Unmake the move
    CALL    unmake_move

    ; Return result (inverted - if in check, move is illegal)
    MOVF    temp1, W
    SUBLW   0x01                ; 1 - result
    RETURN

; ============================================================================
; End of makemove.asm
; ============================================================================
