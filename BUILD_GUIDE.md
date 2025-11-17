# Build and Development Guide

## Table of Contents
1. [Development Environment Setup](#development-environment-setup)
2. [Building the Project](#building-the-project)
3. [Programming the Microcontroller](#programming-the-microcontroller)
4. [Debugging](#debugging)
5. [Testing](#testing)
6. [Optimization](#optimization)
7. [Code Organization](#code-organization)

---

## Development Environment Setup

### Required Software

#### MPLAB X IDE
1. Download from [Microchip Official Site](https://www.microchip.com/mplab/mplab-x-ide)
2. Install version 6.0 or later
3. Include MPASM assembler toolchain

#### Alternative: Command-Line Tools
For advanced users who prefer command-line:
```bash
# MPASM assembler (standalone)
# Download from Microchip
```

### Hardware Tools

#### For Programming
- **PICkit 3** or **PICkit 4** programmer
- USB cable (A to Micro-B or C, depending on PICkit version)
- Target board with PIC18F45K22

#### For Testing
- USB-to-Serial adapter (FTDI FT232, CP2102, etc.)
- Jumper wires
- Breadboard (optional)
- Logic analyzer (optional, for debugging)

---

## Building the Project

### Method 1: MPLAB X IDE (Recommended)

#### Create New Project
1. Open MPLAB X IDE
2. **File** → **New Project**
3. Choose **Microchip Embedded** → **Standalone Project**
4. Click **Next**

#### Device Selection
1. **Family**: Mid-Range 8-bit MCUs
2. **Device**: PIC18F45K22
3. Click **Next**

#### Tool Selection
1. Select your programmer (PICkit 3/4)
2. Or select **Simulator** for testing without hardware
3. Click **Next**

#### Compiler Selection
1. **Compiler Toolchain**: MPASM (mpasmwin)
2. Click **Next**

#### Project Name and Location
1. **Project Name**: Chess-Engine-PIC18F45K22
2. **Project Location**: Choose your directory
3. Click **Finish**

#### Add Source Files
1. Right-click **Source Files** in project tree
2. **Add Existing Item**
3. Navigate to project folder
4. Add **main.asm**
5. All other files are included via `#include` directives

#### Project Configuration
Right-click project → **Properties** → **MPASM**:
- **Use absolute mode**: Unchecked
- **Generate cross reference file**: Checked (optional)
- **Generate symbol file**: Checked (optional)

#### Build Project
1. Click **Clean and Build** (hammer icon)
2. Check **Output** window for results
3. Look for "BUILD SUCCESSFUL"

#### Expected Output
```
BUILD SUCCESSFUL (total time: 5s)
Loading code from C:\...\Chess-Engine.X\dist\default\production\Chess-Engine.X.production.hex
Loading completed
```

### Build Output Files
After successful build:
```
dist/
└── default/
    └── production/
        ├── Chess-Engine.X.production.hex    # Flash programming file
        ├── Chess-Engine.X.production.elf    # Executable linkable format
        └── Chess-Engine.X.production.lst    # Assembly listing
```

---

### Method 2: Command-Line Build

#### Using MPASM Directly
```bash
# Navigate to project directory
cd Chess-in-assembly

# Assemble main file
mpasm /p18F45K22 /l /m /q main.asm

# Output: main.hex (ready to program)
```

#### Makefile (Optional)
Create `Makefile`:
```makefile
# Makefile for PIC18F45K22 Chess Engine

DEVICE = 18F45K22
SRC = main.asm
OUTPUT = chess_engine

all: $(OUTPUT).hex

$(OUTPUT).hex: $(SRC)
	mpasm /p$(DEVICE) /l /m /q $(SRC) /o$(OUTPUT).hex

clean:
	rm -f *.hex *.lst *.err *.o

program: $(OUTPUT).hex
	# Use your programmer's command-line tool
	# Example for PICkit3:
	# pk3cmd -P$(DEVICE) -F$(OUTPUT).hex -M -R

.PHONY: all clean program
```

Build with:
```bash
make
make program  # Program device
make clean    # Clean build files
```

---

## Programming the Microcontroller

### Using MPLAB X IDE

#### Connect Hardware
1. Connect PICkit to USB port
2. Connect PICkit ICSP to target PIC18F45K22:
   ```
   PICkit     PIC18F45K22
   ───────    ────────────
   Pin 1 (MCLR)  → MCLR (Pin 1)
   Pin 2 (VDD)   → VDD
   Pin 3 (VSS)   → VSS (Ground)
   Pin 4 (PGD)   → PGD (RB7)
   Pin 5 (PGC)   → PGC (RB6)
   ```
3. Optionally power target from PICkit (if supported)

#### Program Device
1. Click **Make and Program Device** (down arrow + chip icon)
2. Wait for programming to complete
3. Look for "Programming/Verify complete" message

#### Expected Output
```
Programming...
Programming/Verify complete
Running target
```

### Using Command-Line

#### PICkit 3 Command-Line Tool
```bash
pk3cmd -P18F45K22 -Fchess_engine.hex -M -R
```
Options:
- `-P`: Device
- `-F`: Hex file
- `-M`: Program device
- `-R`: Release from reset after programming

#### PICkit 4 (using MPLAB IPE)
```bash
ipecmd -P18F45K22 -Fchess_engine.hex -M -R
```

---

## Debugging

### Simulator (No Hardware Required)

#### Setup Simulator
1. **Project Properties** → **Conf: [default]**
2. **Select Tool**: Simulator
3. Click **OK**
4. Build project

#### Debug Session
1. Click **Debug Project** (Ctrl+F5)
2. Program counter stops at first instruction

#### Debug Features
- **Step Over** (F8): Execute one instruction
- **Step Into** (F7): Enter subroutine
- **Continue** (F5): Run until breakpoint
- **Stop** (Shift+F5): Stop debugging

#### Setting Breakpoints
1. Click left margin of code editor (red circle appears)
2. Run to breakpoint with F5
3. Inspect registers in **Variables** window

#### UART Simulation
1. **Window** → **Simulator** → **UART1 I/O**
2. Type commands in UART window
3. See output in same window

### Hardware Debugging (with PICkit)

#### Enable Debug Mode
1. **Production** → **Set Configuration** → **Debugging**
2. Program device in debug mode
3. Set breakpoints
4. Use step/continue commands

#### Watch Variables
1. **Window** → **Debugging** → **Variables**
2. Add variables to watch:
   - `game_turn`
   - `move_count`
   - `eval_score_lo`
   - etc.

#### Logic Analyzer (External)
Connect to critical pins:
- RC6 (UART RX)
- RC7 (UART TX)
- RA0 (custom debug pin)

### Common Debugging Tasks

#### Verify Board Initialization
```asm
; Set breakpoint here
CALL    board_init
; Step through and verify:
; - board+E1 == W_KING (0x06)
; - board+E8 == B_KING (0x0E)
```

#### Check Move Generation
```asm
; Set breakpoint after move generation
CALL    movegen_all
; Check move_count register
; Expected: ~20 from starting position
```

#### Monitor UART Communication
```asm
; Set breakpoint in uart_tx_byte
; Watch WREG for transmitted character
; Verify correct ASCII codes
```

---

## Testing

### Unit Tests

#### Board Tests
Run `tests/test_board.asm`:
```asm
#include "tests/test_board.asm"

start:
    CALL    run_board_tests
    ; WREG = 1 if all passed, 0 if any failed
```

#### Perft Testing
Validate move generation with Perft (performance test):
```asm
; From starting position
CALL    board_init
CALL    perft_depth1
; Expected: 20 moves

CALL    perft_depth2
; Expected: 400 moves

CALL    perft_depth3
; Expected: 8902 moves
```

### Integration Tests

#### Test Complete Game
1. Load test game sequence
2. Execute moves
3. Verify final position

Example (Scholar's Mate):
```
MOVE e2e4
MOVE e7e5
MOVE f1c4
MOVE b8c6
MOVE d1h5
MOVE g8f6
MOVE h5f7
; Checkmate!
```

#### Test Special Moves
```asm
; Test castling
test_castling:
    CALL    setup_castling_position
    CALL    movegen_all
    ; Verify castling moves in list

; Test en passant
test_en_passant:
    CALL    setup_en_passant_position
    CALL    movegen_all
    ; Verify en passant capture in list

; Test promotion
test_promotion:
    CALL    setup_promotion_position
    CALL    movegen_all
    ; Verify 4 promotion moves (Q, R, B, N)
```

### Performance Testing

#### Measure Execution Time
```asm
; Use Timer1 to measure function time
measure_movegen:
    ; Clear Timer1
    CLRF    TMR1L
    CLRF    TMR1H

    ; Call function
    CALL    movegen_all

    ; Read Timer1 (counts clock cycles / 4)
    MOVF    TMR1L, W    ; Low byte
    MOVWF   temp1
    MOVF    TMR1H, W    ; High byte
    MOVWF   temp2
    ; temp2:temp1 = elapsed time in instruction cycles
    RETURN
```

#### AI Response Time
Test each level:
```
Level 1: Should be < 16,000 cycles (~1ms at 16MHz)
Level 2: Should be < 80,000,000 cycles (~5s at 16MHz)
Level 3: Should be < 480,000,000 cycles (~30s at 16MHz)
```

---

## Optimization

### Code Size Optimization

#### Current Estimate
- **Total**: ~28-30 KB
- **Available**: 32 KB
- **Margin**: ~2-4 KB (6-12%)

#### Optimization Techniques
1. **Remove unused code**:
   - Comment out debug messages
   - Remove test functions in production

2. **Use macros** instead of functions for very short operations

3. **Lookup tables** instead of computation:
   ```asm
   ; Instead of computing square = rank*8 + file
   ; Use lookup table (if it saves code space)
   ```

4. **Code reuse**:
   - Combine similar functions
   - Use common subroutines

### RAM Optimization

#### Current Usage
- **Used**: ~1400-1500 bytes
- **Available**: 1536 bytes
- **Margin**: ~36-136 bytes (2-8%)

#### Optimization Techniques
1. **Reduce buffer sizes**:
   ```asm
   ; Reduce move_list from 70 to 60 moves
   ; Saves 40 bytes
   ```

2. **Reuse temporary variables**:
   ```asm
   ; Use same temp registers across modules
   ; Clear after use
   ```

3. **Use program memory** for constants:
   ```asm
   ; Store piece-square tables in flash
   ; Access via TBLRD
   ```

### Speed Optimization

#### Critical Paths
Focus on:
1. Move generation (called frequently)
2. Board access (called very frequently)
3. Position evaluation (called in AI search)

#### Techniques
1. **Inline critical functions**:
   ```asm
   ; Instead of CALL board_get_piece
   ; Inline the code if called in tight loop
   ```

2. **Optimize inner loops**:
   ```asm
   ; Use DECFSZ for loop exit
   ; Avoid unnecessary comparisons
   ```

3. **Use ACCESS RAM** for frequently accessed variables:
   ```asm
   ; Place loop counters in 0x000-0x05F
   ; No banking required
   ```

---

## Code Organization

### Module Structure
Each `.asm` file should:
1. Include required headers
2. Define public functions
3. Use consistent naming
4. Include detailed comments

### Naming Conventions
- **Functions**: `module_function` (e.g., `board_init`)
- **Constants**: `ALL_CAPS` (e.g., `BOARD_SIZE`)
- **Variables**: `lowercase_underscore` (e.g., `move_count`)
- **Labels**: `module_label` (e.g., `movegen_loop`)

### Comment Style
```asm
; ============================================================================
; function_name - Brief description
;
; Detailed description of what the function does, algorithm used, etc.
;
; Input:  param1 = description
;         param2 = description
; Output: return_value = description
; Modifies: list of registers modified
; Notes: Any special considerations
; ============================================================================
function_name:
    ; Implementation
    RETURN
```

### Adding New Features

#### 1. Plan the Feature
- Write detailed specification
- Estimate memory impact
- Design algorithm

#### 2. Create Module
```asm
; my_feature.asm
#include "config.inc"
#include "definitions.inc"
#include "memory.inc"

my_feature_init:
    ; ...
    RETURN

my_feature_process:
    ; ...
    RETURN
```

#### 3. Add to main.asm
```asm
#include "my_feature.asm"

; In initialization:
CALL my_feature_init

; In main loop:
CALL my_feature_process
```

#### 4. Test Thoroughly
- Unit tests
- Integration tests
- Memory usage check
- Performance test

---

## Troubleshooting Build Issues

### Error: "Cannot open source file"
**Solution**: Check that all `#include` paths are correct

### Error: "Illegal opcode"
**Solution**: Verify processor is set to PIC18F45K22

### Error: "Out of memory"
**Solution**: Code too large, need optimization

### Error: "Undefined symbol"
**Solution**: Check that label is defined and in correct scope

### Warning: "Register in operand not in bank 0"
**Solution**: Use banking directives or move to ACCESS RAM

---

## Advanced Topics

### Adding Piece-Square Tables
Store in program memory:
```asm
; In separate file or end of main
ORG 0x2000
pst_pawn:
    DB  0, 0, 0, 0, 0, 0, 0, 0  ; Rank 1
    DB  5, 10, 10,-20,-20, 10, 10, 5  ; Rank 2
    ; ... etc
```

Access:
```asm
; Read PST value
MOVLW   LOW pst_pawn
MOVWF   TBLPTRL
MOVLW   HIGH pst_pawn
MOVWF   TBLPTRH
MOVLW   UPPER pst_pawn
MOVWF   TBLPTRU

; Add square offset
MOVF    curr_square, W
ADDWF   TBLPTRL, F

; Read value
TBLRD*
MOVF    TABLAT, W
; W now contains PST value
```

### Using EEPROM for Data
Store opening book or endgame tables:
```asm
; Write to EEPROM
write_eeprom:
    MOVWF   EEDATA          ; Data to write
    MOVLW   address
    MOVWF   EEADR           ; Address
    BCF     EECON1, EEPGD   ; Point to EEPROM
    BSF     EECON1, WREN    ; Enable writes
    ; Required sequence:
    MOVLW   0x55
    MOVWF   EECON2
    MOVLW   0xAA
    MOVWF   EECON2
    BSF     EECON1, WR      ; Start write
    BTFSC   EECON1, WR      ; Wait for completion
    GOTO    $-2
    BCF     EECON1, WREN    ; Disable writes
    RETURN
```

### Interrupt-Driven UART
For more responsive input:
```asm
; Enable UART receive interrupt
BSF     PIE1, RC1IE     ; Enable RX interrupt
BSF     INTCON, GIE     ; Global interrupt enable

; ISR
ORG 0x0008
high_priority_isr:
    BTFSS   PIR1, RC1IF
    GOTO    not_uart
    CALL    uart_isr
    BCF     PIR1, RC1IF
not_uart:
    RETFIE FAST

uart_isr:
    ; Read character
    MOVF    RCREG1, W
    ; Store in buffer
    ; ...
    RETURN
```

---

## Release Checklist

Before releasing:
- [ ] All features implemented
- [ ] All tests passing
- [ ] Code commented thoroughly
- [ ] Memory usage within limits
- [ ] Performance meets requirements
- [ ] Documentation updated
- [ ] Build successful (no warnings)
- [ ] Hardware tested on actual PIC18F45K22
- [ ] UART communication verified
- [ ] All three AI levels tested
- [ ] Special moves (castling, en passant, promotion) verified
- [ ] Checkmate/stalemate detection verified
- [ ] README and USER_MANUAL updated

---

## Resources

### Documentation
- [PIC18F45K22 Datasheet](https://www.microchip.com/en-us/product/PIC18F45K22)
- [MPASM Assembler Guide](https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide)
- [PICkit 3 User Guide](https://www.microchip.com/en-us/development-tool/PG164130)

### Tools
- [MPLAB X IDE](https://www.microchip.com/mplab/mplab-x-ide)
- [MPLAB IPE](https://www.microchip.com/mplab/mplab-integrated-programming-environment)

### Community
- [Microchip Forums](https://www.microchip.com/forums/)
- [Chess Programming Wiki](https://www.chessprogramming.org/)

---

**Good luck with your development! 🛠️**
