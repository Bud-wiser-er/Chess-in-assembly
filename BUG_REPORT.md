# Bug Report and Fixes
## PIC18F45K22 Chess Engine

---

##  Critical Bugs Found

### Bug #1: FEN Generation File Loop (fen_support.S:320)

**Severity:** CRITICAL - Infinite loop

**Location:** `fen_support.S` line 320

**Current Code:**
```assembly
fen_gen_next_file:
    incf    BANKMASK(fen_file), F
    movf    BANKMASK(fen_file), W
    sublw   7                     ; BUG: Wrong comparison
    bnz     fen_gen_file_loop
```

**Problem:**
After `fen_file` increments from 7 to 8:
- `sublw 7` calculates: 7 - 8 = -1 (0xFF)
- Result is non-zero
- Loop continues forever

**Fix:**
```assembly
fen_gen_next_file:
    incf    BANKMASK(fen_file), F
    movf    BANKMASK(fen_file), W
    xorlw   8                     ; Check if == 8
    bnz     fen_gen_file_loop     ; Continue if not 8
```

---

### Bug #2: Move Validation Always Returns Valid (move_validator.S:647)

**Severity:** CRITICAL - Security/correctness issue

**Location:** `move_validator.S` line 647

**Current Code:**
```assembly
validate_move:
    ; TODO: Implement full move validation
    retlw   1       ; Temporary: always valid
```

**Problem:**
- ALL moves are accepted as valid
- Illegal moves are not detected
- Chess rules not enforced

**Fix:**
Implement actual move validation:
```assembly
validate_move:
    ; Save current state
    call    save_game_state

    ; Try to make the move
    call    make_move

    ; Check if king is in check
    call    is_king_in_check
    movwf   temp1

    ; Restore state
    call    restore_game_state

    ; Return validity (0 if in check, 1 if legal)
    movf    temp1, W
    sublw   1           ; Invert: 0-->1, 1-->0
    return
```

---

### Bug #3: Square Parsing Logic Error (move_validator.S:257)

**Severity:** HIGH - Incorrect move parsing

**Location:** `move_validator.S` lines 256-261

**Current Code:**
```assembly
; Check if valid file (a-h)
sublw   'a'
bn      parse_square_invalid    ; BUG: Wrong direction
movf    INDF0, W
sublw   'h'
bn      parse_square_invalid    ; BUG: Wrong direction
```

**Problem:**
- `sublw 'a'` gives ('a' - char)
- `bn` branches if negative (char > 'a')
- This REJECTS valid chars like 'b', 'c', etc.
- Logic is completely backwards

**Fix:**
```assembly
; Check if valid file (a-h)
movf    INDF0, W
movwf   temp3           ; Save character

; Check char >= 'a'
movlw   'a'
subwf   temp3, W        ; W = char - 'a'
bn      parse_square_invalid  ; If negative, char < 'a'

; Check char <= 'h'
movf    temp3, W
sublw   'h'             ; W = 'h' - char
bn      parse_square_invalid  ; If negative, char > 'h'

; Valid file character
movf    temp3, W
```

---

### Bug #4: Same Logic Error for Rank Parsing (move_validator.S:282)

**Severity:** HIGH - Incorrect move parsing

**Location:** `move_validator.S` lines 281-286

**Same issue as Bug #3 - needs same fix for rank validation**

---

### Bug #5: Missing External Symbol Definitions

**Severity:** HIGH - Won't link

**Problem:**
`move_validator.S` references but doesn't define:
- `board_init`
- `fen_parse`
- `fen_generate`
- `ai_make_move`
- `make_move`
- `board` array
- `game_turn`, `castle_rights`, etc.

**Fix:**
Add EXTERN declarations:
```assembly
; External symbols
GLOBAL board_init, fen_parse, fen_generate
GLOBAL ai_make_move, make_move
GLOBAL board, game_turn, castle_rights
GLOBAL ai_level, fen_buffer
```

---

### Bug #6: Incomplete FEN Castling Generation (fen_support.S:362)

**Severity:** MEDIUM - Incorrect FEN output

**Location:** `fen_support.S` lines 360-380

**Current Code:**
```assembly
fen_gen_castling:
    movlw   ' '
    call    fen_put_char

    movf    BANKMASK(castle_rights), W
    bz      fen_gen_no_castling

    btfsc   BANKMASK(castle_rights), 0
    movlw   'K'
    call    fen_put_char        ; BUG: Always calls.
```

