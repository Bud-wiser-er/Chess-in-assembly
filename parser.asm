; ============================================================================
; parser.asm - Command Parser
; Chess Engine Project
; ============================================================================
; This module parses user input commands and executes them.
;
; Commands:
;   - MOVE <from><to>[promo]  - Make a move (e.g., "MOVE e2e4")
;   - NEW <level>             - Start new game with AI level
;   - SHOW                    - Display board
;   - LEVEL <n>               - Change AI difficulty
;
; Functions:
;   - parse_command:    Parse and execute command
;   - parse_move:       Parse move notation
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; parse_command - Parse and execute user command
;
; Input:  cmd_buffer = command string (null-terminated)
; Output: Command executed
; ============================================================================
parse_command:
    ; Check first character to identify command
    MOVF    cmd_buffer, W
    SUBLW   'M'
    BZ      parse_move_cmd

    MOVF    cmd_buffer, W
    SUBLW   'm'
    BZ      parse_move_cmd

    MOVF    cmd_buffer, W
    SUBLW   'N'
    BZ      parse_new_cmd

    MOVF    cmd_buffer, W
    SUBLW   'n'
    BZ      parse_new_cmd

    MOVF    cmd_buffer, W
    SUBLW   'S'
    BZ      parse_show_cmd

    MOVF    cmd_buffer, W
    SUBLW   's'
    BZ      parse_show_cmd

    MOVF    cmd_buffer, W
    SUBLW   'L'
    BZ      parse_level_cmd

    MOVF    cmd_buffer, W
    SUBLW   'l'
    BZ      parse_level_cmd

    ; Unknown command
    GOTO    parse_error

; ============================================================================
; parse_move_cmd - Parse and execute MOVE command
; Format: MOVE e2e4 or MOVE e7e8Q
; ============================================================================
parse_move_cmd:
    ; Skip "MOVE " (5 characters)
    MOVLW   LOW (cmd_buffer + 5)
    MOVWF   FSR0L
    MOVLW   HIGH (cmd_buffer + 5)
    MOVWF   FSR0H

    ; Get from square (2 characters)
    MOVF    POSTINC0, W
    MOVWF   temp1               ; from file
    MOVF    POSTINC0, W
    MOVWF   temp2               ; from rank

    ; Convert to square number
    CALL    board_algebraic_to_square
    MOVWF   curr_from

    ; Check validity
    SUBLW   NO_SQUARE
    BZ      parse_error

    ; Get to square (2 characters)
    MOVF    POSTINC0, W
    MOVWF   temp1               ; to file
    MOVF    POSTINC0, W
    MOVWF   temp2               ; to rank

    ; Convert to square number
    CALL    board_algebraic_to_square
    MOVWF   curr_to

    ; Check validity
    SUBLW   NO_SQUARE
    BZ      parse_error

    ; Check for promotion character
    MOVF    POSTINC0, W
    MOVWF   temp3

    ; Default: no flags
    CLRF    curr_flags

    ; Check if promotion piece specified
    MOVF    temp3, F
    BZ      parse_move_validate  ; No promotion

    ; Parse promotion piece
    MOVF    temp3, W
    SUBLW   'Q'
    BZ      parse_promo_queen
    MOVF    temp3, W
    SUBLW   'q'
    BZ      parse_promo_queen

    MOVF    temp3, W
    SUBLW   'R'
    BZ      parse_promo_rook
    MOVF    temp3, W
    SUBLW   'r'
    BZ      parse_promo_rook

    MOVF    temp3, W
    SUBLW   'B'
    BZ      parse_promo_bishop
    MOVF    temp3, W
    SUBLW   'b'
    BZ      parse_promo_bishop

    MOVF    temp3, W
    SUBLW   'N'
    BZ      parse_promo_knight
    MOVF    temp3, W
    SUBLW   'n'
    BZ      parse_promo_knight

    GOTO    parse_error

parse_promo_queen:
    MOVLW   MOVE_PROMOTION | PROMO_QUEEN
    MOVWF   curr_flags
    GOTO    parse_move_validate

parse_promo_rook:
    MOVLW   MOVE_PROMOTION | PROMO_ROOK
    MOVWF   curr_flags
    GOTO    parse_move_validate

