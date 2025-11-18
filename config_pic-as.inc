; ============================================================================
; config.inc - PIC18F45K22 Configuration for PIC-AS
; Chess Engine Project
; ============================================================================
; NOTE: This file uses PIC-AS syntax (MPLAB X v5.40+)
; File extension should be .inc
; ============================================================================

; Configuration Word 1
    CONFIG FOSC = INTIO67        ; Internal oscillator block
    CONFIG PLLCFG = OFF          ; Oscillator used directly
    CONFIG PRICLKEN = ON         ; Primary clock enabled
    CONFIG FCMEN = OFF           ; Fail-Safe Clock Monitor disabled
    CONFIG IESO = OFF            ; Oscillator Switchover mode disabled
    CONFIG PWRTEN = ON           ; Power up timer enabled
    CONFIG BOREN = SBORDIS       ; Brown-out Reset enabled in hardware only
    CONFIG BORV = 190            ; VBOR set to 1.90 V nominal
    CONFIG WDTEN = OFF           ; Watch dog timer is always disabled
    CONFIG WDTPS = 32768         ; 1:32768
    CONFIG CCP2MX = PORTC1       ; CCP2 input/output is multiplexed with RC1
    CONFIG PBADEN = OFF          ; PORTB<5:0> pins are configured as digital I/O
    CONFIG CCP3MX = PORTB5       ; P3A/CCP3 input/output is multiplexed with RB5
    CONFIG HFOFST = ON           ; HFINTOSC output and ready status are not delayed
    CONFIG T3CMX = PORTC0        ; T3CKI is on RC0
    CONFIG P2BMX = PORTD2        ; P2B is on RD2
    CONFIG MCLRE = EXTMCLR       ; MCLR pin enabled, RE3 input pin disabled
    CONFIG STVREN = ON           ; Stack full/underflow will cause Reset
    CONFIG LVP = OFF             ; Single-Supply ICSP disabled
    CONFIG XINST = OFF           ; Instruction set extension and Indexed Addressing mode disabled
    CONFIG DEBUG = OFF           ; Disabled
    CONFIG CP0 = OFF             ; Block 0 not code-protected
    CONFIG CP1 = OFF             ; Block 1 not code-protected
    CONFIG CP2 = OFF             ; Block 2 not code-protected
    CONFIG CP3 = OFF             ; Block 3 not code-protected
    CONFIG CPB = OFF             ; Boot block not code-protected
    CONFIG CPD = OFF             ; Data EEPROM not code-protected
    CONFIG WRT0 = OFF            ; Block 0 not write-protected
    CONFIG WRT1 = OFF            ; Block 1 not write-protected
    CONFIG WRT2 = OFF            ; Block 2 not write-protected
    CONFIG WRT3 = OFF            ; Block 3 not write-protected
    CONFIG WRTC = OFF            ; Configuration registers not write-protected
    CONFIG WRTB = OFF            ; Boot Block not write-protected
    CONFIG WRTD = OFF            ; Data EEPROM not write-protected
    CONFIG EBTR0 = OFF           ; Block 0 not protected from table reads
    CONFIG EBTR1 = OFF           ; Block 1 not protected from table reads
    CONFIG EBTR2 = OFF           ; Block 2 not protected from table reads
    CONFIG EBTR3 = OFF           ; Block 3 not protected from table reads
    CONFIG EBTRB = OFF           ; Boot Block not protected from table reads

; ============================================================================
; End of config.inc
; ============================================================================
