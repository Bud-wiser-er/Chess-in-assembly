# Chess Engine for PIC18F45K22 - Systems Engineering Design Document

## 1. REQUIREMENTS ANALYSIS

### 1.1 Functional Requirements
- **FR-001**: System shall implement complete chess rules (move validation, check, checkmate, stalemate)
- **FR-002**: System shall support castling (kingside and queenside)
- **FR-003**: System shall support en passant captures
- **FR-004**: System shall support pawn promotion
- **FR-005**: System shall detect check, checkmate, and stalemate conditions
- **FR-006**: System shall implement three AI difficulty levels:
  - **Level 1 (Easy)**: Random legal move selection
  - **Level 2 (Medium)**: Basic position evaluation (material count + piece-square tables)
  - **Level 3 (Hard)**: Minimax with alpha-beta pruning (depth 2-3 ply)
- **FR-007**: System shall accept human player moves via serial interface
- **FR-008**: System shall output board state and moves via serial interface
- **FR-009**: System shall validate all input moves for legality

### 1.2 Non-Functional Requirements
- **NFR-001**: Response time for Level 1: < 1 second
- **NFR-002**: Response time for Level 2: < 5 seconds
- **NFR-003**: Response time for Level 3: < 30 seconds
- **NFR-004**: System shall fit within 32KB program memory
- **NFR-005**: System shall operate within 1536 bytes of RAM
- **NFR-006**: System shall be reliable (no crashes, undefined behavior)
- **NFR-007**: Code shall be maintainable with clear commenting

## 2. HARDWARE CONSTRAINTS - PIC18F45K22

### 2.1 Critical Specifications
```
Microcontroller: PIC18F45K22
Architecture:    8-bit RISC
Program Memory:  32768 bytes (32 KB Flash)
Data Memory:     1536 bytes RAM
                 256 bytes EEPROM
Clock Speed:     Up to 64 MHz (16 MIPS with 4:1 clock ratio)
I/O Pins:        36 I/O pins
Timers:          4 timers (Timer0, Timer1, Timer2, Timer3)
UART:            2 USART modules
ADC:             14 channels, 10-bit
Instruction Set: 75 instructions
```

### 2.2 Memory Map
```
Program Memory:  0x000000 - 0x007FFF (32 KB)
Access RAM:      0x000 - 0x05F (96 bytes - fast access)
GPR Banks:       Bank 0-15 (1536 bytes total)
SFR:             Special Function Registers
Stack:           Hardware stack (31 levels)
```

### 2.3 Constraint Analysis

#### Memory Constraints (CRITICAL)
- **RAM**: Only 1536 bytes available for:
  - Chess board representation (64 squares)
  - Move generation buffer
  - Evaluation stack for minimax
  - Game state (castling rights, en passant, turn)
  - I/O buffers

- **Program Memory**: 32KB for entire program
  - Move generation code (~8-10 KB estimated)
  - Evaluation functions (~4-6 KB)
  - AI algorithms (~6-8 KB)
  - I/O handlers (~2 KB)
  - Utilities and tables (~4-6 KB)
  - **Total estimate**: 24-32 KB (TIGHT.)

#### Processing Constraints
- 8-bit operations only (16-bit requires multiple instructions)
- No hardware multiply/divide (must implement in software)
- Limited registers (WREG, STATUS, BSR, FSR0-2)
- Bank switching overhead for memory access
- No FPU (all integer arithmetic)

#### I/O Constraints
- Serial communication only (UART)
- Limited interrupt capabilities
- No display controller
- No keyboard controller

## 3. SYSTEM ARCHITECTURE

