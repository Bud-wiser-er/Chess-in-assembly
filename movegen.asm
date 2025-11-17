; ============================================================================
; movegen.asm - Move Generation Engine
; Chess Engine Project
; ============================================================================
; This module generates all pseudo-legal moves for the current position.
; Pseudo-legal means the move follows piece movement rules but may leave
; the king in check (which will be filtered later).
;
; Functions:
;   - movegen_all:          Generate all moves for current side
;   - movegen_pawn:         Generate pawn moves
;   - movegen_knight:       Generate knight moves
;   - movegen_bishop:       Generate bishop moves (diagonal)
;   - movegen_rook:         Generate rook moves (orthogonal)
;   - movegen_queen:        Generate queen moves (diagonal + orthogonal)
;   - movegen_king:         Generate king moves
;   - movegen_add_move:     Add move to move list
;   - movegen_is_valid_sq:  Check if square is valid (0-63)
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; movegen_all - Generate all pseudo-legal moves for current player
;
; Input:  game_turn = current player (0=White, 1=Black)
; Output: move_count = number of moves generated
;         move_list = populated with moves
; Modifies: Many registers
; ============================================================================
movegen_all:
    ; Clear move list
    CLRF    move_count

    ; Set up FSR0 to point to move list
    MOVLW   LOW move_list
    MOVWF   FSR0L
    MOVLW   HIGH move_list
    MOVWF   FSR0H

    ; Iterate through all squares on the board
    CLRF    movegen_square      ; Start at square 0

movegen_all_loop:
    ; Get piece at current square
    MOVF    movegen_square, W
    CALL    board_get_piece
    MOVWF   movegen_piece

    ; Check if square is empty
    ANDLW   PIECE_MASK
    BZ      movegen_all_next    ; Empty square, skip

    ; Check if piece belongs to current player
    MOVF    movegen_piece, W
    ANDLW   COLOR_MASK          ; Get color
    MOVWF   temp1

    MOVF    game_turn, W        ; Get current turn
    ANDLW   0x01
    RLNCF   WREG, F
    RLNCF   WREG, F
    RLNCF   WREG, F             ; Convert 0/1 to 0x00/0x08

    SUBWF   temp1, W            ; Compare colors
    BNZ     movegen_all_next    ; Not our piece, skip

    ; Generate moves based on piece type
    MOVF    movegen_piece, W
    ANDLW   PIECE_MASK
    MOVWF   temp2               ; temp2 = piece type

    ; Jump based on piece type
    DECF    temp2, W            ; Adjust for jump table (1->0, 2->1, etc.)
    ADDWF   PCL, F

    GOTO    movegen_all_pawn    ; 1 = Pawn
    GOTO    movegen_all_knight  ; 2 = Knight
    GOTO    movegen_all_bishop  ; 3 = Bishop
    GOTO    movegen_all_rook    ; 4 = Rook
    GOTO    movegen_all_queen   ; 5 = Queen
    GOTO    movegen_all_king    ; 6 = King

movegen_all_pawn:
    CALL    movegen_pawn
    GOTO    movegen_all_next

movegen_all_knight:
    CALL    movegen_knight
    GOTO    movegen_all_next

movegen_all_bishop:
    CALL    movegen_bishop
    GOTO    movegen_all_next

movegen_all_rook:
    CALL    movegen_rook
    GOTO    movegen_all_next

movegen_all_queen:
    CALL    movegen_queen
    GOTO    movegen_all_next

movegen_all_king:
    CALL    movegen_king
    GOTO    movegen_all_next

movegen_all_next:
    INCF    movegen_square, F
    MOVLW   BOARD_SIZE
    SUBWF   movegen_square, W
    BNZ     movegen_all_loop    ; Continue if not done

    RETURN

; ============================================================================
; movegen_pawn - Generate pawn moves from current square
;
; Input:  movegen_square = square of pawn
;         movegen_piece = pawn piece code
; Output: Moves added to move list
; Modifies: temp1-temp6
; ============================================================================
movegen_pawn:
    ; Determine pawn direction based on color
    MOVF    movegen_piece, W
    ANDLW   COLOR_MASK
    BNZ     movegen_pawn_black

