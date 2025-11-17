; ============================================================================
; ai_level1.asm - Level 1 AI (Random Moves)
; Chess Engine Project
; ============================================================================
; This is the simplest AI - just picks a random legal move.
; Uses Timer1 as entropy source for randomness.
;
; Functions:
;   - ai_level1_move:   Select random legal move
;   - random_init:      Initialize random number generator
;   - random_byte:      Get random byte
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; ai_level1_move - Select a random legal move
;
; Input:  None (uses current board position)
; Output: best_move_from, best_move_to, best_move_flags = selected move
;         WREG = 1 if move found, 0 if no legal moves
; ============================================================================
ai_level1_move:
    ; Generate all legal moves
    CALL    movegen_all

    ; Check if any moves available
    MOVF    move_count, F
    BZ      ai_l1_no_moves

    ; Get random number modulo move_count
    CALL    random_byte
    MOVWF   temp1

    ; Calculate temp1 % move_count (simple division)
    CLRF    temp2               ; quotient

ai_l1_mod_loop:
    MOVF    move_count, W
    SUBWF   temp1, W
    BNC     ai_l1_mod_done      ; temp1 < move_count

    MOVWF   temp1               ; temp1 = temp1 - move_count
    INCF    temp2, F
    GOTO    ai_l1_mod_loop

ai_l1_mod_done:
    ; temp1 now contains random index (0 to move_count-1)

    ; Get move from list at index temp1
    MOVF    temp1, W
    RLNCF   WREG, F             ; * 2
    RLNCF   WREG, F             ; * 4
    ADDLW   LOW move_list
    MOVWF   FSR0L
    MOVLW   HIGH move_list
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Load selected move
    MOVF    POSTINC0, W
    MOVWF   best_move_from
    MOVF    POSTINC0, W
    MOVWF   best_move_to
    MOVF    POSTINC0, W
    MOVWF   best_move_flags
    MOVF    POSTINC0, W
    MOVWF   best_move_capture

    ; Move found
    MOVLW   0x01
    RETURN

ai_l1_no_moves:
    CLRF    WREG
    RETURN

; ============================================================================
; random_init - Initialize random number generator
;
; Uses Timer1 as entropy source
; ============================================================================
random_init:
    ; Seed with Timer1 value
    MOVF    TMR1L, W
    MOVWF   rand_state_0
    MOVF    TMR1H, W
    MOVWF   rand_state_1

    ; Add some variation
    COMF    rand_state_0, F
    INCF    rand_state_1, F

    RETURN

; ============================================================================
; random_byte - Get random byte using simple PRNG
;
; Uses XOR shift algorithm (simple and fast)
; Output: WREG = random byte
; ============================================================================
random_byte:
    ; XOR shift PRNG
    ; state ^= state << 3
    MOVF    rand_state_0, W
    MOVWF   temp1
    RLNCF   temp1, F
    RLNCF   temp1, F
    RLNCF   temp1, F
    XORWF   rand_state_0, F

    ; state ^= state >> 5
    MOVF    rand_state_0, W
    MOVWF   temp1
    RRNCF   temp1, F
    RRNCF   temp1, F
    RRNCF   temp1, F
    RRNCF   temp1, F
    RRNCF   temp1, F
    XORWF   rand_state_0, F

    ; Mix with Timer1 for additional entropy
    MOVF    TMR1L, W
    XORWF   rand_state_0, F

    ; Return random value
    MOVF    rand_state_0, W
    RETURN

; ============================================================================
; End of ai_level1.asm
; ============================================================================