### 3.1 High-Level Architecture
```
”ERROR””””””””””””””””””””””””””””””””””””””””””””””[ ]
”‚         UART Communication Layer            ”‚
”‚   (Input Parser / Output Formatter)         ”‚
”””””””””””””””””””¬”””””””””””””””””””””””””””””[ ]
                 ”‚
”ERROR”””””””””””””””””´”””””””””””””””””””””””””””””[ ]
”‚          Game Controller                    ”‚
”‚  (Main Loop, Turn Management, UI)           ”‚
”””””””¬”””””””””””””””””””””””””””””””¬””””””””””[ ]
     ”‚                              ”‚
”ERROR”””””´””””””””””””””[ ]   ”ERROR”””””””””””””´””””””””””[ ]
”‚  Chess Rules     ”‚   ”‚   AI Engine          ”‚
”‚  Engine          ”‚   ”‚                      ”‚
”‚                  ”‚   ”‚  ”ERROR””””””””””””””””””[ ] ”‚
”‚ - Move Generator ”‚   ”‚  ”‚ Level 1: Random ”‚ ”‚
”‚ - Move Validator ”‚   ”‚  ”‚ Level 2: Eval   ”‚ ”‚
”‚ - Check Detector ”‚   ”‚  ”‚ Level 3: Minimax”‚ ”‚
”‚ - Special Moves  ”‚   ”‚  ””””””””””””””””””””[ ] ”‚
”””””””””””””””””””””[ ]   ”””””””””””””””””””””””””[ ]
         ”‚
”ERROR”””””””””´””””””””””””””””””””””””””””””””””””””[ ]
”‚        Board Representation                  ”‚
”‚  (Memory-efficient data structures)          ”‚
”””””””””””””””””””””””””””””””””””””””””””””””””[ ]
```

### 3.2 Module Breakdown

#### Module 1: Board Representation
- **Responsibility**: Store and manipulate board state
- **Memory Usage**: ~100 bytes
- **Key Functions**:
  - Initialize board
  - Get/Set piece at square
  - Check square occupancy

#### Module 2: Move Generation
- **Responsibility**: Generate all legal moves for current position
- **Memory Usage**: ~300 bytes (move buffer)
- **Key Functions**:
  - Generate pseudo-legal moves
  - Filter illegal moves (leaves king in check)
  - Special move generation (castling, en passant)

#### Module 3: Move Validation
- **Responsibility**: Validate move legality
- **Memory Usage**: ~50 bytes
- **Key Functions**:
  - Check if move is in legal move list
  - Validate move format

#### Module 4: Position Evaluation
- **Responsibility**: Evaluate position strength
- **Memory Usage**: ~100 bytes
- **Key Functions**:
  - Material counting
  - Piece-square table lookup
  - Simple mobility evaluation

#### Module 5: AI Engine
- **Responsibility**: Select best move based on difficulty
- **Memory Usage**: ~400 bytes (search stack)
- **Key Functions**:
  - Level 1: Random selection
  - Level 2: Static evaluation comparison
  - Level 3: Minimax with alpha-beta (2-3 ply)

#### Module 6: UART Communication
- **Responsibility**: Handle serial I/O
- **Memory Usage**: ~100 bytes (buffers)
- **Key Functions**:
  - Parse input commands
  - Format output messages
  - Board display

## 4. DATA STRUCTURE DESIGN

### 4.1 Board Representation (Mailbox)

**Choice Rationale**: Given RAM constraints, we need the most compact representation that still allows reasonable access speed.

**Options Considered**:
1. — **Bitboards** (8 bytes Ã— 12 piece types = 96 bytes)
   - Pros: Fast move generation
   - Cons: Requires 64-bit operations on 8-bit MCU (VERY expensive)

2. PASS **Mailbox (8Ã—8 array)** (64 bytes + metadata)
   - Pros: Simple, direct access, 8-bit friendly
   - Cons: Slower iteration
   - **SELECTED**: Best fit for 8-bit architecture

3. — **0x88 Board** (128 bytes)
   - Pros: Fast boundary checking
   - Cons: Wastes 50% of memory

**Implementation**:
```
Board Array: 64 bytes (one byte per square)
Encoding:
  Bits 7-4: Piece type
    0000 = Empty
    0001 = Pawn
    0010 = Knight
    0011 = Bishop
    0100 = Rook
    0101 = Queen
    0110 = King
  Bit 3: Color (0=White, 1=Black)
  Bits 2-0: Reserved/flags

Example: 0x13 = White Knight (0001 0011)
         0x1B = Black Knight (0001 1011)
```