movegen_pawn_white:
    ; White pawn moves up (increasing square numbers)
    MOVLW   DIR_N               ; Direction = +8
    MOVWF   temp1               ; temp1 = forward direction

    ; Check for single push (one square forward)
    MOVF    movegen_square, W
    ADDLW   DIR_N
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_white_captures ; Invalid square

    ; Check if target square is empty
    CALL    board_get_piece
    ANDLW   PIECE_MASK
    BNZ     movegen_pawn_white_captures ; Blocked

    ; Add single push move
    MOVF    movegen_square, W
    ADDLW   DIR_N
    MOVWF   curr_to

    ; Check for promotion (rank 8)
    MOVF    curr_to, W
    ANDLW   0x38                ; Get rank bits
    SUBLW   0x38                ; Rank 8?
    BZ      movegen_pawn_white_promo

    ; Normal push
    CLRF    curr_flags
    CALL    movegen_add_move

    ; Check for double push (from rank 2)
    MOVF    movegen_square, W
    ANDLW   0x38                ; Get rank
    SUBLW   0x08                ; Rank 2?
    BNZ     movegen_pawn_white_captures

    ; Try double push
    MOVF    movegen_square, W
    ADDLW   DIR_N + DIR_N       ; Two squares forward
    CALL    board_get_piece
    ANDLW   PIECE_MASK
    BNZ     movegen_pawn_white_captures ; Blocked

    ; Add double push move
    MOVF    movegen_square, W
    ADDLW   DIR_N + DIR_N
    MOVWF   curr_to
    CLRF    curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_white_captures

movegen_pawn_white_promo:
    ; Add all promotion moves
    MOVLW   MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_white_captures:
    ; Left capture (northwest)
    MOVF    movegen_square, W
    ANDLW   0x07                ; Get file
    BZ      movegen_pawn_white_right_cap ; File A, can't capture left

    MOVF    movegen_square, W
    ADDLW   DIR_NW
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_white_right_cap

    ; Check if target has enemy piece
    CALL    board_get_piece
    MOVWF   temp2
    ANDLW   PIECE_MASK
    BZ      movegen_pawn_white_ep_left   ; Empty, check en passant

    ; Check if enemy
    MOVF    temp2, W
    ANDLW   COLOR_MASK
    BNZ     movegen_pawn_white_add_cap_left ; Black piece, can capture

    GOTO    movegen_pawn_white_ep_left

movegen_pawn_white_add_cap_left:
    MOVF    movegen_square, W
    ADDLW   DIR_NW
    MOVWF   curr_to

    ; Check for promotion
    MOVF    curr_to, W
    ANDLW   0x38
    SUBLW   0x38                ; Rank 8?
    BZ      movegen_pawn_white_cap_promo_left

    ; Normal capture
    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_white_ep_left

movegen_pawn_white_cap_promo_left:
    ; Capture with promotion
    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_white_ep_left:
    ; Check en passant left
    MOVF    enpassant_square, W
    SUBLW   NO_SQUARE
    BZ      movegen_pawn_white_right_cap ; No en passant

    MOVF    movegen_square, W
    ADDLW   DIR_NW
    SUBWF   enpassant_square, W
    BNZ     movegen_pawn_white_right_cap ; Not the en passant square

    ; Add en passant move
    MOVF    enpassant_square, W
    MOVWF   curr_to
    MOVLW   MOVE_CAPTURE | MOVE_ENPASSANT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_white_right_cap:
    ; Right capture (northeast) - similar to left
    MOVF    movegen_square, W
    ANDLW   0x07
    SUBLW   0x07                ; File H?
    BZ      movegen_pawn_done   ; Can't capture right

    MOVF    movegen_square, W
    ADDLW   DIR_NE
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_done

    CALL    board_get_piece
    MOVWF   temp2
    ANDLW   PIECE_MASK
    BZ      movegen_pawn_white_ep_right

    MOVF    temp2, W
    ANDLW   COLOR_MASK
    BNZ     movegen_pawn_white_add_cap_right

    GOTO    movegen_pawn_white_ep_right

movegen_pawn_white_add_cap_right:
    MOVF    movegen_square, W
    ADDLW   DIR_NE
    MOVWF   curr_to

    MOVF    curr_to, W
    ANDLW   0x38
    SUBLW   0x38
    BZ      movegen_pawn_white_cap_promo_right

    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_white_ep_right