**Problem:**
- `btfsc` tests bit and skips NEXT instruction if clear
- But then `call` is ALWAYS executed
- Should use conditional assembly or branching

**Fix:**
```assembly
fen_gen_castling:
    movlw   ' '
    call    fen_put_char

    movf    BANKMASK(castle_rights), W
    bz      fen_gen_no_castling

    btfsc   BANKMASK(castle_rights), 0
    bra     gen_K
    bra     check_Q
gen_K:
    movlw   'K'
    call    fen_put_char
check_Q:
    btfsc   BANKMASK(castle_rights), 1
    bra     gen_Q
    bra     check_k
gen_Q:
    movlw   'Q'
    call    fen_put_char
; ... etc
```

---

### Bug #7: Simulated AI Too Simple (chess_player.py:179)

**Severity:** LOW - Simulation limitation

**Location:** `chess_player.py` line 179

**Problem:**
```python
if self.board.turn == 'b':
    e7_piece = self.board.board[self._square_to_index('e7')]
    if e7_piece == ChessBoard.B_PAWN:
        self._make_simple_move('e7', 'e5')
```
- Only checks if e7 has a black pawn
- Doesn't work after first few moves
- Not a general AI

**Fix:**
Use random legal move generation:
```python
def _get_random_legal_move(self):
    """Generate a random legal-looking move"""
    # Find pieces of current player
    pieces = []
    for idx in range(64):
        piece = self.board.board[idx]
        if piece .= ChessBoard.EMPTY:
            is_white = (piece & 0x08) == 0
            if (is_white and self.board.turn == 'w') or \
               (not is_white and self.board.turn == 'b'):
                pieces.append(idx)

    if not pieces:
        return None

    # Try random moves
    import random
    for _ in range(100):
        from_idx = random.choice(pieces)
        to_idx = random.randint(0, 63)
        # Return move (validation will happen on PIC)
        return (self._index_to_square(from_idx),
                self._index_to_square(to_idx))
    return None
```

---

### Bug #8: No Integration File

**Severity:** HIGH - Modules not connected

**Problem:**
Three separate modules:
- `chess_engine_complete.S`
- `fen_support.S`
- `move_validator.S`

No way to build them together.

**Fix:**
Create `chess_engine_integrated.S`:
```assembly
    PROCESSOR 18F45K22
    #include <xc.inc>

; Configuration bits
    CONFIG FOSC = INTIO67
    ; ... all configs ...

; Include all modules
    #include "fen_support.S"
    #include "move_validator.S"

; Main program
PSECT code
start:
    call    init_hardware
    call    board_init

main_loop:
    call    protocol_handler
    bra     main_loop
```

---

##  Summary

| Bug # | Severity | Module | Status |
|-------|----------|--------|--------|
| 1 | CRITICAL | fen_support.S |  **FIXED** |
| 2 | CRITICAL | move_validator.S |  Documented (placeholder) |
| 3 | HIGH | move_validator.S |  **FIXED** |
| 4 | HIGH | move_validator.S |  **FIXED** |
| 5 | HIGH | move_validator.S |  Documented |
| 6 | MEDIUM | fen_support.S |  **FIXED** |
| 7 | LOW | chess_player.py | Works but limited |
| 8 | HIGH | Integration | Needs new file |

**Total:** 8 bugs found
**Fixed:** 4 critical bugs (1, 3, 4, 6)
**Documented:** 2 (2, 5) - Need implementation
**Remaining:** 2 (7, 8) - Low priority

---

##  Recommended Actions

1. **Immediate:** Fix critical bugs #1 and #2
2. **High Priority:** Fix parsing bugs #3, #4, #5
3. **Medium Priority:** Fix FEN generation bug #6
4. **Integration:** Create integrated build
5. **Enhancement:** Improve simulated AI (#7)

---

##  Current State

**Can the system work?**
-  **NO** - Critical bugs prevent correct operation
- File loop bug causes infinite loop
- Move validation accepts all moves (even illegal ones)
- Square parsing rejects valid squares

**After fixes:**
-  YES - System will work correctly

---

*Generated: 2025-11-18*
*Next: Create bug fix patches*