### 4.2 Game State (16 bytes)
```
Byte 0:    Current turn (0=White, 1=Black)
Byte 1:    Castling rights (bits: K Q k q)
Byte 2:    En passant target square (0xFF if none)
Byte 3:    Halfmove clock (for 50-move rule)
Bytes 4-5: Fullmove number (16-bit)
Byte 6:    Game status (0=ongoing, 1=checkmate, 2=stalemate, 3=draw)
Byte 7:    Selected AI level (1, 2, or 3)
Bytes 8-9: White king position
Bytes 10-11: Black king position
Bytes 12-15: Reserved
```

### 4.3 Move Representation (4 bytes per move)
```
Byte 0: From square (0-63)
Byte 1: To square (0-63)
Byte 2: Move flags
  Bit 7: Capture
  Bit 6: Promotion
  Bit 5: Castling
  Bit 4: En passant
  Bits 3-2: Promotion piece (0=Q, 1=R, 2=B, 3=N)
  Bits 1-0: Reserved
Byte 3: Captured piece (for undo)
```

### 4.4 Move List Buffer (300 bytes)
```
Max legal moves in any position: ~218 (known maximum)
Typical: 30-40 moves
Buffer: 70 moves Ã— 4 bytes = 280 bytes (safe margin)
```

### 4.5 Memory Budget Summary
```
Board:                64 bytes
Game State:           16 bytes
Move List Buffer:    280 bytes
Evaluation Stack:    200 bytes (for minimax, 50 nodes Ã— 4 bytes)
UART RX Buffer:       64 bytes
UART TX Buffer:      128 bytes
Working Memory:      100 bytes
Reserve:             684 bytes (for future features/safety)
””””””””””””””””””””””””””””
TOTAL:              1536 bytes (100% of RAM)
```

## 5. I/O INTERFACE DESIGN

### 5.1 Serial Communication Protocol

**UART Configuration**:
- Baud Rate: 9600 bps (reliable, commonly supported)
- Data Bits: 8
- Parity: None
- Stop Bits: 1
- Flow Control: None

### 5.2 Command Protocol

**Human Input Commands**:
```
1. MOVE <from><to>[promotion]
   Example: "MOVE e2e4"      (pawn advance)
            "MOVE e7e8Q"     (pawn promotion to queen)
            "MOVE e1g1"      (castling kingside)

2. NEW [level]
   Example: "NEW 1"          (start new game, AI level 1)
            "NEW 3"          (start new game, AI level 3)

3. SHOW
   Example: "SHOW"           (display current board)

4. UNDO
   Example: "UNDO"           (undo last move pair)

5. LEVEL <n>
   Example: "LEVEL 2"        (change AI difficulty)
```

**System Output**:
```
1. Board Display (ASCII art)
   8 |r|n|b|q|k|b|n|r|
   7 |p|p|p|p|p|p|p|p|
   6 | | | | | | | | |
   5 | | | | | | | | |
   4 | | | | | | | | |
   3 | | | | | | | | |
   2 |P|P|P|P|P|P|P|P|
   1 |R|N|B|Q|K|B|N|R|
      a b c d e f g h

2. Move Notifications
   "WHITE: e2-e4"
   "BLACK: e7-e5"

3. Status Messages
   "Check."
   "Checkmate. White wins."
   "Stalemate. Draw."
   "Illegal move."

4. AI Thinking
   "Thinking... (Level 3)"
   "Move: Nf3"
```

## 6. ALGORITHM DESIGN

### 6.1 Level 1: Random Moves
```
Algorithm:
1. Generate all legal moves
2. Use Timer1 as entropy source
3. Select random index: (TMR1L) % move_count
4. Return selected move

Complexity: O(n) where n = number of legal moves
Estimated Time: < 1 second
```

### 6.2 Level 2: Basic Evaluation
```
Algorithm:
1. Generate all legal moves
2. For each move:
   a. Make move
   b. Evaluate position using:
      - Material count (P=1, N=3, B=3, R=5, Q=9)
      - Piece-square tables (positional bonuses)
   c. Undo move
   d. Store evaluation score
3. Select move with best score

Complexity: O(n) where n = number of legal moves
Estimated Time: < 5 seconds (40 moves Ã— 100ms evaluation)
```