parse_promo_bishop:
    MOVLW   MOVE_PROMOTION | PROMO_BISHOP
    MOVWF   curr_flags
    GOTO    parse_move_validate

parse_promo_knight:
    MOVLW   MOVE_PROMOTION | PROMO_KNIGHT
    MOVWF   curr_flags

parse_move_validate:
    ; Validate move is legal
    ; Generate all legal moves
    CALL    movegen_all

    ; Search for this move in the list
    CLRF    move_index

parse_move_search:
    MOVF    move_index, W
    SUBWF   move_count, W
    BZ      parse_illegal       ; Not found

    ; Get move from list
    MOVF    move_index, W
    RLNCF   WREG, F
    RLNCF   WREG, F
    ADDLW   LOW move_list
    MOVWF   FSR0L
    MOVLW   HIGH move_list
    MOVWF   FSR0H
    BTFSC   STATUS, C
    INCF    FSR0H, F

    ; Compare from square
    MOVF    INDF0, W
    SUBWF   curr_from, W
    BNZ     parse_move_next

    ; Compare to square
    INCF    FSR0L, F
    MOVF    INDF0, W
    SUBWF   curr_to, W
    BNZ     parse_move_next

    ; Move found! Execute it
    CALL    make_move
    RETURN

parse_move_next:
    INCF    move_index, F
    GOTO    parse_move_search

parse_illegal:
    ; Display illegal move message
    MOVLW   LOW str_illegal
    MOVWF   TBLPTRL
    MOVLW   HIGH str_illegal
    MOVWF   TBLPTRH
    MOVLW   UPPER str_illegal
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    CALL    uart_tx_newline
    RETURN

; ============================================================================
; parse_new_cmd - Parse and execute NEW command
; Format: NEW 1 or NEW 2 or NEW 3
; ============================================================================
parse_new_cmd:
    ; Skip "NEW " (4 characters)
    MOVF    cmd_buffer + 4, W
    SUBLW   '0'
    NEGF    WREG                ; Convert ASCII to number

    ; Validate level (1-3)
    MOVWF   temp1
    SUBLW   0
    BZ      parse_error         ; Level 0 invalid
    MOVF    temp1, W
    SUBLW   3
    BNC     parse_error         ; Level > 3 invalid

    ; Set level
    MOVF    temp1, W
    MOVWF   ai_level

    ; Initialize new game
    CALL    board_init

    ; Display board
    CALL    display_board

    RETURN

; ============================================================================
; parse_show_cmd - Parse and execute SHOW command
; ============================================================================
parse_show_cmd:
    CALL    display_board
    RETURN

; ============================================================================
; parse_level_cmd - Parse and execute LEVEL command
; Format: LEVEL 1 or LEVEL 2 or LEVEL 3
; ============================================================================
parse_level_cmd:
    ; Skip "LEVEL " (6 characters)
    MOVF    cmd_buffer + 6, W
    SUBLW   '0'
    NEGF    WREG

    ; Validate level
    MOVWF   temp1
    SUBLW   0
    BZ      parse_error
    MOVF    temp1, W
    SUBLW   3
    BNC     parse_error

    ; Set level
    MOVF    temp1, W
    MOVWF   ai_level

    ; Display confirmation
    MOVLW   'L'
    CALL    uart_tx_byte
    MOVLW   'e'
    CALL    uart_tx_byte
    MOVLW   'v'
    CALL    uart_tx_byte
    MOVLW   'e'
    CALL    uart_tx_byte
    MOVLW   'l'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte
    MOVF    ai_level, W
    ADDLW   '0'
    CALL    uart_tx_byte
    CALL    uart_tx_newline

    RETURN

; ============================================================================
; parse_error - Handle parse error
; ============================================================================
parse_error:
    MOVLW   'E'
    CALL    uart_tx_byte
    MOVLW   'r'
    CALL    uart_tx_byte
    MOVLW   'r'
    CALL    uart_tx_byte
    MOVLW   'o'
    CALL    uart_tx_byte
    MOVLW   'r'
    CALL    uart_tx_byte
    MOVLW   '!'
    CALL    uart_tx_byte
    CALL    uart_tx_newline
    RETURN

; ============================================================================
; End of parser.asm
; ============================================================================
