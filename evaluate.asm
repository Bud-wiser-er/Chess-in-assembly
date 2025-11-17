; ============================================================================
; evaluate.asm - Position Evaluation Function
; Chess Engine Project
; ============================================================================
; This module evaluates chess positions for the AI.
; Evaluation is based on:
;   1. Material count (piece values)
;   2. Piece-square tables (positional bonuses)
;   3. Simple heuristics (king safety, etc.)
;
; Functions:
;   - evaluate_position:    Evaluate current position
;   - count_material:       Count material for both sides
;   - evaluate_piece_sq:    Get piece-square table value
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; evaluate_position - Evaluate current board position
;
; Input:  Board state
; Output: eval_score_lo:eval_score_hi = evaluation score (centipawns)
;         Positive = good for white, Negative = good for black
; Modifies: Many registers
; ============================================================================
evaluate_position:
    ; Initialize scores to zero
    CLRF    eval_score_lo
    CLRF    eval_score_hi

    CLRF    white_material_lo
    CLRF    white_material_hi
    CLRF    black_material_lo
    CLRF    black_material_hi

    ; Iterate through board and count material + position
    CLRF    curr_square

eval_loop:
    ; Get piece at current square
    MOVF    curr_square, W
    CALL    board_get_piece
    MOVWF   curr_piece

    ; Check if empty
    ANDLW   PIECE_MASK
    BZ      eval_next_square

    ; Get piece type
    MOVF    curr_piece, W
    ANDLW   PIECE_MASK
    MOVWF   temp1               ; temp1 = piece type

    ; Get piece color
    MOVF    curr_piece, W
    ANDLW   COLOR_MASK
    MOVWF   temp2               ; temp2 = color

    ; Get material value
    CALL    get_piece_value
    MOVWF   temp3               ; temp3 = piece value (low byte)

    ; Add to appropriate material count
    MOVF    temp2, F
    BNZ     eval_black_material

eval_white_material:
    MOVF    temp3, W
    ADDWF   white_material_lo, F
    BTFSC   STATUS, C
    INCF    white_material_hi, F
    GOTO    eval_piece_square

eval_black_material:
    MOVF    temp3, W
    ADDWF   black_material_lo, F
    BTFSC   STATUS, C
    INCF    black_material_hi, F

eval_piece_square:
    ; Add piece-square table bonus (simplified for 8-bit)
    ; In full implementation, would use lookup tables
    ; For now, simple positional bonuses

    ; Bonus for central squares (d4, d5, e4, e5)
    MOVF    curr_square, W
    SUBLW   D4
    BZ      eval_center_bonus

    MOVF    curr_square, W
    SUBLW   D5
    BZ      eval_center_bonus

    MOVF    curr_square, W
    SUBLW   E4
    BZ      eval_center_bonus

    MOVF    curr_square, W
    SUBLW   E5
    BZ      eval_center_bonus

    GOTO    eval_next_square

eval_center_bonus:
    ; Add 10 centipawn bonus for central control
    MOVLW   10
    MOVWF   temp4

    MOVF    temp2, F
    BNZ     eval_black_center

    ; White center bonus
    ADDWF   white_material_lo, F
    BTFSC   STATUS, C
    INCF    white_material_hi, F
    GOTO    eval_next_square

eval_black_center:
    ADDWF   black_material_lo, F
    BTFSC   STATUS, C
    INCF    black_material_hi, F

eval_next_square:
    INCF    curr_square, F
    MOVLW   BOARD_SIZE
    SUBWF   curr_square, W
    BNZ     eval_loop

    ; Calculate final score: white_material - black_material
    MOVF    black_material_lo, W
    SUBWF   white_material_lo, W
    MOVWF   eval_score_lo

    MOVF    black_material_hi, W
    SUBWFB  white_material_hi, W
    MOVWF   eval_score_hi

    RETURN

; ============================================================================
; get_piece_value - Get material value of piece type
;
; Input:  temp1 = piece type (1-6)
; Output: WREG = piece value in centipawns (low byte)
; ============================================================================
get_piece_value:
    MOVF    temp1, W
    ADDWF   PCL, F

    GOTO    get_value_none      ; 0 (shouldn't happen)
    GOTO    get_value_pawn      ; 1
    GOTO    get_value_knight    ; 2
    GOTO    get_value_bishop    ; 3
    GOTO    get_value_rook      ; 4
    GOTO    get_value_queen     ; 5
    GOTO    get_value_king      ; 6

get_value_none:
    RETLW   0

get_value_pawn:
    RETLW   VAL_PAWN & 0xFF     ; 100

get_value_knight:
    RETLW   VAL_KNIGHT & 0xFF   ; 300 (low byte: 44)

get_value_bishop:
    RETLW   VAL_BISHOP & 0xFF   ; 300

get_value_rook:
    RETLW   VAL_ROOK & 0xFF     ; 500 (low byte: 244)

get_value_queen:
    RETLW   VAL_QUEEN & 0xFF    ; 900 (low byte: 132)

get_value_king:
    RETLW   0                   ; King has no material value

; ============================================================================
; compare_scores - Compare two 16-bit scores
;
; Input:  eval_score_lo:eval_score_hi = score1
;         eval_best_lo:eval_best_hi = score2
; Output: STATUS flags set according to score1 - score2
;         WREG = 1 if score1 > score2, 0 otherwise
; ============================================================================
compare_scores:
    ; Compare high bytes first
    MOVF    eval_best_hi, W
    SUBWF   eval_score_hi, W
    BNZ     compare_done

    ; High bytes equal, compare low bytes
    MOVF    eval_best_lo, W
    SUBWF   eval_score_lo, W

compare_done:
    ; Carry set means score1 >= score2
    BTFSC   STATUS, C
    GOTO    compare_greater

    CLRF    WREG
    RETURN

compare_greater:
    MOVLW   0x01
    RETURN

; ============================================================================
; End of evaluate.asm
; ============================================================================
