; ============================================================================
; memory.inc - Memory Map and Variable Definitions
; Chess Engine Project
; Total RAM: 1536 bytes
; ============================================================================

; ============================================================================
; ACCESS RAM (0x000-0x05F) - 96 bytes, fast access, no banking
; ============================================================================
    CBLOCK  0x000

    ; Temporary working registers (16 bytes)
    temp1               ; General purpose temp
    temp2
    temp3
    temp4
    temp5
    temp6
    loop_count
    loop_count2
    delay_count
    delay_temp

    ; Current operation context (10 bytes)
    curr_square         ; Current square being processed
    curr_piece          ; Current piece being processed
    curr_from           ; Current move from square
    curr_to             ; Current move to square
    curr_flags          ; Current move flags
    curr_capture        ; Captured piece (for undo)

    ; FSR shadow registers (6 bytes)
    fsr0_save_l
    fsr0_save_h
    fsr1_save_l
    fsr1_save_h
    fsr2_save_l
    fsr2_save_h

    ENDC

; ============================================================================
; BANKED RAM - Game State and Data Structures
; ============================================================================
    CBLOCK  0x060

    ; ========================================================================
    ; BOARD REPRESENTATION (64 bytes)
    ; ========================================================================
    board:64            ; Chess board array (a1=0, b1=1, ..., h8=63)
                        ; Each byte encodes: [0000][color][piece_type]

    ; ========================================================================
    ; GAME STATE (32 bytes)
    ; ========================================================================
    game_turn           ; Current turn (0=White, 1=Black)
    castle_rights       ; Castling rights (bits: BQ BK WQ WK)
    enpassant_square    ; En passant target square (0xFF if none)
    halfmove_clock      ; Halfmove clock for 50-move rule
    fullmove_lo         ; Fullmove number (low byte)
    fullmove_hi         ; Fullmove number (high byte)
    game_status         ; Game status (0=ongoing, 1=checkmate, etc.)
    ai_level            ; Selected AI level (1, 2, or 3)
    white_king_sq       ; White king position (for quick access)
    black_king_sq       ; Black king position

    ; Last move (for display and undo)
    last_from
    last_to
    last_flags
    last_capture

    ; Check flags
    in_check            ; Flag: is current side in check?
    check_count         ; Number of pieces giving check

    ; Reserved for future use
    game_state_reserved:16

    ; ========================================================================
    ; MOVE LIST BUFFER (280 bytes = 70 moves × 4 bytes)
    ; ========================================================================
    move_list:280       ; Buffer for generated moves
                        ; Each move: [from][to][flags][captured]
    move_count          ; Number of moves in list
    move_index          ; Current move index (for iteration)

    ; ========================================================================
    ; UART BUFFERS (192 bytes)
    ; ========================================================================
    uart_rx_buffer:64   ; UART receive buffer
    uart_tx_buffer:128  ; UART transmit buffer
    uart_rx_head        ; RX buffer head pointer
    uart_rx_tail        ; RX buffer tail pointer
    uart_tx_head        ; TX buffer head pointer
    uart_tx_tail        ; TX buffer tail pointer

    ; Command parsing
    cmd_buffer:32       ; Command parsing buffer
    cmd_length          ; Command length
    cmd_arg1            ; First argument
    cmd_arg2            ; Second argument
    cmd_arg3            ; Third argument
    cmd_arg4            ; Fourth argument

    ; ========================================================================
    ; EVALUATION DATA (120 bytes)
    ; ========================================================================
    eval_score_lo       ; Current evaluation score (low byte)
    eval_score_hi       ; Current evaluation score (high byte)
    eval_best_lo        ; Best evaluation found
    eval_best_hi
    eval_alpha_lo       ; Alpha for alpha-beta pruning
    eval_alpha_hi
    eval_beta_lo        ; Beta for alpha-beta pruning
    eval_beta_hi

    ; Material count cache
    white_material_lo
    white_material_hi
    black_material_lo
    black_material_hi

    ; Working space for evaluation
    eval_work:100

    ; ========================================================================
    ; MINIMAX SEARCH STACK (200 bytes = 50 nodes × 4 bytes)
    ; ========================================================================
    minimax_stack:200   ; Stack for minimax search
                        ; Each entry: [from][to][flags][captured]
    minimax_depth       ; Current search depth
    minimax_max_depth   ; Maximum search depth
    minimax_ply         ; Current ply in search

    ; Best move tracking
    best_move_from
    best_move_to
    best_move_flags
    best_move_capture

    ; ========================================================================
    ; MOVE GENERATION WORKING SPACE (100 bytes)
    ; ========================================================================
    movegen_square      ; Square being processed
    movegen_piece       ; Piece being processed
    movegen_target      ; Target square
    movegen_direction   ; Current direction offset
    movegen_temp:20     ; Temporary space for move generation

    ; Sliding piece generation
    slide_square
    slide_file
    slide_rank
    slide_target_file
    slide_target_rank

    ; Attack detection
    attack_square       ; Square to check for attacks
    attack_color        ; Color of attacking pieces
    attack_found        ; Flag: attack found

    ; Legal move filtering
    legal_temp_from
    legal_temp_to
    legal_temp_flags
    legal_temp_capture
    legal_move_count

    movegen_work:50

    ; ========================================================================
    ; PIECE-SQUARE TABLES (will be in program memory, pointers here)
    ; ========================================================================
    pst_ptr_lo          ; Pointer to current PST (low byte)
    pst_ptr_hi          ; Pointer to current PST (high byte)

    ; ========================================================================
    ; DISPLAY AND OUTPUT (80 bytes)
    ; ========================================================================
    disp_rank           ; Current rank for display
    disp_file           ; Current file for display
    disp_square         ; Current square for display
    disp_piece          ; Current piece for display
    disp_char           ; Character to display
    disp_buffer:64      ; Display formatting buffer
    disp_index

    ; ========================================================================
    ; RANDOM NUMBER GENERATOR (8 bytes)
    ; ========================================================================
    rand_state_0        ; LFSR state bytes
    rand_state_1
    rand_state_2
    rand_state_3

    ; ========================================================================
    ; STACK POINTER (for software stack operations)
    ; ========================================================================
    stack_ptr_lo
    stack_ptr_hi

    ; ========================================================================
    ; WORKING MEMORY / RESERVE (Remaining space)
    ; ========================================================================
    work_buffer:100     ; General working buffer

    ENDC

