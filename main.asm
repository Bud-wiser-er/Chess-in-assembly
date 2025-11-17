; ============================================================================
; main.asm - Main Program Entry Point
; PIC18F45K22 Chess Engine
; ============================================================================
; This is the main program file that initializes the system and runs
; the main game loop.
;
; System Architecture:
;   1. Initialize hardware (oscillator, UART, timers)
;   2. Initialize chess board
;   3. Display welcome message
;   4. Enter main game loop:
;      - Check for user input
;      - Execute user commands
;      - Generate AI response
;      - Check game status
;      - Repeat
;
; Author: PIC18F45K22 Chess Engine Project
; Date: 2025
; ============================================================================

    LIST P=18F45K22
    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; Reset Vector
; ============================================================================
    ORG 0x0000
    GOTO    start

; ============================================================================
; Interrupt Vector (not used in this application)
; ============================================================================
    ORG 0x0008
    RETFIE FAST

    ORG 0x0018
    RETFIE FAST

; ============================================================================
; Main Program Start
; ============================================================================
    ORG 0x0030

start:
    ; Initialize system
    CALL    init_hardware
    CALL    init_game
    CALL    display_welcome
    CALL    display_board

    ; Main game loop
main_loop:
    ; Display prompt
    CALL    display_prompt

    ; Wait for command
    MOVLW   LOW cmd_buffer
    MOVWF   FSR2L
    MOVLW   HIGH cmd_buffer
    MOVWF   FSR2H
    MOVLW   32                  ; Buffer size
    MOVWF   temp1
    CALL    uart_rx_line        ; Receive command

    ; Parse and execute command
    CALL    parse_command

    ; Check game status
    CALL    display_status

    ; Check if game over
    MOVF    game_status, W
    BZ      check_ai_turn       ; Game ongoing

    ; Game over - wait for new game command
    GOTO    main_loop

check_ai_turn:
    ; Check if it's AI's turn
    ; (In this implementation, human is always white, AI is black)
    MOVF    game_turn, W
    ANDLW   0x01
    BZ      main_loop           ; White's turn (human)

    ; AI's turn
    CALL    ai_make_move

    ; Display AI's move
    CALL    display_move

    ; Display updated board
    CALL    display_board

    ; Check game status
    CALL    display_status

    ; Continue loop
    GOTO    main_loop

; ============================================================================
; init_hardware - Initialize microcontroller hardware
; ============================================================================
init_hardware:
    ; Configure oscillator for 16 MHz internal
    MOVLW   b'01110000'         ; 16 MHz HFINTOSC
    MOVWF   OSCCON
    MOVLW   b'00010000'
    MOVWF   OSCCON2

    ; Wait for oscillator to stabilize
    BTFSS   OSCCON, HFIOFS
    GOTO    $-2

    ; Configure all ports as digital
    CLRF    ANSEL
    CLRF    ANSELH

    ; Initialize UART
    CALL    uart_init

    ; Initialize Timer1 (for random number generation)
    MOVLW   b'00000001'         ; Timer1 ON, 1:1 prescaler, internal clock
    MOVWF   T1CON

    ; Initialize random number generator
    CALL    random_init

    RETURN

; ============================================================================
; init_game - Initialize chess game
; ============================================================================
init_game:
    ; Initialize board to starting position
    CALL    board_init

    ; Set default AI level
    MOVLW   LEVEL_EVAL
    MOVWF   ai_level

    ; Clear game status
    CLRF    game_status

    RETURN

; ============================================================================
; ai_make_move - AI makes a move based on selected level
; ============================================================================
ai_make_move:
    ; Display thinking message
    MOVLW   LOW str_thinking
    MOVWF   TBLPTRL
    MOVLW   HIGH str_thinking
    MOVWF   TBLPTRH
    MOVLW   UPPER str_thinking
    MOVWF   TBLPTRU
    CALL    uart_tx_string
    CALL    uart_tx_newline

    ; Check AI level and call appropriate function
    MOVF    ai_level, W
    SUBLW   LEVEL_RANDOM
    BZ      ai_call_level1

    MOVF    ai_level, W
    SUBLW   LEVEL_EVAL
    BZ      ai_call_level2

    MOVF    ai_level, W
    SUBLW   LEVEL_MINIMAX
    BZ      ai_call_level3

    ; Default to level 2
    GOTO    ai_call_level2

ai_call_level1:
    CALL    ai_level1_move
    GOTO    ai_execute_move

ai_call_level2:
    CALL    ai_level2_move
    GOTO    ai_execute_move

ai_call_level3:
    CALL    ai_level3_move
    GOTO    ai_execute_move

ai_execute_move:
    ; Check if move was found
    BZ      ai_no_move

    ; Execute the best move
    MOVF    best_move_from, W
    MOVWF   curr_from
    MOVF    best_move_to, W
    MOVWF   curr_to
    MOVF    best_move_flags, W
    MOVWF   curr_flags

    CALL    make_move

    RETURN

ai_no_move:
    ; No legal moves - game over
    ; Check if checkmate or stalemate
    CALL    is_checkmate
    BNZ     ai_checkmate

    ; Stalemate
    MOVLW   STATUS_STALEMATE
    MOVWF   game_status
    RETURN

ai_checkmate:
    MOVLW   STATUS_CHECKMATE
    MOVWF   game_status
    RETURN

; ============================================================================
; Include all module files
; ============================================================================
    #include "board.asm"
    #include "uart.asm"
    #include "movegen.asm"
    #include "makemove.asm"
    #include "check.asm"
    #include "evaluate.asm"
    #include "ai_level1.asm"
    #include "ai_level2.asm"
    #include "ai_level3.asm"
    #include "display.asm"
    #include "parser.asm"

; ============================================================================
; End of Program
; ============================================================================
    END