movegen_pawn_white_cap_promo_right:
    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_white_ep_right:
    MOVF    enpassant_square, W
    SUBLW   NO_SQUARE
    BZ      movegen_pawn_done

    MOVF    movegen_square, W
    ADDLW   DIR_NE
    SUBWF   enpassant_square, W
    BNZ     movegen_pawn_done

    MOVF    enpassant_square, W
    MOVWF   curr_to
    MOVLW   MOVE_CAPTURE | MOVE_ENPASSANT
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_done

movegen_pawn_black:
    ; Black pawn (similar logic but moving down)
    ; Single push
    MOVF    movegen_square, W
    ADDLW   DIR_S               ; -8
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_black_captures

    CALL    board_get_piece
    ANDLW   PIECE_MASK
    BNZ     movegen_pawn_black_captures

    MOVF    movegen_square, W
    ADDLW   DIR_S
    MOVWF   curr_to

    ; Check for promotion (rank 1)
    MOVF    curr_to, W
    ANDLW   0x38
    BZ      movegen_pawn_black_promo

    CLRF    curr_flags
    CALL    movegen_add_move

    ; Check for double push (from rank 7)
    MOVF    movegen_square, W
    ANDLW   0x38
    SUBLW   0x30                ; Rank 7?
    BNZ     movegen_pawn_black_captures

    MOVF    movegen_square, W
    ADDLW   DIR_S + DIR_S
    CALL    board_get_piece
    ANDLW   PIECE_MASK
    BNZ     movegen_pawn_black_captures

    MOVF    movegen_square, W
    ADDLW   DIR_S + DIR_S
    MOVWF   curr_to
    CLRF    curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_black_captures

movegen_pawn_black_promo:
    MOVLW   MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_black_captures:
    ; Left capture (southwest)
    MOVF    movegen_square, W
    ANDLW   0x07
    BZ      movegen_pawn_black_right_cap

    MOVF    movegen_square, W
    ADDLW   DIR_SW
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_black_right_cap

    CALL    board_get_piece
    MOVWF   temp2
    ANDLW   PIECE_MASK
    BZ      movegen_pawn_black_ep_left

    MOVF    temp2, W
    ANDLW   COLOR_MASK
    BZ      movegen_pawn_black_add_cap_left ; White piece

    GOTO    movegen_pawn_black_ep_left

movegen_pawn_black_add_cap_left:
    MOVF    movegen_square, W
    ADDLW   DIR_SW
    MOVWF   curr_to

    MOVF    curr_to, W
    ANDLW   0x38
    BZ      movegen_pawn_black_cap_promo_left

    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_black_ep_left

movegen_pawn_black_cap_promo_left:
    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_black_ep_left:
    MOVF    enpassant_square, W
    SUBLW   NO_SQUARE
    BZ      movegen_pawn_black_right_cap

    MOVF    movegen_square, W
    ADDLW   DIR_SW
    SUBWF   enpassant_square, W
    BNZ     movegen_pawn_black_right_cap

    MOVF    enpassant_square, W
    MOVWF   curr_to
    MOVLW   MOVE_CAPTURE | MOVE_ENPASSANT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_black_right_cap:
    MOVF    movegen_square, W
    ANDLW   0x07
    SUBLW   0x07
    BZ      movegen_pawn_done

    MOVF    movegen_square, W
    ADDLW   DIR_SE
    CALL    movegen_is_valid_sq
    BZ      movegen_pawn_done

    CALL    board_get_piece
    MOVWF   temp2
    ANDLW   PIECE_MASK
    BZ      movegen_pawn_black_ep_right

    MOVF    temp2, W
    ANDLW   COLOR_MASK
    BZ      movegen_pawn_black_add_cap_right

    GOTO    movegen_pawn_black_ep_right

movegen_pawn_black_add_cap_right:
    MOVF    movegen_square, W
    ADDLW   DIR_SE
    MOVWF   curr_to

    MOVF    curr_to, W
    ANDLW   0x38
    BZ      movegen_pawn_black_cap_promo_right

    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_pawn_black_ep_right