### 6.3 Level 3: Minimax with Alpha-Beta Pruning
```
Algorithm: Minimax with Alpha-Beta (2-3 ply depth)

function minimax(depth, alpha, beta, maximizing):
    if depth == 0 or game_over:
        return evaluate_position()

    if maximizing:
        max_eval = -INFINITY
        for each legal_move:
            make_move(legal_move)
            eval = minimax(depth-1, alpha, beta, False)
            undo_move()
            max_eval = max(max_eval, eval)
            alpha = max(alpha, eval)
            if beta <= alpha:
                break  // Beta cutoff
        return max_eval
    else:
        min_eval = +INFINITY
        for each legal_move:
            make_move(legal_move)
            eval = minimax(depth-1, alpha, beta, True)
            undo_move()
            min_eval = min(min_eval, eval)
            beta = min(beta, eval)
            if beta <= alpha:
                break  // Alpha cutoff
        return min_eval

Complexity: O(b^d) where b=branching factor (~35), d=depth (2-3)
Worst case: 35^3 = 42,875 positions
With alpha-beta: ~6,000 positions (assuming 85% cutoff)
Estimated Time: < 30 seconds
```

### 6.4 Move Generation Algorithm
```
For each square on board:
    piece = board[square]
    if piece.color == current_turn:
        switch piece.type:
            case PAWN:
                generate_pawn_moves(square)
            case KNIGHT:
                generate_knight_moves(square)
            case BISHOP:
                generate_sliding_moves(square, diagonal_directions)
            case ROOK:
                generate_sliding_moves(square, orthogonal_directions)
            case QUEEN:
                generate_sliding_moves(square, all_directions)
            case KING:
                generate_king_moves(square)
                generate_castling_moves(square)

Filter out moves that leave king in check
```

## 7. TESTING STRATEGY

### 7.1 Unit Tests
- **Test 1**: Board initialization
- **Test 2**: Piece placement and retrieval
- **Test 3**: Move generation for each piece type
- **Test 4**: Check detection
- **Test 5**: Checkmate detection
- **Test 6**: Stalemate detection
- **Test 7**: Castling validation (all cases)
- **Test 8**: En passant capture
- **Test 9**: Pawn promotion
- **Test 10**: Move make/undo

### 7.2 Integration Tests
- **Test 11**: Complete game playthrough (e4 e5, Nf3 Nc6, ...)
- **Test 12**: Scholar's Mate (quick checkmate)
- **Test 13**: Fool's Mate (fastest checkmate)
- **Test 14**: Castling in actual game
- **Test 15**: En passant in actual game

### 7.3 Performance Tests
- **Test 16**: Level 1 response time < 1s
- **Test 17**: Level 2 response time < 5s
- **Test 18**: Level 3 response time < 30s
- **Test 19**: Memory usage < 1536 bytes
- **Test 20**: Program size < 32KB

### 7.4 Perft Testing (Move Generation Validation)
```
Perft(depth) = count of leaf nodes at depth from position
Used to validate move generation is correct

Initial Position:
Perft(1) = 20     (20 possible first moves)
Perft(2) = 400    (400 positions after 2 ply)
Perft(3) = 8,902  (8,902 positions after 3 ply)
Perft(4) = 197,281
```

## 8. IMPLEMENTATION PLAN

### Phase 1: Core Foundation (Week 1)
- Setup development environment (MPLAB X IDE, XC8/ASM)
- Create project structure
- Implement board representation
- Implement basic UART I/O
- Test: Board initialization and display

### Phase 2: Move Generation (Week 2)
- Implement pseudo-legal move generation
- Implement check detection
- Implement legal move filtering
- Test: Perft(3) validation

### Phase 3: Game Logic (Week 3)
- Implement move making/unmaking
- Implement special moves (castling, en passant, promotion)
- Implement checkmate/stalemate detection
- Test: Complete games with manual moves

### Phase 4: AI Level 1 (Week 4)
- Implement random move selection
- Integrate with game loop
- Test: AI vs AI games

### Phase 5: AI Level 2 (Week 5)
- Implement evaluation function
- Implement piece-square tables
- Implement static evaluation-based move selection
- Test: AI plays sensible moves

### Phase 6: AI Level 3 (Week 6)
- Implement minimax algorithm
- Implement alpha-beta pruning
- Optimize search depth
- Test: AI plays strong moves

