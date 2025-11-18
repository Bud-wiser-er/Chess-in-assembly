; ============================================================================
; move_validator.S - Move Validation and Response Protocol
; PIC18F45K22 Chess Engine
; ============================================================================
; This module handles move validation and response protocol for PC communication.
;
; Protocol:
;   PC → PIC: "MOVE e2e4\r\n"
;   PIC validates move against current board
;   If valid:
;     - Make user's move
;     - AI makes response move
;     - PIC → PC: "OK <FEN>\r\n"
;   If invalid:
;     - PIC → PC: "ERROR Invalid move\r\n"
;
; Commands from PC:
;   MOVE <from><to>[promo]  - Make a move (e.g., "MOVE e2e4")
;   FEN <fen_string>        - Set position from FEN
;   NEW <level>             - Start new game with AI level
;   GET                     - Get current position as FEN
;
; Responses to PC:
;   OK <fen_string>         - Move accepted, new position
;   ERROR <message>         - Move rejected, reason given
;   FEN <fen_string>        - Current position (response to GET)
;
; ============================================================================

    PROCESSOR 18F45K22
    #include <xc.inc>

; ============================================================================
; Variables
; ============================================================================
PSECT udata_bank0
    cmd_buffer:         DS 96       ; Command buffer from UART
    response_buffer:    DS 128      ; Response buffer for UART
    move_from:          DS 1        ; From square
    move_to:            DS 1        ; To square
    move_promo:         DS 1        ; Promotion piece
    is_valid:           DS 1        ; Move validity flag

PSECT udata_acs
    cmd_ptr:            DS 1        ; Command buffer pointer
    resp_ptr:           DS 1        ; Response buffer pointer

PSECT code

; ============================================================================
; protocol_handler - Main command handler
; ============================================================================
protocol_handler:
    ; Receive command from UART
    call    receive_command

    ; Check command type
    movf    BANKMASK(cmd_buffer), W
    sublw   'M'
    bz      handle_move_cmd

    movf    BANKMASK(cmd_buffer), W
    sublw   'F'
    bz      handle_fen_cmd

    movf    BANKMASK(cmd_buffer), W
    sublw   'N'
    bz      handle_new_cmd

    movf    BANKMASK(cmd_buffer), W
    sublw   'G'
    bz      handle_get_cmd

    ; Unknown command
    call    send_error_unknown
    return

; ============================================================================
; handle_move_cmd - Process MOVE command
; Format: "MOVE e2e4" or "MOVE e7e8Q"
; ============================================================================
handle_move_cmd:
    ; Parse move from command buffer
    ; Skip "MOVE " (5 characters)
    movlw   5
    movwf   BANKMASK(cmd_ptr)

    ; Get from square (2 chars: e2)
    call    parse_square
    movwf   BANKMASK(move_from)

    ; Check if valid square
    sublw   0xFF
    bz      handle_move_invalid

    ; Get to square (2 chars: e4)
    call    parse_square
    movwf   BANKMASK(move_to)

    ; Check if valid square
    sublw   0xFF
    bz      handle_move_invalid

    ; Check for promotion piece (optional)
    call    parse_promotion
    movwf   BANKMASK(move_promo)

    ; Validate move against current board
    movf    BANKMASK(move_from), W
    movwf   BANKMASK(curr_from)
    movf    BANKMASK(move_to), W
    movwf   BANKMASK(curr_to)
    movf    BANKMASK(move_promo), W
    movwf   BANKMASK(curr_flags)

    call    validate_move
    movwf   BANKMASK(is_valid)

    ; Check if move is valid
    bz      handle_move_invalid

    ; Move is valid - make it
    call    make_move

    ; AI makes response move
    call    ai_make_move

    ; Generate FEN for new position
    call    fen_generate

    ; Send OK response with FEN
    call    send_ok_response
    return

handle_move_invalid:
    call    send_error_invalid_move
    return

; ============================================================================
; handle_fen_cmd - Process FEN command
; Format: "FEN rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
; ============================================================================
handle_fen_cmd:
    ; Copy FEN string to fen_buffer (skip "FEN ")
    movlw   4
    movwf   BANKMASK(cmd_ptr)

    clrf    BANKMASK(fen_ptr)
copy_fen_loop:
    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    bz      copy_fen_done

    ; Store in fen_buffer
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

    incf    BANKMASK(cmd_ptr), F
    incf    BANKMASK(fen_ptr), F
    bra     copy_fen_loop

copy_fen_done:
    ; Null terminate
    movf    BANKMASK(fen_ptr), W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F
    clrf    INDF0

    ; Parse FEN
    call    fen_parse

    ; Send OK response
    call    send_ok_fen
    return

