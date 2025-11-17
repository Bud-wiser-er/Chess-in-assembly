; ============================================================================
; ai_level2.asm - Level 2 AI (Static Evaluation)
; Chess Engine Project
; ============================================================================
; This AI evaluates each legal move by making it, evaluating the position,
; and unmaking it. Selects the move with the best evaluation.
;
; Functions:
;   - ai_level2_move:   Select best move based on static evaluation
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; ai_level2_move - Select best move using static evaluation
;
; Input:  None (uses current board position)
; Output: best_move_from, best_move_to, best_move_flags = selected move
;         WREG = 1 if move found, 0 if no legal moves
; ============================================================================
ai_level2_move:
    ; Generate all legal moves
    CALL    movegen_all

    ; Check if any moves available
    MOVF    move_count, F
    BZ      ai_l2_no_moves

    ; Initialize best score
    ; For white: start with worst possible (EVAL_MIN)
    ; For black: start with worst possible (EVAL_MAX)
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     ai_l2_init_black

ai_l2_init_white:
    ; White wants to maximize
    MOVLW   LOW EVAL_MIN
    MOVWF   eval_best_lo
    MOVLW   HIGH EVAL_MIN
    MOVWF   eval_best_hi
    GOTO    ai_l2_start

ai_l2_init_black:
    ; Black wants to minimize
    MOVLW   LOW EVAL_MAX
    MOVWF   eval_best_lo
    MOVLW   HIGH EVAL_MAX
    MOVWF   eval_best_hi

ai_l2_start:
    ; Iterate through all moves
    CLRF    move_index

ai_l2_loop:
    ; Check if done
    MOVF    move_index, W
    SUBWF   move_count, W
    BZ      ai_l2_done

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
    MOVF    POSTINC0, W
    MOVWF   curr_capture

    ; Check if move is legal (doesn't leave king in check)
    CALL    is_legal_move
    BZ      ai_l2_next          ; Illegal, skip

    ; Make the move
    CALL    make_move

    ; Evaluate position
    CALL    evaluate_position

    ; Unmake move
    CALL    unmake_move

    ; Compare with best score
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     ai_l2_compare_black

ai_l2_compare_white:
    ; White maximizing - check if eval > best
    MOVF    eval_best_hi, W
    SUBWF   eval_score_hi, W
    BNZ     ai_l2_check_greater

    ; High bytes equal, check low bytes
    MOVF    eval_best_lo, W
    SUBWF   eval_score_lo, W

ai_l2_check_greater:
    BNC     ai_l2_next          ; Not better, skip

    ; Better move found - save it
    GOTO    ai_l2_save_best

ai_l2_compare_black:
    ; Black minimizing - check if eval < best
    MOVF    eval_score_hi, W
    SUBWF   eval_best_hi, W
    BNZ     ai_l2_check_less

    MOVF    eval_score_lo, W
    SUBWF   eval_best_lo, W

ai_l2_check_less:
    BNC     ai_l2_next          ; Not better, skip

ai_l2_save_best:
    ; Save as best move
    MOVF    curr_from, W
    MOVWF   best_move_from
    MOVF    curr_to, W
    MOVWF   best_move_to
    MOVF    curr_flags, W
    MOVWF   best_move_flags
    MOVF    curr_capture, W
    MOVWF   best_move_capture

    ; Save score
    MOVF    eval_score_lo, W
    MOVWF   eval_best_lo
    MOVF    eval_score_hi, W
    MOVWF   eval_best_hi

ai_l2_next:
    INCF    move_index, F
    GOTO    ai_l2_loop

ai_l2_done:
    ; Best move is in best_move_*
    MOVLW   0x01
    RETURN

ai_l2_no_moves:
    CLRF    WREG
    RETURN

; ============================================================================
; End of ai_level2.asm
; ============================================================================
