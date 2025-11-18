# Migration Guide: MPASM to PIC-AS

## ⚠️ IMPORTANT NOTICE

**MPASM has been deprecated by Microchip!**

Starting with **MPLAB X IDE v5.40 and later**, the MPASM assembler is **NO LONGER INCLUDED**. You must use the **PIC-AS assembler** (part of MPLAB XC8 compiler suite).

---

## What Changed?

### Old Toolchain (Deprecated)
- **Assembler**: MPASM (mpasmwin)
- **File Extension**: `.asm`
- **Include Files**: Device-specific (e.g., `p18f45k22.inc`)
- **Last Supported**: MPLAB X v5.35

### New Toolchain (Current)
- **Assembler**: PIC-AS (pic-as, part of XC8)
- **File Extension**: `.S` (capital S)
- **Include Files**: Generic `<xc.inc>`
- **Required**: MPLAB X v5.40+ with XC8 compiler

---

## Quick Conversion Reference

| MPASM (Old) | PIC-AS (New) | Notes |
|-------------|--------------|-------|
| `filename.asm` | `filename.S` | Capital S extension |
| `LIST P=18F45K22` | `PROCESSOR 18F45K22` | Processor declaration |
| `#include <p18f45k22.inc>` | `#include <xc.inc>` | Generic include file |
| `ORG 0x0000` | `PSECT resetVec,class=CODE,reloc=2` | Section definition |
| `CBLOCK 0x000` ... `ENDC` | `PSECT udata_acs` + `DS` | Variable declaration |
| `variable RES 1` | `variable: DS 1` | Reserve space |
| `CONFIG ...` | `CONFIG ...` | Similar, but quoted values |
| `GOTO label` | `goto label` | Lowercase recommended |
| `banksel variable` | `BANKMASK(variable)` | Banking access |

---

## Detailed Syntax Changes

### 1. File Extension
```assembly
; Old MPASM
main.asm

; New PIC-AS
main.S    (capital S!)
```

### 2. Processor Declaration
```assembly
; Old MPASM
    LIST P=18F45K22
    #include <p18f45k22.inc>

; New PIC-AS
    PROCESSOR 18F45K22
    #include <xc.inc>
```

### 3. Configuration Bits
```assembly
; Old MPASM
    CONFIG  FOSC = INTIO67
    CONFIG  WDTEN = OFF

; New PIC-AS (similar, but may use quoted strings for complex values)
    CONFIG FOSC = INTIO67
    CONFIG WDTEN = OFF
```

### 4. Code Sections
```assembly
; Old MPASM
    ORG 0x0000
    GOTO start

    ORG 0x0008
    RETFIE

; New PIC-AS
PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto    start

PSECT intVec,class=CODE,reloc=2
intVec:
    retfie
```

### 5. Variable Declarations
```assembly
; Old MPASM
    CBLOCK 0x000
        temp1
        temp2
        temp3
    ENDC

; New PIC-AS
PSECT udata_acs
    temp1:      DS 1
    temp2:      DS 1
    temp3:      DS 1
```

### 6. Data Tables in Program Memory
```assembly
; Old MPASM
    ORG 0x1000
my_table:
    DB  0x01, 0x02, 0x03
    DB  "Hello", 0

; New PIC-AS
PSECT myTable,class=CODE
my_table:
    DB  0x01, 0x02, 0x03
    DB  "Hello", 0
```

### 7. Banked Memory Access
```assembly
; Old MPASM
    BANKSEL variable
    MOVF    variable, W

; New PIC-AS (use BANKMASK macro)
    MOVF    BANKMASK(variable), W
```

### 8. Access Bank Variables
```assembly
; New PIC-AS - Variables in access bank (0x000-0x05F)
PSECT udata_acs
    fast_var:   DS 1    ; No banking required

; Banked RAM (above 0x05F)
PSECT udata_bank0
    slow_var:   DS 1    ; Banking may be needed
```

### 9. Case Sensitivity
```assembly
; PIC-AS is more strict about case
; Recommend using lowercase for instructions:

; Recommended
    movlw   0x10
    movwf   OSCCON
    goto    main_loop
    bra     next_section

; Also works but inconsistent
    MOVLW   0x10
    GOTO    main_loop
```

