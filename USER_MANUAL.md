# PIC18F45K22 Chess Engine - User Manual

## Table of Contents
1. [Getting Started](#getting-started)
2. [Hardware Setup](#hardware-setup)
3. [Software Installation](#software-installation)
4. [Playing Chess](#playing-chess)
5. [Command Reference](#command-reference)
6. [Chess Rules](#chess-rules)
7. [AI Difficulty Levels](#ai-difficulty-levels)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Getting Started

### What You Need
- PIC18F45K22 microcontroller (pre-programmed with chess engine)
- USB-to-Serial adapter (FTDI, CP2102, or similar)
- Computer with terminal emulator
- Power source (USB or battery, 3.3V-5V)
- Jumper wires for connections

### Quick Start
1. Connect the hardware (see Hardware Setup)
2. Open your terminal emulator
3. Configure: 9600 baud, 8N1
4. Power on the device
5. Type `NEW 2` to start a game
6. Make moves with `MOVE e2e4` format
7. The AI will respond automatically

---

## Hardware Setup

### Pin Connections

```
USB-Serial Adapter          PIC18F45K22
”””””””””””””””””          ””””””””””””
        TX        ””””””””> RC6 (Pin 17) RX
        RX        <”””””””” RC7 (Pin 18) TX
       GND        ””””””””> GND
       VCC        ””””””””> VDD (3.3V or 5V)
```

### Important Notes
- **NEVER** swap RX and TX. TX connects to RX, RX connects to TX
- Ensure voltage levels match (3.3V or 5V)
- Common ground is essential
- Use short, quality jumper wires

### LED Indicator (Optional)
You can add an LED to indicate when the AI is thinking:
```
PIC18F45K22          LED
””””””””””””          ”””
    RA0      ””””””> Anode (longer leg)
                         |
                      Resistor (220Î©-1kÎ©)
                         |
    GND      ””””””> Cathode (shorter leg)
```

---

## Software Installation

### Windows

1. **Install Terminal Emulator**:
   - Download [PuTTY](https://www.putty.org/)
   - Or use [TeraTerm](https://ttssh2.osdn.jp/)

2. **Configure PuTTY**:
   - Connection type: Serial
   - Serial line: COM3 (check Device Manager for your port)
   - Speed: 9600
   - Click "Open"

3. **Configure Settings**:
   - Terminal --> Local echo: Force on (optional)
   - Terminal --> Local line editing: Force on (optional)

### macOS

1. **Find Serial Port**:
   ```bash
   ls /dev/cu.*
   ```
   Look for `/dev/cu.usbserial-XXXX`

2. **Connect with screen**:
   ```bash
   screen /dev/cu.usbserial-XXXX 9600
   ```

3. **Exit screen**:
   Press `Ctrl-A` then `K`, then `Y` to confirm

### Linux

1. **Find Serial Port**:
   ```bash
   dmesg | grep tty
   ```
   Usually `/dev/ttyUSB0` or `/dev/ttyACM0`

2. **Connect with screen**:
   ```bash
   screen /dev/ttyUSB0 9600
   ```

3. **Alternative (minicom)**:
   ```bash
   sudo minicom -D /dev/ttyUSB0 -b 9600
   ```

---

## Playing Chess

### Starting a New Game

Type:
```
NEW 2
```
This starts a new game with AI Level 2 (medium difficulty).

You'll see the starting position:
```
8 |r|n|b|q|k|b|n|r|
7 |p|p|p|p|p|p|p|p|
6 | | | | | | | | |
5 | | | | | | | | |
4 | | | | | | | | |
3 | | | | | | | | |
2 |P|P|P|P|P|P|P|P|
1 |R|N|B|Q|K|B|N|R|
  a b c d e f g h
```

### Understanding the Board

**Piece Symbols**:
- **Uppercase** = White pieces
  - `P` = Pawn
  - `N` = Knight
  - `B` = Bishop
  - `R` = Rook
  - `Q` = Queen
  - `K` = King

- **Lowercase** = Black pieces
  - `p` = Pawn
  - `n` = Knight
  - `b` = Bishop
  - `r` = Rook
  - `q` = Queen
  - `k` = King

**Square Naming**:
- **Files** (columns): a-h (left to right)
- **Ranks** (rows): 1-8 (bottom to top from white's perspective)
- Example: `e4` = file 'e', rank '4'

### Making Moves

#### Basic Move Format
```
MOVE <from><to>
```

**Examples**:
```
MOVE e2e4    # Move pawn from e2 to e4
MOVE g1f3    # Move knight from g1 to f3
MOVE f1c4    # Move bishop from f1 to c4
MOVE e1g1    # Castle kingside (king moves e1 to g1)
```

#### Pawn Promotion
When a pawn reaches the opposite end, add the promotion piece:
```
MOVE e7e8Q   # Promote to Queen
MOVE e7e8R   # Promote to Rook
MOVE e7e8B   # Promote to Bishop
MOVE e7e8N   # Promote to Knight
```

#### Special Moves

**Castling**:
- Kingside: `MOVE e1g1` (white) or `MOVE e8g8` (black)
- Queenside: `MOVE e1c1` (white) or `MOVE e8c8` (black)

**En Passant**:
Just move the pawn diagonally to the en passant square:
```
MOVE e5d6    # Capture en passant
```

### Game Flow

1. **You (White) move first**
   - Type your move: `MOVE e2e4`
   - Press Enter

2. **AI (Black) responds**
   - You'll see: "Thinking..."
   - AI makes its move
   - Board updates automatically

3. **Continue taking turns**
   - Type your next move
   - Wait for AI response
   - Repeat until game ends

### Game End Conditions

**Checkmate**:
```
Checkmate. White wins.
```
or
```
Checkmate. Black wins.
```

**Stalemate**:
```
Stalemate - Draw.
```

**Check**:
```
Check.
```
You must move your king to safety or block the attack.

---

## Command Reference

### NEW - Start New Game
```
NEW <level>
```
- **level**: 1 (easy), 2 (medium), or 3 (hard)
- Resets board to starting position
- Sets AI difficulty

**Examples**:
```
NEW 1    # Start easy game
NEW 2    # Start medium game
NEW 3    # Start hard game
```

### MOVE - Make a Move
```
MOVE <from><to>[promotion]
```
- **from**: Starting square (e.g., e2)
- **to**: Destination square (e.g., e4)
- **promotion**: Q, R, B, or N (only for pawn promotion)

**Examples**:
```
MOVE d2d4       # Pawn to d4
MOVE b1c3       # Knight to c3
MOVE d1h5       # Queen to h5
MOVE e7e8Q      # Pawn promotes to Queen
```

**Common Errors**:
```
Illegal move.   # Move not legal in current position
Error.          # Invalid command format
```

### SHOW - Display Board
```
SHOW
```
- Displays current board position
- Useful to refresh the display
- No arguments needed

### LEVEL - Change AI Difficulty
```
LEVEL <n>
```
- **n**: 1, 2, or 3
- Changes AI difficulty mid-game
- Does not reset the board

**Examples**:
```
LEVEL 1    # Switch to easy mode
LEVEL 3    # Switch to hard mode
```

---

## Chess Rules

### Piece Movement

#### Pawn
- Moves forward one square
- First move: can move forward two squares
- Captures diagonally forward
- Promotes when reaching opposite end

#### Knight
- Moves in "L" shape: 2 squares in one direction, 1 square perpendicular
- Can jump over other pieces
- Unique movement pattern

#### Bishop
- Moves diagonally any number of squares
- Cannot jump over pieces
- Stays on same color squares

#### Rook
- Moves horizontally or vertically any number of squares
- Cannot jump over pieces
- Essential for castling

#### Queen
- Combines bishop and rook movement
- Most powerful piece
- Can move diagonally or straight

#### King
- Moves one square in any direction
- Cannot move into check
- Can castle once per game (if conditions met)

### Special Rules

#### Castling
**Requirements**:
- King and rook haven't moved
- No pieces between king and rook
- King not in check
- King doesn't pass through or land in check

**How to Castle**:
- Kingside: `MOVE e1g1` (king moves two squares toward h-rook)
- Queenside: `MOVE e1c1` (king moves two squares toward a-rook)

#### En Passant
**When**:
- Enemy pawn moves two squares forward
- Lands beside your pawn

**How**:
- Next move only: capture diagonally to square pawn passed over
- Example: If enemy pawn goes e7-->e5, and you have pawn on d5, you can play `MOVE d5e6`

#### Pawn Promotion
**When**:
- Your pawn reaches rank 8 (or rank 1 for black)

**How**:
- Must promote to Q, R, B, or N
- Example: `MOVE e7e8Q` (promotes to Queen)

### Check and Checkmate

#### Check
- King is under attack
- Must move king, block, or capture attacker
- Cannot make move that leaves king in check

#### Checkmate
- King in check with no legal moves
- Game over, attacker wins

#### Stalemate
- Not in check but no legal moves
- Game ends in draw

---

## AI Difficulty Levels

### Level 1: Random (Easy)
**Characteristics**:
- Picks random legal move
- No strategy or planning
- Very fast (< 1 second)
- Perfect for beginners

**Expected Behavior**:
- May hang pieces
- No obvious threats
- Random opening moves
- Easily beatable

**When to Use**:
- Learning chess rules
- Testing move legality
- Quick games

---

### Level 2: Evaluation (Medium)
**Characteristics**:
- Evaluates each move's result
- Considers material and position
- Medium speed (1-5 seconds)
- Plays sensible chess

**Strategy**:
- Captures valuable pieces
- Avoids hanging pieces
- Controls center
- Basic tactical awareness

**Expected Behavior**:
- Won't blunder pieces easily
- Makes reasonable moves
- Some positional understanding
- Moderate challenge

**When to Use**:
- Casual games
- Balanced difficulty
- Learning strategy

---

### Level 3: Minimax (Hard)
**Characteristics**:
- Looks 2-3 moves ahead
- Uses minimax algorithm
- Slower (10-30 seconds)
- Strongest play

**Strategy**:
- Finds tactical combinations
- Plans ahead
- Evaluates consequences
- Alpha-beta pruning for efficiency

**Expected Behavior**:
- Spots simple tactics (forks, pins)
- Avoids most blunders
- Plays strong openings
- Challenging for intermediate players

**When to Use**:
- Serious games
- Maximum challenge
- When you have time to wait

**Note**: Some complex positions may take the full 30 seconds.

---

## Troubleshooting

### Problem: No Output on Terminal

**Check**:
1. Power connected to PIC? (LED should light if present)
2. USB-Serial adapter connected to computer?
3. Correct COM port selected?
4. Baud rate set to 9600?
5. RX/TX wires swapped?

**Solution**:
- Verify all connections
- Try different USB port
- Restart terminal emulator
- Check Device Manager (Windows) for COM port

---

### Problem: Garbled Characters

**Symptoms**: `$#@.%^&*` instead of text

**Causes**:
- Wrong baud rate
- Wrong parity/stop bits
- Loose connection

**Solution**:
- Set baud rate to exactly **9600**
- Set to **8N1** (8 data bits, no parity, 1 stop bit)
- Check cable connections
- Try different terminal emulator

---

### Problem: "Illegal move." Error

**Why**:
- Move doesn't follow chess rules
- Piece can't reach that square
- Move leaves king in check
- Wrong piece type for that move

**Solution**:
- Check piece movement rules
- Verify starting square has your piece
- Ensure destination is valid
- Type `SHOW` to see current position

**Common Mistakes**:
```
MOVE e2e5    # Pawn can't move 3 squares
MOVE e1e2    # King in check? Can't move there
MOVE f1g3    # Path blocked? Bishop can't jump
```

---

### Problem: AI Takes Too Long

**Normal Behavior**:
- Level 1: < 1 second
- Level 2: 1-5 seconds
- Level 3: 10-30 seconds (especially in complex positions)

**If Excessively Long**:
- Wait for current move to complete
- Switch to lower difficulty: `LEVEL 2` or `LEVEL 1`
- Complex positions take longer

---

### Problem: Board Display Scrambled

**Fix**:
- Type `SHOW` to redisplay board
- Some terminal emulators handle line breaks differently
- Try different emulator (PuTTY usually works best)

---

## FAQ

### Can I play against a friend?
Not directly. This version is AI vs Human only. Both players would need to take turns at the terminal.

### Can I undo a move?
No, undo is not currently implemented. Start a new game with `NEW <level>` if needed.

### What happens if I make an illegal move?
The engine will respond with "Illegal move." and wait for a legal move.

### Can I play as Black?
No, you always play as White (moves first), AI plays as Black.

### How do I save a game?
Game saving is not supported. Games exist only during the current session.

### Can I analyze positions?
Not directly, but you can use the `SHOW` command to view the board anytime.

### What if the game is drawn?
The engine detects stalemate. It does NOT automatically detect:
- Three-fold repetition
- 50-move rule
- Insufficient material

These require manual agreement or starting a new game.

### Can I change the AI mid-game?
Yes. Use `LEVEL <n>` to switch difficulty without resetting the board.

### Why is Level 3 so slow?
Level 3 evaluates thousands of positions (up to 6,000). On an 8-bit microcontroller running at 16 MHz, this takes time.

### Can the AI play against itself?
Not in the current version. You must make moves for White.

### What's the AI's playing strength?
Approximate ELO ratings:
- Level 1: ~400 (beginner)
- Level 2: ~800 (novice)
- Level 3: ~1200 (intermediate)

For reference, average club players are 1200-1600.

### Does it have an opening book?
No, due to memory constraints. The AI calculates every move.

### Can it solve chess puzzles?
Level 2 and 3 can solve simple tactics (2-3 moves deep). Complex puzzles may be beyond its search depth.

### What happens if power is lost?
Game is lost. No persistent storage. Restart and begin a new game.

---

## Tips for Best Experience

### Maximize AI Strength
1. Use Level 3 for serious games
2. Give it time to think (don't interrupt power)
3. Complex positions yield better moves
4. Play solidly - AI punishes mistakes

### Speed Up Games
1. Use Level 1 for quick games
2. Use Level 2 for balanced speed/strength
3. Avoid highly complex positions
4. Make moves promptly

### Learning Chess
1. Start with Level 1 to learn rules
2. Progress to Level 2 when comfortable
3. Use Level 3 to improve skills
4. Analyze why AI made certain moves

### Best Terminal Settings
- **Windows**: PuTTY (most reliable)
- **macOS/Linux**: screen command
- **All**: 9600 baud, 8N1, no flow control
- **Optional**: Enable local echo for easier typing

---

## Example Game

Here's a complete game showing all features:

```
> NEW 2
[Board displays]

> MOVE e2e4
Thinking...
BLACK: e7-e5
[Board updates]

> MOVE g1f3
Thinking...
BLACK: b8c6
[Board updates]

> MOVE f1c4
Thinking...
BLACK: g8f6
[Board updates]

> MOVE b1c3
Thinking...
BLACK: f8c5
[Board updates]

> SHOW
[Board redisplays]

> LEVEL 3
Level 3
[Difficulty changed, no board reset]

> MOVE d2d3
Thinking...
[Takes longer now - Level 3]
BLACK: d7-d6
[Board updates]

...continue until mate or draw...
```

---

## Support and Resources

### Need Help?
- Re-read this manual
- Check Troubleshooting section
- Review chess rules online
- Practice with Level 1 first

### Learn Chess
- [Chess.com Learn](https://www.chess.com/learn)
- [Lichess Basics](https://lichess.org/learn)
- YouTube chess channels

### Technical Documentation
- See `DESIGN_DOCUMENT.md` for technical details
- See `README.md` for developer information
- Source code includes detailed comments

---

**End of manual. **

---

*Last Updated: 2025*
*Version: 1.0*