; ============================================================================
; MEMORY USAGE SUMMARY
; ============================================================================
; Access RAM:              96 bytes
; Board:                   64 bytes
; Game State:              32 bytes
; Move List:              282 bytes (280 + count + index)
; UART Buffers:           192 bytes
; Command Buffer:          37 bytes
; Evaluation:             120 bytes
; Minimax Stack:          203 bytes
; Move Generation:        100 bytes
; Display:                 80 bytes
; Random:                   4 bytes
; Stack pointers:           2 bytes
; Work buffer:            100 bytes
; ────────────────────────────────
; ESTIMATED TOTAL:       ~1312 bytes (85% of 1536 bytes)
; RESERVE:                ~224 bytes

; ============================================================================
; SPECIAL FUNCTION REGISTER ADDRESSES (commonly used)
; ============================================================================
; Already defined in p18f45k22.inc, but listed here for reference:
; WREG      - Working register
; STATUS    - Status register
; BSR       - Bank Select Register
; FSR0L/H   - File Select Register 0
; FSR1L/H   - File Select Register 1
; FSR2L/H   - File Select Register 2
; INDF0     - Indirect access through FSR0
; INDF1     - Indirect access through FSR1
; INDF2     - Indirect access through FSR2
; POSTINC0  - FSR0 with post-increment
; POSTINC1  - FSR1 with post-increment
; POSTINC2  - FSR2 with post-increment
; POSTDEC0  - FSR0 with post-decrement
; POSTDEC1  - FSR1 with post-decrement
; POSTDEC2  - FSR2 with post-decrement

; ============================================================================
; End of memory.inc
; ============================================================================