---

## Converting the Chess Engine Project

### Step 1: Install Required Tools
1. **Download MPLAB X IDE v6.0+**
   - [https://www.microchip.com/mplab/mplab-x-ide](https://www.microchip.com/mplab/mplab-x-ide)

2. **Download MPLAB XC8 Compiler**
   - [https://www.microchip.com/mplab/compilers](https://www.microchip.com/mplab/compilers)
   - PIC-AS is included with XC8

3. **Verify Installation**
   - Open MPLAB X IDE
   - Tools → Options → Embedded
   - Check that XC8 is listed

### Step 2: Create New Project
1. **File → New Project**
2. **Microchip Embedded → Standalone Project**
3. **Device**: PIC18F45K22
4. **Tool**: PICkit 3/4 or Simulator
5. **Compiler**: XC8 (select XC8 Compiler, not MPASM!)
6. **Project Name**: Chess-Engine-PIC18F45K22

### Step 3: Convert Source Files

#### Option A: Use Provided PIC-AS Files
- Use `main.S` (already converted)
- Use `config_pic-as.inc` for configuration

#### Option B: Convert Manually
For each `.asm` file:
1. Rename `filename.asm` → `filename.S`
2. Change `LIST P=18F45K22` → `PROCESSOR 18F45K22`
3. Change `#include <p18f45k22.inc>` → `#include <xc.inc>`
4. Convert `ORG` to `PSECT`
5. Convert `CBLOCK/ENDC` to `PSECT` + `DS`
6. Add `BANKMASK()` where needed
7. Review and test

### Step 4: Project Configuration
1. **Right-click project → Properties**
2. **pic-as Global Options**:
   - Preprocessor macros: (none needed)
   - Additional options: (leave default)
3. **pic-as Assembler**:
   - Include directories: Add project folder if needed

### Step 5: Build and Test
1. **Clean and Build** (hammer icon)
2. Check **Output** window for errors
3. Fix any remaining syntax issues
4. **Make and Program Device**

---

## Common Conversion Errors

### Error 1: "Unknown directive: LIST"
```
Error: Unknown directive: LIST
```
**Fix**: Change `LIST P=18F45K22` to `PROCESSOR 18F45K22`

### Error 2: "Can't open include file"
```
Error: Can't open include file "p18f45k22.inc"
```
**Fix**: Change to `#include <xc.inc>`

### Error 3: "Unknown directive: CBLOCK"
```
Error: Unknown directive: CBLOCK
```
**Fix**: Use `PSECT udata_acs` with `DS` directives instead

### Error 4: "Unknown directive: ORG"
```
Error: Unknown directive: ORG
```
**Fix**: Use `PSECT` with appropriate class and flags

### Error 5: "Fixup overflow in expression"
```
Error: Fixup overflow in expression
```
**Fix**: Use `BANKMASK()` macro for banked RAM access

### Error 6: "Undefined symbol"
```
Error: Undefined symbol: PORTA
```
**Fix**: Make sure `#include <xc.inc>` is at top of file

---

## Status of Chess Engine Conversion

### ✅ Converted Files
- `main.S` - Main program (PIC-AS syntax)
- `config_pic-as.inc` - Configuration bits

### 🚧 Files Needing Conversion
The following files are in MPASM syntax and need conversion:
- `board.asm` → `board.S`
- `uart.asm` → `uart.S`
- `movegen.asm` → `movegen.S`
- `makemove.asm` → `makemove.S`
- `check.asm` → `check.S`
- `evaluate.asm` → `evaluate.S`
- `ai_level1.asm` → `ai_level1.S`
- `ai_level2.asm` → `ai_level2.S`
- `ai_level3.asm` → `ai_level3.S`
- `display.asm` → `display.S`
- `parser.asm` → `parser.S`

### Conversion Approach

**Recommended**: Convert modules one at a time:
1. Start with `board.S` (foundation)
2. Then `uart.S` (for testing output)
3. Convert remaining modules
4. Test each module as you convert
5. Link all modules together

---

## PIC-AS Resources

### Official Documentation
- **MPLAB XC8 PIC Assembler User's Guide**
  - Document: DS50002974
  - Latest version available at microchip.com

- **MPLAB XC8 C Compiler User's Guide**
  - Includes pic-as documentation
  - Configuration bits reference

### Online Resources
- **Microchip Developer Help**: [https://microchipdeveloper.com](https://microchipdeveloper.com)
- **MPLAB X IDE User's Guide**: Embedded → Assembler Topics
- **PIC18 Device Include Files**: Located in XC8 installation directory
  - `C:\Program Files\Microchip\xc8\v2.xx\pic\include\proc\`

### Example Projects
- **GitHub**: Search for "PIC-AS examples" or "pic18 .S files"
- **Microchip Code Examples**: Filter by PIC-AS/XC8

---

## Migration Checklist

Use this checklist when converting the chess engine:

### Preparation
- [ ] MPLAB X IDE v5.40+ installed
- [ ] MPLAB XC8 compiler installed
- [ ] Verified pic-as is available (Tools → Options)
- [ ] Backed up original MPASM `.asm` files

### Conversion
- [ ] Created new project with XC8 toolchain
- [ ] Renamed files: `.asm` → `.S`
- [ ] Updated processor declaration
- [ ] Changed include to `<xc.inc>`
- [ ] Converted ORG to PSECT
- [ ] Converted CBLOCK to PSECT + DS
- [ ] Added BANKMASK() where needed
- [ ] Reviewed configuration bits syntax

### Testing
- [ ] Project builds without errors
- [ ] No warnings about deprecated syntax
- [ ] Hex file generated successfully
- [ ] Code size within 32KB limit
- [ ] RAM usage within 1536 bytes

### Verification
- [ ] Programmed to PIC18F45K22 successfully
- [ ] UART communication working
- [ ] Board initialization correct
- [ ] Move generation functional
- [ ] AI levels operational
- [ ] Complete game playthrough successful

---

## Known Issues and Limitations

### Issue 1: Label Definitions
PIC-AS is stricter about label definitions. Ensure labels have colons:
```assembly
; May cause issues
my_function
    movlw 0x10

; Better
my_function:
    movlw 0x10
```

### Issue 2: Macro Syntax
Macro syntax has changed slightly. Refer to XC8 PIC Assembler User's Guide for details.

### Issue 3: Banking
PIC-AS handles banking differently. The `BANKMASK()` macro helps prevent fixup overflow errors.

### Issue 4: Configuration Bits
Some configuration bit names may have changed. Check the device-specific documentation in the XC8 installation folder.

---

## Support and Help

### If You Get Stuck
1. **Check Build Output**: Read error messages carefully
2. **Consult Documentation**: XC8 PIC Assembler User's Guide
3. **Search Online**: "PIC-AS" + your error message
4. **Microchip Forums**: [https://www.microchip.com/forums/](https://www.microchip.com/forums/)

### Recommended Learning Path
1. **Start Small**: Convert one simple file first (e.g., `board.S`)
2. **Build Often**: Test after each module conversion
3. **Compare**: Keep MPASM version for reference
4. **Document**: Note any tricky conversions for later

---

## Summary

**MPASM is deprecated. Use PIC-AS for all new projects.**

Key Points:
- File extension: `.S` (capital S)
- Assembler: pic-as (part of XC8)
- Include: `<xc.inc>`
- Sections: Use `PSECT`
- Variables: Use `DS` directive
- Banking: Use `BANKMASK()` macro

The chess engine code is provided in **both formats** for educational purposes:
- `.asm` files: **Legacy MPASM** (for reference only, won't build on modern MPLAB X)
- `.S` files: **Modern PIC-AS** (use these for actual development)

**Start with `main.S` as your template for converting the remaining modules!**

---

## Version History
- v1.0 (2025): Initial migration guide
- Original MPASM code provided for reference
- PIC-AS conversion in progress

**Good luck with your conversion!** 🛠️