movegen_pawn_black_cap_promo_right:
    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    CALL    movegen_add_move

    MOVLW   MOVE_CAPTURE | MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_black_ep_right:
    MOVF    enpassant_square, W
    SUBLW   NO_SQUARE
    BZ      movegen_pawn_done

    MOVF    movegen_square, W
    ADDLW   DIR_SE
    SUBWF   enpassant_square, W
    BNZ     movegen_pawn_done

    MOVF    enpassant_square, W
    MOVWF   curr_to
    MOVLW   MOVE_CAPTURE | MOVE_ENPASSANT
    MOVWF   curr_flags
    CALL    movegen_add_move

movegen_pawn_done:
    RETURN

; ============================================================================
; movegen_knight - Generate knight moves
;
; Input:  movegen_square = square of knight
;         movegen_piece = knight piece code
; Output: Moves added to move list
; ============================================================================
movegen_knight:
    ; Knight has 8 possible moves in L-shape
    ; We'll check each direction manually due to board boundaries

    ; Get knight's file and rank for boundary checking
    MOVF    movegen_square, W
    ANDLW   0x07
    MOVWF   temp1               ; temp1 = file (0-7)

    MOVF    movegen_square, W
    SWAPF   WREG, W
    ANDLW   0x0F
    RRNCF   WREG, W
    MOVWF   temp2               ; temp2 = rank (0-7)

    ; Move 1: +2 ranks, +1 file (up-up-right)
    MOVF    temp2, W
    ADDLW   2
    SUBLW   7
    BNC     movegen_knight_2    ; Rank out of bounds

    MOVF    temp1, W
    ADDLW   1
    SUBLW   7
    BNC     movegen_knight_2    ; File out of bounds

    ; Valid square, check if we can move there
    MOVF    movegen_square, W
    ADDLW   17                  ; +2 ranks (+16) +1 file
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_2:
    ; Move 2: +2 ranks, -1 file (up-up-left)
    MOVF    temp2, W
    ADDLW   2
    SUBLW   7
    BNC     movegen_knight_3

    MOVF    temp1, W
    SUBLW   0
    BZ      movegen_knight_3    ; File A, can't go left

    MOVF    movegen_square, W
    ADDLW   15                  ; +2 ranks (+16) -1 file
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_3:
    ; Move 3: +1 rank, +2 files (up-right-right)
    MOVF    temp2, W
    ADDLW   1
    SUBLW   7
    BNC     movegen_knight_4

    MOVF    temp1, W
    ADDLW   2
    SUBLW   7
    BNC     movegen_knight_4

    MOVF    movegen_square, W
    ADDLW   10                  ; +1 rank (+8) +2 files
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_4:
    ; Move 4: +1 rank, -2 files (up-left-left)
    MOVF    temp2, W
    ADDLW   1
    SUBLW   7
    BNC     movegen_knight_5

    MOVF    temp1, W
    SUBLW   1
    BNC     movegen_knight_5    ; File 0 or 1, can't go 2 left

    MOVF    movegen_square, W
    ADDLW   6                   ; +1 rank (+8) -2 files
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_5:
    ; Move 5: -1 rank, +2 files (down-right-right)
    MOVF    temp2, W
    SUBLW   0
    BZ      movegen_knight_6    ; Rank 0, can't go down

    MOVF    temp1, W
    ADDLW   2
    SUBLW   7
    BNC     movegen_knight_6

    MOVF    movegen_square, W
    SUBLW   0xF8                ; -1 rank (-8) +2 files
    NEGF    WREG
    ADDLW   2
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_6:
    ; Move 6: -1 rank, -2 files (down-left-left)
    MOVF    temp2, W
    SUBLW   0
    BZ      movegen_knight_7

    MOVF    temp1, W
    SUBLW   1
    BNC     movegen_knight_7

    MOVF    movegen_square, W
    SUBLW   0xF4                ; -1 rank (-8) -2 files (-10)
    NEGF    WREG
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_7:
    ; Move 7: -2 ranks, +1 file (down-down-right)
    MOVF    temp2, W
    SUBLW   1
    BNC     movegen_knight_8    ; Rank 0 or 1, can't go 2 down

    MOVF    temp1, W
    ADDLW   1
    SUBLW   7
    BNC     movegen_knight_8

    MOVF    movegen_square, W
    SUBLW   0xEF                ; -2 ranks (-16) +1 file (-15)
    NEGF    WREG
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_8:
    ; Move 8: -2 ranks, -1 file (down-down-left)
    MOVF    temp2, W
    SUBLW   1
    BNC     movegen_knight_done

    MOVF    temp1, W
    SUBLW   0
    BZ      movegen_knight_done

    MOVF    movegen_square, W
    SUBLW   0xF1                ; -2 ranks (-16) -1 file (-17)
    NEGF    WREG
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_knight_done:
    RETURN

