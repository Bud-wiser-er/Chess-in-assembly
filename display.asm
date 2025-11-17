; ============================================================================
; display.asm - Board Display and Output Formatting
; Chess Engine Project
; ============================================================================
; This module handles displaying the chess board and game information
; via UART serial connection.
;
; Functions:
;   - display_board:        Display current board state
;   - display_move:         Display a move in algebraic notation
;   - display_welcome:      Display welcome message
;   - display_prompt:       Display input prompt
;   - display_status:       Display game status
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; display_welcome - Display welcome message
; ============================================================================
display_welcome:
    ; Display title
    MOVLW   LOW str_title
    MOVWF   TBLPTRL
    MOVLW   HIGH str_title
    MOVWF   TBLPTRH
    MOVLW   UPPER str_title
    MOVWF   TBLPTRU
    CALL    uart_tx_string

    CALL    uart_tx_newline

    ; Display instructions
    MOVLW   LOW str_instructions
    MOVWF   TBLPTRL
    MOVLW   HIGH str_instructions
    MOVWF   TBLPTRH
    MOVLW   UPPER str_instructions
    MOVWF   TBLPTRU
    CALL    uart_tx_string

    CALL    uart_tx_newline
    CALL    uart_tx_newline

    RETURN

; ============================================================================
; display_board - Display current board state in ASCII art
; ============================================================================
display_board:
    CALL    uart_tx_newline

    ; Display from rank 8 down to rank 1
    MOVLW   7
    MOVWF   disp_rank           ; Start at rank 7 (8 in chess notation)

disp_board_rank_loop:
    ; Display rank number
    MOVF    disp_rank, W
    ADDLW   '1'
    CALL    uart_tx_byte

    MOVLW   ' '
    CALL    uart_tx_byte
    MOVLW   '|'
    CALL    uart_tx_byte

    ; Display all files for this rank
    CLRF    disp_file

disp_board_file_loop:
    ; Calculate square = rank * 8 + file
    MOVF    disp_rank, W
    RLNCF   WREG, F
    RLNCF   WREG, F
    RLNCF   WREG, F             ; rank * 8
    ADDWF   disp_file, W        ; + file
    MOVWF   disp_square

    ; Get piece at square
    CALL    board_get_piece
    MOVWF   disp_piece

    ; Convert to character
    CALL    board_piece_to_char
    CALL    uart_tx_byte

    ; Separator
    MOVLW   '|'
    CALL    uart_tx_byte

    ; Next file
    INCF    disp_file, F
    MOVLW   8
    SUBWF   disp_file, W
    BNZ     disp_board_file_loop

    ; End of rank
    CALL    uart_tx_newline

    ; Next rank (going down)
    DECF    disp_rank, F
    MOVF    disp_rank, W
    ADDLW   1
    BNZ     disp_board_rank_loop

    ; Display file labels
    MOVLW   ' '
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'a'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'b'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'c'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'd'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'e'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'f'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'g'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    MOVLW   'h'
    CALL    uart_tx_byte

    CALL    uart_tx_newline
    CALL    uart_tx_newline

    RETURN

; ============================================================================
; display_move - Display a move in algebraic notation
;
; Input:  best_move_from, best_move_to
; ============================================================================
display_move:
    ; Display color
    MOVF    game_turn, W
    ANDLW   0x01
    BNZ     disp_move_black

    ; White
    MOVLW   LOW str_white
    MOVWF   TBLPTRL
    MOVLW   HIGH str_white
    MOVWF   TBLPTRH
    MOVLW   UPPER str_white
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    GOTO    disp_move_squares

disp_move_black:
    MOVLW   LOW str_black
    MOVWF   TBLPTRL
    MOVLW   HIGH str_black
    MOVWF   TBLPTRH
    MOVLW   UPPER str_black
    MOVWF   TBLPTRU
    CALL    uart_tx_string

disp_move_squares:
    MOVLW   ':'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte

    ; Display from square
    MOVF    best_move_from, W
    CALL    board_square_to_algebraic
    MOVF    temp1, W            ; file
    CALL    uart_tx_byte
    MOVF    temp2, W            ; rank
    CALL    uart_tx_byte

    ; Separator
    MOVLW   '-'
    CALL    uart_tx_byte

    ; Display to square
    MOVF    best_move_to, W
    CALL    board_square_to_algebraic
    MOVF    temp1, W
    CALL    uart_tx_byte
    MOVF    temp2, W
    CALL    uart_tx_byte

    ; Check for promotion
    BTFSS   best_move_flags, 6
    GOTO    disp_move_end

    ; Display promotion piece
    MOVF    best_move_flags, W
    ANDLW   0x0C
    RRNCF   WREG, F
    RRNCF   WREG, F
    ADDWF   PCL, F

    GOTO    disp_promo_queen
    GOTO    disp_promo_rook
    GOTO    disp_promo_bishop
    GOTO    disp_promo_knight

disp_promo_queen:
    MOVLW   'Q'
    CALL    uart_tx_byte
    GOTO    disp_move_end

disp_promo_rook:
    MOVLW   'R'
    CALL    uart_tx_byte
    GOTO    disp_move_end

disp_promo_bishop:
    MOVLW   'B'
    CALL    uart_tx_byte
    GOTO    disp_move_end

disp_promo_knight:
    MOVLW   'N'
    CALL    uart_tx_byte

disp_move_end:
    CALL    uart_tx_newline
    RETURN

; ============================================================================
; display_prompt - Display input prompt
; ============================================================================
display_prompt:
    MOVLW   '>'
    CALL    uart_tx_byte
    MOVLW   ' '
    CALL    uart_tx_byte
    RETURN

; ============================================================================
; display_status - Display game status (check, checkmate, etc.)
; ============================================================================
display_status:
    ; Check for checkmate
    CALL    is_checkmate
    BZ      disp_stat_check

    ; Checkmate
    MOVLW   LOW str_checkmate
    MOVWF   TBLPTRL
    MOVLW   HIGH str_checkmate
    MOVWF   TBLPTRH
    MOVLW   UPPER str_checkmate
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    CALL    uart_tx_newline
    RETURN

disp_stat_check:
    ; Check for stalemate
    CALL    is_stalemate
    BZ      disp_stat_check2

    ; Stalemate
    MOVLW   LOW str_stalemate
    MOVWF   TBLPTRL
    MOVLW   HIGH str_stalemate
    MOVWF   TBLPTRH
    MOVLW   UPPER str_stalemate
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    CALL    uart_tx_newline
    RETURN

disp_stat_check2:
    ; Check for check
    MOVF    in_check, F
    BZ      disp_stat_done

    ; In check
    MOVLW   LOW str_check
    MOVWF   TBLPTRL
    MOVLW   HIGH str_check
    MOVWF   TBLPTRH
    MOVLW   UPPER str_check
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    CALL    uart_tx_newline

disp_stat_done:
    RETURN

; ============================================================================
; String Constants (stored in program memory)
; ============================================================================
    ORG 0x1000              ; Place strings in program memory

str_title:
    DB  "PIC18F45K22 Chess Engine v1.0", 0

str_instructions:
    DB  "Commands: MOVE <from><to> | NEW <level> | SHOW | LEVEL <n>", 0

str_white:
    DB  "WHITE", 0

str_black:
    DB  "BLACK", 0

str_check:
    DB  "Check!", 0

str_checkmate:
    DB  "Checkmate!", 0

str_stalemate:
    DB  "Stalemate - Draw!", 0

str_illegal:
    DB  "Illegal move!", 0

str_thinking:
    DB  "Thinking...", 0

; ============================================================================
; End of display.asm
; ============================================================================