; ============================================================================
; handle_new_cmd - Process NEW command
; Format: "NEW 2" (starts new game with AI level 2)
; ============================================================================
handle_new_cmd:
    ; Parse AI level (skip "NEW ")
    movlw   4
    movwf   BANKMASK(cmd_ptr)

    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    sublw   '0'
    negf    WREG
    movwf   BANKMASK(ai_level)

    ; Initialize new game
    call    board_init

    ; Generate starting FEN
    call    fen_generate

    ; Send OK response
    call    send_ok_response
    return

; ============================================================================
; handle_get_cmd - Process GET command (returns current FEN)
; ============================================================================
handle_get_cmd:
    call    fen_generate
    call    send_fen_response
    return

; ============================================================================
; Helper Functions
; ============================================================================

; Parse square from algebraic notation
; Input: cmd_ptr points to square (e.g., "e4")
; Output: W = square index (0-63) or 0xFF if invalid
parse_square:
    ; Get file character
    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    movwf   temp3           ; Save file character
    incf    BANKMASK(cmd_ptr), F

    ; Check if valid file (a-h)
    ; Check char >= 'a'
    movlw   'a'
    subwf   temp3, W        ; W = char - 'a'
    bn      parse_square_invalid  ; If negative, char < 'a'

    ; Check char <= 'h'
    movf    temp3, W
    sublw   'h'             ; W = 'h' - char
    bn      parse_square_invalid  ; If negative, char > 'h'

    ; Calculate file (0-7)
    movf    temp3, W
    sublw   'a'
    negf    WREG
    movwf   temp1

    ; Get rank character
    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    movwf   temp3           ; Save rank character
    incf    BANKMASK(cmd_ptr), F

    ; Check if valid rank (1-8)
    ; Check char >= '1'
    movlw   '1'
    subwf   temp3, W        ; W = char - '1'
    bn      parse_square_invalid  ; If negative, char < '1'

    ; Check char <= '8'
    movf    temp3, W
    sublw   '8'             ; W = '8' - char
    bn      parse_square_invalid  ; If negative, char > '8'

    ; Calculate rank (0-7)
    movf    temp3, W
    sublw   '1'
    negf    WREG
    movwf   temp2

    ; Calculate square index: rank * 8 + file
    movf    temp2, W
    mullw   8
    movf    PRODL, W
    addwf   temp1, W

    return

parse_square_invalid:
    retlw   0xFF

; Parse promotion piece (if present)
; Returns piece type or 0 if none
parse_promotion:
    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W

    ; Check for Q, R, B, N
    sublw   'Q'
    bz      promo_queen
    movf    INDF0, W
    sublw   'R'
    bz      promo_rook
    movf    INDF0, W
    sublw   'B'
    bz      promo_bishop
    movf    INDF0, W
    sublw   'N'
    bz      promo_knight

    retlw   0

promo_queen:
    retlw   0x05
promo_rook:
    retlw   0x04
promo_bishop:
    retlw   0x03
promo_knight:
    retlw   0x02

; ============================================================================
; Response Functions
; ============================================================================

; Send OK response with FEN
; Format: "OK <fen_string>\r\n"
send_ok_response:
    ; Build response: "OK "
    clrf    BANKMASK(resp_ptr)

    movlw   'O'
    call    put_response_char
    movlw   'K'
    call    put_response_char
    movlw   ' '
    call    put_response_char

    ; Copy FEN from fen_buffer
    clrf    temp1
copy_fen_to_response:
    movf    temp1, W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    bz      copy_fen_response_done

    call    put_response_char
    incf    temp1, F
    bra     copy_fen_to_response

copy_fen_response_done:
    ; Add CR+LF
    movlw   0x0D
    call    put_response_char
    movlw   0x0A
    call    put_response_char
    clrf    WREG
    call    put_response_char

    ; Transmit response
    call    transmit_response
    return

; Send FEN response
; Format: "FEN <fen_string>\r\n"
send_fen_response:
    clrf    BANKMASK(resp_ptr)

    movlw   'F'
    call    put_response_char
    movlw   'E'
    call    put_response_char
    movlw   'N'
    call    put_response_char
    movlw   ' '
    call    put_response_char

    ; Copy FEN
    clrf    temp1