; ============================================================================
; movegen_sliding - Generate sliding piece moves (bishop/rook/queen)
;
; Input:  movegen_square = starting square
;         temp3 = direction offset
; Output: Moves added to move list
; ============================================================================
movegen_sliding:
    MOVF    movegen_square, W
    MOVWF   slide_square        ; Start at piece position

movegen_sliding_loop:
    ; Add direction offset to current square
    MOVF    temp3, W
    ADDWF   slide_square, F

    ; Check bounds (0-63)
    MOVF    slide_square, W
    SUBLW   63
    BNC     movegen_sliding_done ; Out of bounds

    ; Check for file wrapping (important!)
    MOVF    slide_square, W
    CALL    movegen_is_valid_sq
    BZ      movegen_sliding_done

    ; Check what's on target square
    MOVF    slide_square, W
    MOVWF   curr_to
    CALL    board_get_piece
    MOVWF   temp4

    ; If empty, add move and continue
    ANDLW   PIECE_MASK
    BZ      movegen_sliding_empty

    ; Square occupied - check if enemy or friend
    MOVF    temp4, W
    ANDLW   COLOR_MASK
    MOVWF   temp5               ; temp5 = target color

    MOVF    movegen_piece, W
    ANDLW   COLOR_MASK          ; Our color

    SUBWF   temp5, W
    BZ      movegen_sliding_done ; Same color, stop

    ; Enemy piece - add capture and stop
    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    CALL    movegen_add_move
    GOTO    movegen_sliding_done

movegen_sliding_empty:
    ; Empty square - add move and continue
    CLRF    curr_flags
    CALL    movegen_add_move
    GOTO    movegen_sliding_loop

movegen_sliding_done:
    RETURN

; ============================================================================
; movegen_bishop - Generate bishop moves (diagonal)
; ============================================================================
movegen_bishop:
    ; Four diagonal directions
    MOVLW   DIR_NE
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_NW
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_SE
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_SW
    MOVWF   temp3
    CALL    movegen_sliding

    RETURN

; ============================================================================
; movegen_rook - Generate rook moves (orthogonal)
; ============================================================================
movegen_rook:
    ; Four orthogonal directions
    MOVLW   DIR_N
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_S
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_E
    MOVWF   temp3
    CALL    movegen_sliding

    MOVLW   DIR_W
    MOVWF   temp3
    CALL    movegen_sliding

    RETURN

; ============================================================================
; movegen_queen - Generate queen moves (diagonal + orthogonal)
; ============================================================================
movegen_queen:
    CALL    movegen_bishop      ; Diagonal moves
    CALL    movegen_rook        ; Orthogonal moves
    RETURN

; ============================================================================
; movegen_king - Generate king moves (including castling)
; ============================================================================
movegen_king:
    ; King moves one square in any direction (8 directions)
    ; Similar to knight but simpler

    ; North
    MOVF    movegen_square, W
    ADDLW   DIR_N
    CALL    movegen_is_valid_sq
    BZ      movegen_king_s
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_s:
    ; South
    MOVF    movegen_square, W
    ADDLW   DIR_S
    CALL    movegen_is_valid_sq
    BZ      movegen_king_e
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_e:
    ; East
    MOVF    movegen_square, W
    ANDLW   0x07
    SUBLW   7
    BZ      movegen_king_w      ; File H, can't go east

    MOVF    movegen_square, W
    ADDLW   DIR_E
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_w:
    ; West
    MOVF    movegen_square, W
    ANDLW   0x07
    BZ      movegen_king_ne     ; File A, can't go west

    MOVF    movegen_square, W
    ADDLW   DIR_W
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_ne:
    ; Northeast
    MOVF    movegen_square, W
    ADDLW   DIR_NE
    CALL    movegen_is_valid_sq
    BZ      movegen_king_nw
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_nw:
    ; Northwest
    MOVF    movegen_square, W
    ADDLW   DIR_NW
    CALL    movegen_is_valid_sq
    BZ      movegen_king_se
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_se:
    ; Southeast
    MOVF    movegen_square, W
    ADDLW   DIR_SE
    CALL    movegen_is_valid_sq
    BZ      movegen_king_sw
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_sw:
    ; Southwest
    MOVF    movegen_square, W
    ADDLW   DIR_SW
    CALL    movegen_is_valid_sq
    BZ      movegen_king_castle
    MOVWF   curr_to
    CALL    movegen_check_target
    CALL    movegen_add_if_valid

