; ============================================================================
; test_board.asm - Board Representation Tests
; Chess Engine Test Suite
; ============================================================================
; This file contains unit tests for the board representation module.
;
; Tests:
;   1. Board initialization
;   2. Piece placement and retrieval
;   3. Square clearing
;   4. Algebraic notation conversion
;   5. Piece to character conversion
; ============================================================================

    #include "../config.inc"
    #include "../definitions.inc"
    #include "../memory.inc"

; ============================================================================
; Test 1: Board Initialization
; ============================================================================
test_board_init:
    CALL    board_init

    ; Verify white pieces on rank 1
    MOVLW   E1
    CALL    board_get_piece
    SUBLW   W_KING
    BNZ     test1_fail

    MOVLW   A1
    CALL    board_get_piece
    SUBLW   W_ROOK
    BNZ     test1_fail

    ; Verify black pieces on rank 8
    MOVLW   E8
    CALL    board_get_piece
    SUBLW   B_KING
    BNZ     test1_fail

    ; Verify empty squares in middle
    MOVLW   E4
    CALL    board_get_piece
    SUBLW   EMPTY
    BNZ     test1_fail

    ; Test passed
    MOVLW   0x01
    RETURN

test1_fail:
    CLRF    WREG
    RETURN

; ============================================================================
; Test 2: Get and Set Piece
; ============================================================================
test_get_set_piece:
    ; Set white queen on e4
    MOVLW   E4
    MOVWF   curr_square
    MOVLW   W_QUEEN
    MOVWF   curr_piece
    CALL    board_set_piece

    ; Retrieve and verify
    MOVLW   E4
    CALL    board_get_piece
    SUBLW   W_QUEEN
    BNZ     test2_fail

    ; Clear square
    MOVLW   E4
    CALL    board_clear_sq

    ; Verify empty
    MOVLW   E4
    CALL    board_get_piece
    SUBLW   EMPTY
    BNZ     test2_fail

    ; Test passed
    MOVLW   0x01
    RETURN

test2_fail:
    CLRF    WREG
    RETURN

; ============================================================================
; Test 3: Algebraic Notation Conversion
; ============================================================================
test_algebraic:
    ; Test e4 (square 28)
    MOVLW   'e'
    MOVWF   temp1
    MOVLW   '4'
    MOVWF   temp2

    CALL    board_algebraic_to_square
    SUBLW   E4
    BNZ     test3_fail

    ; Test reverse conversion
    MOVLW   E4
    CALL    board_square_to_algebraic

    MOVF    temp1, W
    SUBLW   'e'
    BNZ     test3_fail

    MOVF    temp2, W
    SUBLW   '4'
    BNZ     test3_fail

    ; Test passed
    MOVLW   0x01
    RETURN

test3_fail:
    CLRF    WREG
    RETURN

; ============================================================================
; Test 4: Piece to Character Conversion
; ============================================================================
test_piece_to_char:
    ; White king should be 'K'
    MOVLW   W_KING
    CALL    board_piece_to_char
    SUBLW   'K'
    BNZ     test4_fail

    ; Black pawn should be 'p'
    MOVLW   B_PAWN
    CALL    board_piece_to_char
    SUBLW   'p'
    BNZ     test4_fail

    ; Empty should be ' '
    MOVLW   EMPTY
    CALL    board_piece_to_char
    SUBLW   ' '
    BNZ     test4_fail

    ; Test passed
    MOVLW   0x01
    RETURN

test4_fail:
    CLRF    WREG
    RETURN

; ============================================================================
; Run All Board Tests
; ============================================================================
run_board_tests:
    CALL    test_board_init
    BZ      board_tests_fail

    CALL    test_get_set_piece
    BZ      board_tests_fail

    CALL    test_algebraic
    BZ      board_tests_fail

    CALL    test_piece_to_char
    BZ      board_tests_fail

    ; All tests passed
    MOVLW   0x01
    RETURN

board_tests_fail:
    CLRF    WREG
    RETURN

; ============================================================================
; End of test_board.asm
; ============================================================================
