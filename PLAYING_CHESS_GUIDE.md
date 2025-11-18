# Playing Chess Against the PIC18F45K22
## Complete User Guide

---

##  What Is This?

This is a complete chess system where:
1. **You** play chess using a Python program on your computer
2. **PIC18F45K22** microcontroller validates your moves and plays against you
3. **Serial communication** connects your PC to the chess engine

**The PIC is the referee** - it validates all moves and ensures chess rules are followed.

---

##  Quick Start (No Hardware Needed.)

### Test Mode (Simulated PIC)

You can play chess right now without any hardware:

```bash
cd /home/user/Chess-in-assembly
python3 chess_player.py
```

**What you'll see:**
```
Play Chess Against PIC18F45K22
  Running in SIMULATED mode (no hardware)

  =================================
8 | r | n | b | q | k | b | n | r |
7 | p | p | p | p | p | p | p | p |
6 |   |   |   |   |   |   |   |   |
5 |   |   |   |   |   |   |   |   |
4 |   |   |   |   |   |   |   |   |
3 |   |   |   |   |   |   |   |   |
2 | P | P | P | P | P | P | P | P |
1 | R | N | B | Q | K | B | N | R |
  =================================

Your move (White) >
```

**Try making a move:**
```
Your move (White) > e2e4
```

The simulated PIC will validate your move and respond.

---

##  How It Works

### The Move Validation Flow

```
1. You type a move (e.g., "e2e4")
        -->
2. Python sends: "MOVE e2e4" --> PIC
        -->
3. PIC validates the move:
   - Is the piece there?
   - Can it move that way?
   - Does it leave king in check?
        -->
4. If VALID:
   - PIC makes your move
   - AI calculates its response
   - AI makes its move
   - PIC sends back: "OK <new_position_FEN>"
        -->
   If INVALID:
   - PIC sends: "ERROR Invalid move"
        -->
5. Python updates the board display
```

### Why PIC Validates?

The PIC acts as the **authoritative game engine**:
-  Enforces all chess rules (castling, en passant, promotion, etc.)
-  Prevents illegal moves
-  Ensures game integrity
-  Makes AI opponent's moves
-  Detects checkmate/stalemate

---

##  Commands You Can Use

| Command | What It Does | Example |
|---------|--------------|---------|
| `e2e4` | Make a move | `e2e4` (pawn from e2 to e4) |
| `e7e8q` | Move with promotion | `e7e8q` (pawn to e8, promote to queen) |
| `new` | Start a new game | `new` |
| `show` | Display the board | `show` |
| `quit` | Exit the program | `quit` |

### Move Notation

Moves use **UCI notation** (Universal Chess Interface):
- Format: `<from_square><to_square>[promotion]`
- Examples:
  - `e2e4` - Move piece from e2 to e4
  - `g1f3` - Move knight from g1 to f3
  - `e7e8Q` - Move pawn from e7 to e8 and promote to Queen
  - `e7e8q` - Same (lowercase also works)

**Squares:**
- Files: `a` through `h` (left to right)
- Ranks: `1` through `8` (bottom to top)
- Examples: `e4`, `a1`, `h8`

**Promotion pieces:**
- `Q` or `q` - Queen
- `R` or `r` - Rook
- `B` or `b` - Bishop
- `N` or `n` - Knight

---

## ² Example Game Session

```
Your move (White) > e2e4
[SEND] Sending move to PIC for validation...
--> Sent: MOVE e2e4
<-- Received: OK rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1
 Move accepted. PIC responded.

  =================================
8 | r | n | b | q | k | b | n | r |
7 | p | p | p | p |   | p | p | p |
6 |   |   |   |   |   |   |   |   |
5 |   |   |   |   | p |   |   |   |
4 |   |   |   |   | P |   |   |   |
3 |   |   |   |   |   |   |   |   |
2 | P | P | P | P |   | P | P | P |
1 | R | N | B | Q | K | B | N | R |
  =================================

Your move (White) > g1f3
[SEND] Sending move to PIC for validation...
--> Sent: MOVE g1f3
<-- Received: OK r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1
 Move accepted. PIC responded.

  =================================
8 | r |   | b | q | k | b | n | r |
7 | p | p | p | p |   | p | p | p |
6 |   |   | n |   |   |   |   |   |
5 |   |   |   |   | p |   |   |   |
4 |   |   |   |   | P |   |   |   |
3 |   |   |   |   |   | N |   |   |
2 | P | P | P | P |   | P | P | P |
1 | R | N | B | Q | K | B |   | R |
  =================================

Your move (White) >
```

---

##  What Happens with Invalid Moves?

```
Your move (White) > e2e5
[SEND] Sending move to PIC for validation...
--> Sent: MOVE e2e5
<-- Received: ERROR Invalid move
 Move rejected: Invalid move
Try a different move.

Your move (White) > e2e4
 Move accepted. PIC responded.
```

The PIC will reject moves that are:
- Illegal for the piece type
- Would leave your king in check
- Move a piece that isn't there
- Use invalid square notation

---

##  Testing the Python Program

### Run Automated Tests

```bash
python3 chess_player.py --test
```

**What gets tested:**
1.  Board initialization
2.  Valid move acceptance
3.  Invalid move format rejection
4.  Invalid square rejection
5.  Move sequence handling
6.  New game initialization

