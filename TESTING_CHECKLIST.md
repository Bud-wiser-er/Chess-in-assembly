# Testing Checklist for PIC18F45K22 Chess Engine

## Pre-Testing Setup
- [ ] Hardware correctly assembled
- [ ] Power supply verified (3.3V or 5V)
- [ ] UART connections verified (RX/TX not swapped)
- [ ] Terminal emulator configured (9600 baud, 8N1)
- [ ] Device programmed with latest hex file

---

## Unit Tests

### Board Representation Tests
- [ ] `test_board_init()` - Board initializes to correct starting position
  - [ ] White pieces on rank 1 correct
  - [ ] White pawns on rank 2 correct
  - [ ] Black pieces on rank 8 correct
  - [ ] Black pawns on rank 7 correct
  - [ ] Empty squares in middle (ranks 3-6) correct

- [ ] `test_get_set_piece()` - Piece placement/retrieval works
  - [ ] Can set piece on empty square
  - [ ] Can retrieve piece from square
  - [ ] Can clear square
  - [ ] King position cache updated correctly

- [ ] `test_algebraic()` - Algebraic notation conversion
  - [ ] e2 --> square 12 (correct)
  - [ ] e4 --> square 28 (correct)
  - [ ] a1 --> square 0 (correct)
  - [ ] h8 --> square 63 (correct)
  - [ ] Reverse conversion works
  - [ ] Invalid notation rejected

- [ ] `test_piece_to_char()` - Piece character conversion
  - [ ] White pieces --> Uppercase letters
  - [ ] Black pieces --> Lowercase letters
  - [ ] Empty squares --> Space
  - [ ] All piece types correct

### Move Generation Tests
- [ ] **Pawn moves**:
  - [ ] Single push from starting position
  - [ ] Double push from rank 2 (white) / rank 7 (black)
  - [ ] Captures (diagonal)
  - [ ] En passant captures
  - [ ] Promotion (all 4 pieces: Q, R, B, N)
  - [ ] Blocked by pieces