### Phase 7: Optimization & Testing (Week 7-8)
- Optimize critical paths
- Memory optimization
- Comprehensive testing
- Bug fixes

## 9. RISK ANALYSIS

### Risk 1: Insufficient Program Memory
- **Probability**: Medium
- **Impact**: High
- **Mitigation**:
  - Aggressive code optimization
  - Table compression
  - Reduce Level 3 search depth if needed

### Risk 2: Insufficient RAM
- **Probability**: Low-Medium
- **Impact**: High
- **Mitigation**:
  - Reduce move buffer size
  - Reduce minimax stack depth
  - Use EEPROM for static tables

### Risk 3: Performance Too Slow
- **Probability**: Medium
- **Impact**: Medium
- **Mitigation**:
  - Optimize inner loops
  - Use lookup tables
  - Reduce Level 3 search depth

### Risk 4: Bugs in Move Generation
- **Probability**: Medium
- **Impact**: High
- **Mitigation**:
  - Extensive perft testing
  - Manual testing of edge cases
  - Code review

### Risk 5: UART Communication Issues
- **Probability**: Low
- **Impact**: Medium
- **Mitigation**:
  - Thorough testing with terminal emulator
  - Add timeout handling
  - Error detection/correction

## 10. DEVELOPMENT TOOLS

### Required Software
- **MPLAB X IDE**: Main development environment
- **MPASM/ASM30**: Assembler for PIC18
- **PICkit 3/4**: Hardware programmer/debugger
- **Terminal Emulator**: For UART testing (PuTTY, TeraTerm)
- **Simulator**: MPLAB SIM for testing without hardware

### Simulation Strategy
Since we may not have physical hardware:
- Use MPLAB SIM for instruction-level simulation
- Test UART with stimulus files
- Validate logic before hardware deployment

## 11. CODE STRUCTURE

```
chess-engine/
””” main.asm                 # Main program entry, initialization
””” board.asm                # Board representation and basic operations
””” movegen.asm              # Move generation engine
””” makemove.asm             # Move making/unmaking
””” check.asm                # Check, checkmate, stalemate detection
””” evaluate.asm             # Position evaluation
””” ai_level1.asm            # Random move AI
””” ai_level2.asm            # Static evaluation AI
””” ai_level3.asm            # Minimax AI
””” uart.asm                 # UART communication
””” parser.asm               # Command parsing
””” display.asm              # Board display formatting
””” utils.asm                # Utility functions
””” tables.asm               # Lookup tables (piece-square, etc.)
””” config.inc               # Configuration bits
””” definitions.inc          # Constants and macros
””” memory.inc               # Memory map definitions
””” tests/
”‚   ””” test_board.asm
”‚   ””” test_movegen.asm
”‚   ””” test_check.asm
”‚   ”””” perft.asm
”””” docs/
    ”””” DESIGN_DOCUMENT.md   # This file
```

## 12. FUTURE ENHANCEMENTS (Out of Scope)

- Opening book (requires EEPROM storage)
- Endgame tablebases (not feasible with memory constraints)
- Transposition table (would require significant RAM)
- Iterative deepening (would improve Level 3)
- Time management (basic version feasible)
- Move ordering (would improve alpha-beta efficiency)
- Quiescence search (would improve tactical awareness)

## 13. CONCLUSION

This chess engine represents the limits of what's achievable on an 8-bit microcontroller with severe resource constraints. The design prioritizes:

1. **Correctness**: All chess rules implemented properly
2. **Reliability**: No crashes or undefined behavior
3. **Feasibility**: Fits within memory constraints
4. **Playability**: Three distinct difficulty levels

The system uses proven algorithms (minimax with alpha-beta) adapted to work within the constraints of the PIC18F45K22. Success requires careful memory management, efficient algorithms, and extensive testing.

**Estimated Resource Usage**:
- Program Memory: ~28-30 KB (87-93% of 32 KB)
- Data Memory: ~1400-1500 bytes (91-97% of 1536 bytes)
- Development Time: 6-8 weeks for full implementation and testing

This is an aggressive but achievable project with proper planning and execution.