movegen_king_castle:
    ; Castling (simplified - detailed implementation in check.asm)
    ; Will be implemented with proper attack checking
    RETURN

; ============================================================================
; movegen_check_target - Check if target square can be moved to
;
; Input:  curr_to = target square
; Output: curr_flags = set if capture, cleared if empty
;         Z flag = set if invalid (own piece)
; ============================================================================
movegen_check_target:
    MOVF    curr_to, W
    CALL    board_get_piece
    MOVWF   temp4

    ; Check if empty
    ANDLW   PIECE_MASK
    BZ      movegen_check_empty

    ; Occupied - check color
    MOVF    temp4, W
    ANDLW   COLOR_MASK
    MOVWF   temp5

    MOVF    movegen_piece, W
    ANDLW   COLOR_MASK

    SUBWF   temp5, W
    BZ      movegen_check_invalid ; Same color

    ; Enemy piece - valid capture
    MOVLW   MOVE_CAPTURE
    MOVWF   curr_flags
    ANDLW   0xFF                ; Clear Z flag
    RETURN

movegen_check_empty:
    CLRF    curr_flags
    ANDLW   0xFF                ; Clear Z flag
    RETURN

movegen_check_invalid:
    CLRF    WREG                ; Set Z flag
    RETURN

; ============================================================================
; movegen_add_if_valid - Add move if curr_flags indicates valid
; ============================================================================
movegen_add_if_valid:
    BZ      movegen_add_if_valid_done ; Z set = invalid
    CALL    movegen_add_move

movegen_add_if_valid_done:
    RETURN

; ============================================================================
; movegen_add_move - Add move to move list
;
; Input:  movegen_square = from square (curr_from)
;         curr_to = to square
;         curr_flags = move flags
; Output: Move added to list, move_count incremented
; ============================================================================
movegen_add_move:
    ; Save FSR0 (pointing to move list)
    MOVF    FSR0L, W
    MOVWF   fsr0_save_l
    MOVF    FSR0H, W
    MOVWF   fsr0_save_h

    ; Calculate offset: move_count * 4
    MOVF    move_count, W
    RLNCF   WREG, F             ; * 2
    RLNCF   WREG, F             ; * 4
    ADDLW   LOW move_list
    MOVWF   FSR0L
    MOVLW   HIGH move_list
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Store move: [from][to][flags][captured]
    MOVF    movegen_square, W
    MOVWF   POSTINC0            ; from

    MOVF    curr_to, W
    MOVWF   POSTINC0            ; to

    MOVF    curr_flags, W
    MOVWF   POSTINC0            ; flags

    ; Get captured piece if capture
    BTFSC   curr_flags, 7       ; Test capture bit
    GOTO    movegen_add_capture

    CLRF    POSTINC0            ; No capture
    GOTO    movegen_add_inc

movegen_add_capture:
    MOVF    curr_to, W
    CALL    board_get_piece
    MOVWF   POSTINC0            ; Captured piece

movegen_add_inc:
    ; Increment move count
    INCF    move_count, F

    ; Restore FSR0
    MOVF    fsr0_save_l, W
    MOVWF   FSR0L
    MOVF    fsr0_save_h, W
    MOVWF   FSR0H

    RETURN

; ============================================================================
; movegen_is_valid_sq - Check if square is valid (0-63) and no wrap
;
; Input:  WREG = square
; Output: WREG = square if valid, Z cleared
;         WREG = 0, Z set if invalid
; ============================================================================
movegen_is_valid_sq:
    ; Check if < 64
    MOVWF   temp6
    SUBLW   63
    BNC     movegen_invalid_sq  ; >= 64

    ; Valid
    MOVF    temp6, W
    ANDLW   0xFF                ; Clear Z
    RETURN

movegen_invalid_sq:
    CLRF    WREG                ; Set Z
    RETURN

; ============================================================================
; End of movegen.asm
; ============================================================================