- [ ] **Knight moves**:
  - [ ] All 8 L-shaped moves generated
  - [ ] Can jump over pieces
  - [ ] Boundary checking (doesn't wrap around board)
  - [ ] Captures enemy pieces
  - [ ] Doesn't capture own pieces

- [ ] **Bishop moves**:
  - [ ] Diagonal movement (all 4 directions)
  - [ ] Blocked by pieces (doesn't jump)
  - [ ] Captures enemy pieces
  - [ ] Stops at board edge

- [ ] **Rook moves**:
  - [ ] Orthogonal movement (all 4 directions)
  - [ ] Blocked by pieces
  - [ ] Captures enemy pieces
  - [ ] Full rank/file movement

- [ ] **Queen moves**:
  - [ ] Combines bishop and rook movement
  - [ ] All 8 directions
  - [ ] Captures work correctly

- [ ] **King moves**:
  - [ ] One square in all 8 directions
  - [ ] Castling kingside (when legal)
  - [ ] Castling queenside (when legal)
  - [ ] Cannot castle through check
  - [ ] Cannot castle when in check
  - [ ] Cannot castle after king moved
  - [ ] Cannot castle after rook moved

### Perft Tests (Move Generation Validation)
Run from starting position:
- [ ] Perft(1) = 20 moves PASS
- [ ] Perft(2) = 400 moves PASS
- [ ] Perft(3) = 8,902 moves PASS

Known positions:
- [ ] Position 2 (Kiwipete): Perft(1) = 48 moves
- [ ] Position 3: Perft(1) = 14 moves

### Check Detection Tests
- [ ] Detects check from pawn
- [ ] Detects check from knight
- [ ] Detects check from bishop
- [ ] Detects check from rook
- [ ] Detects check from queen
- [ ] Detects check from king (adjacent)
- [ ] Detects double check
- [ ] No false positives (not in check when safe)

### Legal Move Validation Tests
- [ ] Filters moves that leave king in check
- [ ] Allows moves that block check
- [ ] Allows moves that capture checking piece
- [ ] Allows king to move out of check
- [ ] Handles discovered checks correctly

### Make/Unmake Move Tests
- [ ] Piece moves correctly
- [ ] Captured piece recorded
- [ ] Castling moves rook
- [ ] En passant removes correct pawn
- [ ] Promotion places correct piece
- [ ] Unmake restores board state
- [ ] Castling rights updated correctly
- [ ] En passant square updated correctly

---

## Integration Tests

### Complete Game Tests

#### Test Game 1: Scholar's Mate
```
1. e4 e5
2. Bc4 Nc6
3. Qh5 Nf6
4. Qxf7# (Checkmate)
```
- [ ] All moves legal
- [ ] Checkmate detected
- [ ] Game ends properly

#### Test Game 2: Fool's Mate
```
1. f3 e5
2. g4 Qh4# (Checkmate)
```
- [ ] Fastest checkmate works
- [ ] Checkmate detected on move 2

#### Test Game 3: Castling Test
```
1. e4 e5
2. Nf3 Nc6
3. Bc4 Bc5
4. O-O (Kingside castle)
```
- [ ] Setup allows castling
- [ ] Castling executes correctly
- [ ] King and rook move properly
- [ ] Castling rights updated

#### Test Game 4: En Passant
```
1. e4 d5
2. e5 f5
3. exf6 (en passant)
```
- [ ] En passant opportunity detected
- [ ] En passant capture works
- [ ] Correct pawn removed

#### Test Game 5: Promotion
```
Set up position with white pawn on e7
1. exd8=Q
```
- [ ] Promotion to Queen works
- [ ] Promotion to Rook works
- [ ] Promotion to Bishop works
- [ ] Promotion to Knight works
- [ ] Capture + promotion works

### Stalemate Tests
Set up stalemate positions and verify:
- [ ] King not in check
- [ ] No legal moves available
- [ ] Game ends in draw
- [ ] "Stalemate" message displayed

---

## AI Testing

### Level 1 (Random AI)
- [ ] Makes legal moves only
- [ ] Response time < 1 second
- [ ] Different moves each game (randomness works)
- [ ] Doesn't crash on complex positions
- [ ] Handles all piece types

### Level 2 (Evaluation AI)
- [ ] Makes sensible moves
- [ ] Captures valuable pieces when possible
- [ ] Doesn't hang pieces unnecessarily
- [ ] Response time < 5 seconds
- [ ] Shows some positional understanding
- [ ] Prefers center control

### Level 3 (Minimax AI)
- [ ] Finds simple tactics (forks, pins)
- [ ] Looks ahead 2-3 moves
- [ ] Avoids blunders
- [ ] Response time < 30 seconds
- [ ] Plays stronger than Level 2
- [ ] Handles complex positions

### AI Comparison
Play same position with all levels:
- [ ] Level 3 finds best move
- [ ] Level 2 finds reasonable move
- [ ] Level 1 makes random move
- [ ] Clear strength difference

---

## UART Communication Tests

### Basic Communication
- [ ] Welcome message displays correctly
- [ ] Board displays correctly
- [ ] Piece symbols correct (uppercase/lowercase)
- [ ] Algebraic notation correct (a-h, 1-8)
- [ ] No garbled characters
- [ ] Line breaks correct

### Command Parsing
- [ ] `NEW 1` starts new game, level 1
- [ ] `NEW 2` starts new game, level 2
- [ ] `NEW 3` starts new game, level 3
- [ ] `SHOW` displays current board
- [ ] `LEVEL 1/2/3` changes AI difficulty
- [ ] `MOVE e2e4` makes pawn move
- [ ] `MOVE g1f3` makes knight move
- [ ] `MOVE e7e8Q` promotes to queen
- [ ] Invalid commands show error
- [ ] Case insensitive (NEW vs new)

### Error Handling
- [ ] Illegal moves show "Illegal move."
- [ ] Invalid commands show "Error."
- [ ] Invalid square names rejected
- [ ] Out-of-bounds moves rejected

---

## System Integration Tests

### Power-On Sequence
- [ ] System initializes correctly
- [ ] Welcome message appears
- [ ] Board in starting position
- [ ] Ready for input

### Game Flow
- [ ] Human (White) moves first
- [ ] AI (Black) responds automatically
- [ ] Turns alternate correctly
- [ ] Board updates after each move
- [ ] Status messages appear (Check, Checkmate, etc.)

### Edge Cases
- [ ] Very long game (> 50 moves)
- [ ] Many pieces on board
- [ ] Few pieces on board
- [ ] Forced sequence (only one legal move)
- [ ] No legal moves (checkmate/stalemate)

---

## Performance Tests

### Memory Usage
- [ ] Program size < 32 KB (fits in flash)
- [ ] RAM usage < 1536 bytes
- [ ] No stack overflow
- [ ] No memory corruption

### Response Times
Measure with Timer1:
- [ ] Board initialization: < 100ms
- [ ] Move generation: < 500ms
- [ ] Position evaluation: < 100ms
- [ ] Level 1 move: < 1s
- [ ] Level 2 move: < 5s
- [ ] Level 3 move: < 30s

### Stress Tests
- [ ] Generate moves 100 times from same position (consistency)
- [ ] Play 10 complete games (stability)
- [ ] Test all 64 starting squares for each piece type
- [ ] Maximum legal moves position (~218 moves)

---

## Hardware Tests (with actual PIC18F45K22)

### Programming
- [ ] Device programs successfully
- [ ] Verify succeeds
- [ ] Device runs after programming
- [ ] Configuration bits correct

### UART Hardware
- [ ] Baud rate accurate (9600 baud)
- [ ] No framing errors
- [ ] No overrun errors
- [ ] Reliable communication
- [ ] Works with different USB-Serial adapters

### Power
- [ ] Works at 3.3V
- [ ] Works at 5V
- [ ] Stable operation
- [ ] No brown-out resets

### Timing
- [ ] Internal oscillator stable (16 MHz)
- [ ] Timer1 functioning (for random)
- [ ] Timing delays accurate

---

## Regression Tests
After any code changes, re-run:
- [ ] Perft tests (move generation validation)
- [ ] Scholar's Mate test game
- [ ] All three AI levels
- [ ] UART communication
- [ ] Memory usage check

---

## Final Acceptance Tests

### Functional
- [ ] Can play complete game from start to checkmate
- [ ] All chess rules implemented correctly
- [ ] All three AI levels work
- [ ] No crashes or hangs
- [ ] Clean exit conditions (checkmate, stalemate)

### Quality
- [ ] Code well-commented
- [ ] No compiler warnings
- [ ] Documentation complete
- [ ] README accurate
- [ ] USER_MANUAL clear

### Performance
- [ ] Meets all response time requirements
- [ ] Fits in memory constraints
- [ ] Stable for extended operation
- [ ] Reliable UART communication

---

## Test Results Log

### Test Date: ________________

| Test Category | Pass | Fail | Notes |
|---------------|------|------|-------|
| Board Representation | | | |
| Move Generation | | | |
| Perft Validation | | | |
| Check Detection | | | |
| Make/Unmake Moves | | | |
| Complete Games | | | |
| AI Level 1 | | | |
| AI Level 2 | | | |
| AI Level 3 | | | |
| UART Communication | | | |
| Command Parsing | | | |
| Memory Usage | | | |
| Performance | | | |
| Hardware Tests | | | |

### Overall Result: PASS  FAIL

### Tester Signature: _______________________

### Notes and Issues:
```
[Record any issues found, workarounds, or observations]
```

---

## Automated Test Script (Pseudo-code)

```python
# Example test automation for terminal-based testing

import serial
import time

def test_new_game():
    send_command("NEW 2")
    response = read_until_prompt()
    assert "8 |r|n|b|q|k|b|n|r|" in response
    assert "1 |R|N|B|Q|K|B|N|R|" in response
    print("PASS New game test passed")

def test_move():
    send_command("MOVE e2e4")
    response = read_until_prompt()
    assert "BLACK:" in response
    print("PASS Move test passed")

def test_scholars_mate():
    send_command("NEW 1")  # Use level 1 for predictable testing
    moves = [
        ("MOVE e2e4", "e5"),
        ("MOVE f1c4", "Nc6"),
        ("MOVE d1h5", "Nf6"),
        ("MOVE h5f7", "Checkmate")
    ]
    for white_move, expected in moves:
        send_command(white_move)
        response = read_until_prompt()
        # Verify expected patterns
    print("PASS Scholar's Mate test passed")

# Run all tests
run_all_tests()
```

---

**Testing is Critical. Do not skip steps.** 