copy_fen_to_fen_response:
    movf    temp1, W
    addlw   LOW (fen_buffer)
    movwf   FSR0L
    movlw   HIGH (fen_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    bz      copy_fen_fen_response_done

    call    put_response_char
    incf    temp1, F
    bra     copy_fen_to_fen_response

copy_fen_fen_response_done:
    movlw   0x0D
    call    put_response_char
    movlw   0x0A
    call    put_response_char
    clrf    WREG
    call    put_response_char

    call    transmit_response
    return

; Send OK for FEN command
send_ok_fen:
    clrf    BANKMASK(resp_ptr)

    movlw   'O'
    call    put_response_char
    movlw   'K'
    call    put_response_char
    movlw   0x0D
    call    put_response_char
    movlw   0x0A
    call    put_response_char
    clrf    WREG
    call    put_response_char

    call    transmit_response
    return

; Send error: invalid move
send_error_invalid_move:
    clrf    BANKMASK(resp_ptr)

    ; "ERROR Invalid move\r\n"
    movlw   'E'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   'O'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   ' '
    call    put_response_char
    movlw   'I'
    call    put_response_char
    movlw   'n'
    call    put_response_char
    movlw   'v'
    call    put_response_char
    movlw   'a'
    call    put_response_char
    movlw   'l'
    call    put_response_char
    movlw   'i'
    call    put_response_char
    movlw   'd'
    call    put_response_char
    movlw   ' '
    call    put_response_char
    movlw   'm'
    call    put_response_char
    movlw   'o'
    call    put_response_char
    movlw   'v'
    call    put_response_char
    movlw   'e'
    call    put_response_char
    movlw   0x0D
    call    put_response_char
    movlw   0x0A
    call    put_response_char
    clrf    WREG
    call    put_response_char

    call    transmit_response
    return

; Send error: unknown command
send_error_unknown:
    clrf    BANKMASK(resp_ptr)

    ; "ERROR Unknown command\r\n"
    movlw   'E'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   'O'
    call    put_response_char
    movlw   'R'
    call    put_response_char
    movlw   ' '
    call    put_response_char
    movlw   'U'
    call    put_response_char
    movlw   'n'
    call    put_response_char
    movlw   'k'
    call    put_response_char
    movlw   'n'
    call    put_response_char
    movlw   'o'
    call    put_response_char
    movlw   'w'
    call    put_response_char
    movlw   'n'
    call    put_response_char
    movlw   0x0D
    call    put_response_char
    movlw   0x0A
    call    put_response_char
    clrf    WREG
    call    put_response_char

    call    transmit_response
    return

; Put character into response buffer
put_response_char:
    movwf   temp1

    movf    BANKMASK(resp_ptr), W
    addlw   LOW (response_buffer)
    movwf   FSR0L
    movlw   HIGH (response_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    temp1, W
    movwf   INDF0

    incf    BANKMASK(resp_ptr), F
    return

; Transmit response buffer via UART
transmit_response:
    clrf    temp1

transmit_loop:
    movf    temp1, W
    addlw   LOW (response_buffer)
    movwf   FSR0L
    movlw   HIGH (response_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    INDF0, W
    bz      transmit_done

    ; Wait for TX ready
tx_wait:
    btfss   PIR1, 4         ; TX1IF
    bra     tx_wait

    movwf   TXREG1

    incf    temp1, F
    bra     transmit_loop

transmit_done:
    return

; Receive command from UART
receive_command:
    clrf    BANKMASK(cmd_ptr)

rx_loop:
    ; Wait for character
    btfss   PIR1, 5         ; RC1IF
    bra     rx_loop

    movf    RCREG1, W

    ; Check for CR or LF (end of command)
    sublw   0x0D
    bz      rx_done
    movf    RCREG1, W
    sublw   0x0A
    bz      rx_done

    ; Store character
    movf    RCREG1, W
    movwf   temp1

    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    movf    temp1, W
    movwf   INDF0

    incf    BANKMASK(cmd_ptr), F

    ; Check for buffer overflow
    movf    BANKMASK(cmd_ptr), W
    sublw   95
    bnz     rx_loop

rx_done:
    ; Null terminate
    movf    BANKMASK(cmd_ptr), W
    addlw   LOW (cmd_buffer)
    movwf   FSR0L
    movlw   HIGH (cmd_buffer)
    movwf   FSR0H
    btfsc   STATUS, 0
    incf    FSR0H, F

    clrf    INDF0

    return

; ============================================================================
; validate_move - Validate if move is legal
; ============================================================================
; ⚠️ WARNING: THIS IS A PLACEHOLDER IMPLEMENTATION
; Currently accepts ALL moves as valid for testing purposes.
;
; For production use, implement full move validation:
;   1. Generate all legal moves for current position
;   2. Check if curr_from/curr_to matches any legal move
;   3. Verify move doesn't leave king in check
;   4. Return 1 if legal, 0 if illegal
;
; Input:  curr_from, curr_to, curr_flags set
; Output: W = 1 if move is valid, 0 if invalid
; ============================================================================
validate_move:
    ; TEMPORARY IMPLEMENTATION - ACCEPTS ALL MOVES
    ; This allows testing of the protocol without full chess logic
    ; Replace this with actual move validation before deployment!

    retlw   1       ; Always return valid (TEMPORARY)

    END
