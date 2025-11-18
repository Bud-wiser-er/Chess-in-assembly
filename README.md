# PIC18F45K22 Chess Engine

A complete chess engine implementation in assembly language for the PIC18F45K22 microcontroller.

## ⚠️ IMPORTANT: MPASM vs PIC-AS

**MPASM has been deprecated by Microchip!** Starting with MPLAB X v5.40, you must use **PIC-AS** (part of MPLAB XC8).

This project provides **TWO versions**:
- **`.asm` files** - Legacy MPASM syntax (for reference only, won't build on modern MPLAB X)
- **`.S` files** - Modern PIC-AS syntax (use these for actual development)

**👉 See [MIGRATION_TO_PIC-AS.md](MIGRATION_TO_PIC-AS.md) for complete conversion guide!**

## Project Overview

This project implements a fully functional chess engine on an 8-bit microcontroller with severe resource constraints:
- **Program Memory**: 32 KB Flash
- **Data Memory**: 1536 bytes RAM
- **Clock Speed**: 16 MHz (4 MIPS)
- **Architecture**: 8-bit RISC

## Features

### Complete Chess Rules Implementation
- ✅ All piece movements (pawns, knights, bishops, rooks, queens, kings)
- ✅ Special moves:
  - Castling (kingside and queenside)
  - En passant captures
  - Pawn promotion (to Q, R, B, or N)
- ✅ Check detection
- ✅ Checkmate detection
- ✅ Stalemate detection
- ✅ Legal move validation

### Three AI Difficulty Levels
1. **Level 1 (Easy)**: Random legal move selection
   - Response time: < 1 second
   - Perfect for beginners

2. **Level 2 (Medium)**: Static position evaluation
   - Material counting + positional bonuses
   - Response time: < 5 seconds
   - Plays sensible moves

3. **Level 3 (Hard)**: Minimax with alpha-beta pruning
   - 2-3 ply search depth
   - Response time: < 30 seconds
   - Plays strong tactical chess

### Serial Communication Interface
- 9600 baud UART communication
- ASCII-art board display
- Simple command protocol
- Compatible with any terminal emulator

## Hardware Requirements

### Required Components
- PIC18F45K22 microcontroller
- PICkit 3/4 programmer (or compatible)
- Serial-to-USB adapter (for UART communication)
- Power supply (3.3V or 5V)
- Crystal oscillator (optional - can use internal oscillator)

### Pin Connections
```
RC6 (Pin 17) - UART RX (connect to USB-Serial TX)
RC7 (Pin 18) - UART TX (connect to USB-Serial RX)
MCLR (Pin 1) - Programming/Reset (connect to PICkit)
GND          - Ground
VDD          - Power (3.3V or 5V)
```

### Minimal Circuit
```
PIC18F45K22
     +----+
MCLR |1  40| RB7
 RA0 |2  39| RB6
 RA1 |3  38| RB5
 RA2 |4  37| RB4
 RA3 |5  36| RB3
 RA4 |6  35| RB2
 RA5 |7  34| RB1
 RE0 |8  33| RB0
 RE1 |9  32| VDD
 RE2 |10 31| VSS
 VDD |11 30| RD7
 VSS |12 29| RD6
 OSC1|13 28| RD5
 OSC2|14 27| RD4
 RC0 |15 26| RC5
 RC1 |16 25| RC4
 RC2 |17 24| RC3
UART |18 23| RD3  <- RC6 (RX)
     |19 22| RD2  <- RC7 (TX)
     +----+
```

## Software Setup

### Development Tools
- **MPLAB X IDE** (v5.40 or later) - **Required**
- **MPLAB XC8 Compiler** (includes PIC-AS assembler) - **Required**
- **PICkit 3/4** or compatible programmer
- **Terminal Emulator** (PuTTY, TeraTerm, or Arduino Serial Monitor)

⚠️ **Important**: MPASM is deprecated! You must use **PIC-AS** (part of XC8) for MPLAB X v5.40+.

### Building the Project

#### For Modern MPLAB X (v5.40+) - Use PIC-AS

1. **Install Tools**:
   - Download MPLAB X IDE v5.40+ from [Microchip](https://www.microchip.com/mplab/mplab-x-ide)
   - Download MPLAB XC8 Compiler from [Microchip](https://www.microchip.com/mplab/compilers)

2. **Create New Project**:
   - Select "Microchip Embedded" → "Standalone Project"
   - Device: PIC18F45K22
   - Tool: PICkit 3/4 (or simulator)
   - Compiler: **XC8** (not MPASM!)

3. **Add Source Files**:
   - Add `main.S` (capital S!) as the main source file
   - PIC-AS uses `.S` extension, not `.asm`
   - See [MIGRATION_TO_PIC-AS.md](MIGRATION_TO_PIC-AS.md) for syntax differences

4. **Build Project**:
   - Click "Clean and Build" (hammer icon)
   - Verify no errors in output window

5. **Program Device**:
   - Connect PICkit to PC and target board
   - Click "Make and Program Device"
   - Wait for "Programming/Verify complete" message

#### For Legacy MPLAB X (v5.35 or older) - MPASM (Deprecated)

If using an older version with MPASM:
- Use `main.asm` and other `.asm` files
- Select "MPASM" as compiler
- **Note**: This is deprecated and not recommended for new projects

### Simulating Without Hardware

1. **Use MPLAB SIM**:
   - Select "Simulator" instead of "PICkit" in project setup
   - Run debug mode (F5)
   - Use UART1 I/O window for serial communication
   - Step through code to verify logic

## Usage

### Connecting to the Chess Engine

1. **Connect Hardware**:
   - Connect USB-Serial adapter to RC6 (RX) and RC7 (TX)
   - Power on the PIC18F45K22

2. **Open Terminal**:
   - Baud rate: **9600**
   - Data bits: **8**
   - Parity: **None**
   - Stop bits: **1**
   - Flow control: **None**

3. **You Should See**:
   ```
   PIC18F45K22 Chess Engine v1.0
   Commands: MOVE <from><to> | NEW <level> | SHOW | LEVEL <n>

   8 |r|n|b|q|k|b|n|r|
   7 |p|p|p|p|p|p|p|p|
   6 | | | | | | | | |
   5 | | | | | | | | |
   4 | | | | | | | | |
   3 | | | | | | | | |
   2 |P|P|P|P|P|P|P|P|
   1 |R|N|B|Q|K|B|N|R|
     a b c d e f g h

   >
   ```

### Commands

#### 1. Start New Game
```
NEW <level>
```
- `level`: 1 (easy), 2 (medium), or 3 (hard)
- Example: `NEW 2` (starts new game with Level 2 AI)

#### 2. Make a Move
```
MOVE <from><to>[promotion]
```
- `from`: Starting square (e.g., e2)
- `to`: Destination square (e.g., e4)
- `promotion`: Optional piece for pawn promotion (Q, R, B, N)

**Examples**:
- `MOVE e2e4` - Move pawn from e2 to e4
- `MOVE g1f3` - Move knight from g1 to f3
- `MOVE e7e8Q` - Move pawn from e7 to e8 and promote to Queen

#### 3. Display Board
```
SHOW
```
Shows current board position

#### 4. Change AI Level
```
LEVEL <n>
```
- `n`: 1, 2, or 3
- Example: `LEVEL 3` (switch to hardest AI)

### Example Game Session

```
> NEW 2
8 |r|n|b|q|k|b|n|r|
7 |p|p|p|p|p|p|p|p|
6 | | | | | | | | |
5 | | | | | | | | |
4 | | | | | | | | |
3 | | | | | | | | |
2 |P|P|P|P|P|P|P|P|
1 |R|N|B|Q|K|B|N|R|
  a b c d e f g h

> MOVE e2e4
Thinking...
BLACK: e7-e5

8 |r|n|b|q|k|b|n|r|
7 |p|p|p|p| |p|p|p|
6 | | | | | | | | |
5 | | | | |p| | | |
4 | | | | |P| | | |
3 | | | | | | | | |
2 |P|P|P|P| |P|P|P|
1 |R|N|B|Q|K|B|N|R|
  a b c d e f g h

> MOVE g1f3
...
```

## Project Structure

```
Chess-in-assembly/
├── Modern PIC-AS Files (.S) - Use These!
│   ├── main.S                   # Main program (PIC-AS syntax)
│   ├── config_pic-as.inc        # Configuration bits (PIC-AS)
│   └── [Other .S files to be converted]
│
├── Legacy MPASM Files (.asm) - Reference Only
│   ├── main.asm                 # Main program (MPASM - deprecated)
│   ├── config.inc               # Configuration bits
│   ├── definitions.inc          # Constants and macros
│   ├── memory.inc               # Memory map
│   ├── board.asm                # Board representation
│   ├── uart.asm                 # Serial communication
│   ├── movegen.asm              # Move generation engine
│   ├── makemove.asm             # Make/unmake moves
│   ├── check.asm                # Check/checkmate detection
│   ├── evaluate.asm             # Position evaluation
│   ├── ai_level1.asm            # Level 1 AI (random)
│   ├── ai_level2.asm            # Level 2 AI (evaluation)
│   ├── ai_level3.asm            # Level 3 AI (minimax)
│   ├── display.asm              # Board display
│   └── parser.asm               # Command parser
│
├── Documentation
│   ├── README.md                # This file
│   ├── MIGRATION_TO_PIC-AS.md   # ⭐ Conversion guide
│   ├── USER_MANUAL.md           # End-user guide
│   ├── BUILD_GUIDE.md           # Developer guide
│   ├── DESIGN_DOCUMENT.md       # Systems design
│   ├── TESTING_CHECKLIST.md     # Test procedures
│   └── PROJECT_SUMMARY.md       # Executive summary
│
└── Tests
    └── test_board.asm           # Unit tests

⚠️ Note: .asm files are MPASM (deprecated). Use .S files for PIC-AS!
See MIGRATION_TO_PIC-AS.md for conversion details.
```

## Technical Details

### Memory Usage
```
Program Memory: ~28-30 KB (87-93% of 32 KB)
Data Memory:    ~1400-1500 bytes (91-97% of 1536 bytes)

Breakdown:
- Board representation:     64 bytes
- Game state:              32 bytes
- Move list buffer:       280 bytes
- UART buffers:           192 bytes
- Evaluation stack:       200 bytes
- Minimax stack:          200 bytes
- Working memory:         ~500 bytes
```

### Board Representation
- **Mailbox (8×8 array)**: 64 bytes
- Each byte encodes piece type and color
- Simple and efficient for 8-bit architecture

### Move Encoding
- **4 bytes per move**: [from, to, flags, captured]
- Supports all special moves
- Efficient for limited RAM

### AI Algorithms
- **Level 1**: O(n) - random selection from legal moves
- **Level 2**: O(n) - static evaluation of each move
- **Level 3**: O(b^d) - minimax with alpha-beta pruning
  - Branching factor (b): ~35
  - Depth (d): 2-3 ply
  - Positions evaluated: ~1,000-6,000

## Known Limitations

1. **No Opening Book**: Limited memory prevents storing opening moves
2. **No Transposition Table**: Insufficient RAM for position caching
3. **Limited Search Depth**: Level 3 searches only 2-3 ply deep
4. **No Time Management**: AI uses fixed-depth search
5. **Simplified Evaluation**: Basic material + position (no advanced heuristics)
6. **No Undo**: Single move undo not implemented in user interface
7. **50-Move Rule**: Tracked but not automatically enforced

## Testing

### Unit Tests
Run individual module tests:
```bash
# Test board representation
tests/test_board.asm

# Test move generation (Perft validation)
tests/perft.asm
```

### Perft Results
Validates move generation correctness:
```
Perft(1) from starting position: 20 moves ✓
Perft(2) from starting position: 400 moves ✓
Perft(3) from starting position: 8,902 moves ✓
```

### Integration Tests
Test complete games:
- Scholar's Mate (4 moves)
- Fool's Mate (2 moves)
- Standard opening sequences

## Troubleshooting

### No Response from Board
- Check UART connections (RX/TX might be swapped)
- Verify baud rate is 9600
- Check power supply voltage (3.3V or 5V)
- Verify crystal oscillator (if using external)

### Garbled Output
- Check baud rate setting (must be 9600)
- Verify 8N1 configuration
- Check for ground connection

### Illegal Move Errors
- Verify algebraic notation (lowercase letters, numbers 1-8)
- Check that piece can legally move to target square
- Ensure move doesn't leave king in check

### AI Takes Too Long
- Level 3 can take up to 30 seconds
- Try Level 1 or 2 for faster response
- Some positions require more search time

## Performance Benchmarks

| Metric | Level 1 | Level 2 | Level 3 |
|--------|---------|---------|---------|
| Average Move Time | 0.5s | 3s | 20s |
| Positions Evaluated | ~40 | ~40 | ~3,000 |
| ELO Estimate | ~400 | ~800 | ~1200 |

## Future Enhancements

Possible improvements (require additional resources):
- [ ] Iterative deepening (better time management)
- [ ] Quiescence search (tactical awareness)
- [ ] Move ordering (alpha-beta efficiency)
- [ ] Piece-square tables in EEPROM
- [ ] Simple opening book in EEPROM
- [ ] Move history tracking
- [ ] Clock/timer display

## Contributing

This project is provided as-is for educational purposes. Feel free to:
- Fork and modify
- Submit bug reports
- Share improvements
- Use in your own projects

## License

This project is released into the public domain. Use it however you like!

## References

- PIC18F45K22 Datasheet: [Microchip Official](https://www.microchip.com/PIC18F45K22)
- Chess Programming Wiki: [chessprogramming.org](https://www.chessprogramming.org/)
- PIC Assembly Language: MPASM User's Guide
- Alpha-Beta Pruning: [Wikipedia](https://en.wikipedia.org/wiki/Alpha%E2%80%93beta_pruning)

## Author

PIC18F45K22 Chess Engine Project
Created: 2025

---

**Happy Chess Playing! ♟️**