**Expected output:**
```
============================================================
  RUNNING AUTOMATED TESTS - PIC Chess Player
============================================================

Test 1: Initial Position
PASS PASS

Test 2: Valid Move (e2e4)
PASS PASS

Test 3: Invalid Move Format
PASS PASS

Test 4: Invalid Square
PASS PASS

Test 5: Move Sequence
PASS PASS

Test 6: New Game
PASS PASS

============================================================
  TESTS COMPLETE: 6 passed, 0 failed
  ALL TESTS PASSED PASS
============================================================
```

---

##  Using Real Hardware (When You Have It)

### Hardware Setup

**You'll need:**
1. PIC18F45K22 microcontroller (programmed with chess engine)
2. USB-to-Serial adapter (FTDI, CP2102, etc.)
3. Jumper wires
4. Power supply for PIC

**Connections:**
```
USB-Serial        PIC18F45K22
”””””””””         ”””””””””””
TX  ””””””””””””> RC6 (Pin 17) [PIC RX]
RX  <”””””””””””” RC7 (Pin 18) [PIC TX]
GND ””””””””””””> GND
```

### Find Your Serial Port

**Linux:**
```bash
ls /dev/ttyUSB*
# Usually /dev/ttyUSB0 or /dev/ttyACM0
```

**macOS:**
```bash
ls /dev/cu.usbserial*
# Usually /dev/cu.usbserial-XXXX
```

**Windows:**
- Open Device Manager
- Look under "Ports (COM & LPT)"
- Find "USB Serial Port (COM3)" or similar

### Connect and Play

```bash
python3 chess_player.py /dev/ttyUSB0    # Linux
python3 chess_player.py COM3            # Windows
python3 chess_player.py /dev/cu.usbserial-XXXX  # macOS
```

**What you'll see:**
```
Play Chess Against PIC18F45K22
PASS Connected to /dev/ttyUSB0

  =================================
8 | r | n | b | q | k | b | n | r |
...
```

Now you're playing against the real PIC.

---

##  AI Difficulty Levels

When you start a new game, you can choose AI difficulty:

```
Your move > new
```

The default is Level 2 (Medium). To change:
- **Level 1 (Easy)**: Random legal moves (< 1 second)
- **Level 2 (Medium)**: Evaluates positions (< 5 seconds)
- **Level 3 (Hard)**: Minimax search (< 30 seconds)

*(Level selection will be added in future versions of the Python interface)*

---

##  Troubleshooting

### "No module named serial"

**Problem:** pyserial not installed

**Solution:**
```bash
pip3 install pyserial
# or
python3 -m pip install pyserial
```

Or just use simulated mode (no hardware needed):
```bash
python3 chess_player.py
```

### "Permission denied: /dev/ttyUSB0"

**Problem:** User doesn't have permission to access serial port

**Solution (Linux):**
```bash
sudo usermod -a -G dialout $USER
# Then log out and log back in
```

**Quick fix:**
```bash
sudo chmod 666 /dev/ttyUSB0
```

### No Response from PIC

**Check:**
1. Is PIC powered on?
2. Is it programmed with the chess engine?
3. Are RX/TX connections swapped?
4. Is baud rate 9600?
5. Try unplugging and replugging USB

### Garbled Output

**Check:**
1. Baud rate is 9600
2. Serial settings are 8N1 (8 data bits, no parity, 1 stop bit)
3. Ground connection is good
4. Power supply is stable

---

##  Technical Details

### Communication Protocol

| Direction | Format | Example |
|-----------|--------|---------|
| PC --> PIC | `MOVE e2e4\r\n` | Send move |
| PIC --> PC | `OK <FEN>\r\n` | Move accepted |
| PIC --> PC | `ERROR Invalid move\r\n` | Move rejected |

### FEN (Forsyth-Edwards Notation)

The PIC sends board positions using FEN:
```
rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
```

Components:
- Piece placement (ranks 8 to 1)
- Active color (w/b)
- Castling rights (KQkq)
- En passant target
- Halfmove clock
- Fullmove number

### Serial Settings

- **Baud Rate**: 9600
- **Data Bits**: 8
- **Parity**: None
- **Stop Bits**: 1
- **Flow Control**: None

---

##  Learning Chess with the PIC

This chess engine is perfect for:

1. **Learning chess rules** - PIC enforces all rules
2. **Practicing openings** - Play standard chess openings
3. **Understanding positions** - See FEN notation
4. **Assembly language** - Study the PIC source code
5. **Embedded systems** - Real-world microcontroller project

---

##  Additional Resources

- **FEN_PROTOCOL.md** - Complete protocol specification
- **chess_player.py** - Python source code
- **move_validator.S** - PIC assembly validation code
- **fen_support.S** - FEN parsing/generation code
- **chess_engine_complete.S** - Main chess engine

---

##  Getting Help

**Run tests first:**
```bash
python3 chess_player.py --test
```

**Check the documentation:**
- `FEN_PROTOCOL.md` - Protocol details
- `README.md` - Project overview
- `USER_MANUAL.md` - Full user manual

**Common Issues:**
- Invalid moves --> PIC tells you why
- Can't connect --> Check serial port and permissions
- Simulated mode --> Works without hardware (for testing)

---

##  Have Fun.

You're now ready to play chess against a microcontroller.

**Remember:**
- The PIC validates all moves
- You can't cheat the chess rules
- AI will respond after your valid moves
- Simulated mode works without hardware

Enjoy playing chess. 

---

*This guide was created for the PIC18F45K22 Chess Engine project*
*For questions or issues, see the main README.md*
