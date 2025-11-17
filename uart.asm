; ============================================================================
; uart.asm - UART Communication Module
; Chess Engine Project
; ============================================================================
; This module handles UART serial communication for the chess engine.
; Configuration: 9600 baud, 8N1 (8 data bits, no parity, 1 stop bit)
;
; Functions:
;   - uart_init:        Initialize UART hardware
;   - uart_tx_byte:     Transmit single byte
;   - uart_rx_byte:     Receive single byte (blocking)
;   - uart_tx_string:   Transmit null-terminated string
;   - uart_tx_newline:  Transmit CR+LF
;   - uart_available:   Check if data available
; ============================================================================

    #include "config.inc"
    #include "definitions.inc"
    #include "memory.inc"

; ============================================================================
; uart_init - Initialize UART for 9600 baud, 8N1
;
; Input:  None
; Output: None
; Modifies: WREG
; Notes:  Assumes 16 MHz oscillator
;         SPBRG = (Fosc / (64 * Baud)) - 1
;         SPBRG = (16000000 / (64 * 9600)) - 1 = 25.04 ≈ 25
;         Actual baud = 16000000 / (64 * (25+1)) = 9615 baud (0.16% error)
; ============================================================================
uart_init:
    ; Configure USART for asynchronous mode
    BCF     TRISC, TRISC7       ; RC7 = TX (output)
    BSF     TRISC, TRISC6       ; RC6 = RX (input)

    ; Baud rate configuration (9600 baud @ 16 MHz)
    MOVLW   25                  ; SPBRG value for 9600 baud
    MOVWF   SPBRG1              ; Load baud rate generator
    CLRF    SPBRGH1             ; High byte = 0

    ; TXSTA configuration
    BCF     TXSTA1, TX9         ; 8-bit transmission
    BSF     TXSTA1, TXEN        ; Enable transmitter
    BCF     TXSTA1, SYNC        ; Asynchronous mode
    BCF     TXSTA1, BRGH        ; Low speed mode

    ; RCSTA configuration
    BSF     RCSTA1, SPEN        ; Serial port enabled
    BCF     RCSTA1, RX9         ; 8-bit reception
    BSF     RCSTA1, CREN        ; Enable continuous receive

    ; BAUDCON configuration
    BCF     BAUDCON1, BRG16     ; 8-bit baud rate generator

    ; Clear buffer pointers
    CLRF    uart_rx_head
    CLRF    uart_rx_tail
    CLRF    uart_tx_head
    CLRF    uart_tx_tail

    RETURN

; ============================================================================
; uart_tx_byte - Transmit single byte
;
; Input:  WREG = byte to transmit
; Output: None
; Modifies: None
; Notes:  Blocking - waits for transmit buffer to be empty
; ============================================================================
uart_tx_byte:
    ; Wait for transmit buffer to be empty
uart_tx_wait:
    BTFSS   PIR1, TX1IF         ; Check TXIF (transmit buffer empty flag)
    GOTO    uart_tx_wait        ; Wait if buffer full

    ; Transmit byte
    MOVWF   TXREG1              ; Load transmit register

    RETURN

; ============================================================================
; uart_rx_byte - Receive single byte (blocking)
;
; Input:  None
; Output: WREG = received byte
; Modifies: WREG
; Notes:  Blocking - waits for data to be available
; ============================================================================
uart_rx_byte:
    ; Wait for data to be available
uart_rx_wait:
    BTFSS   PIR1, RC1IF         ; Check RCIF (receive buffer full flag)
    GOTO    uart_rx_wait        ; Wait if no data

    ; Check for errors
    BTFSC   RCSTA1, OERR        ; Overrun error?
    GOTO    uart_rx_clear_error

    BTFSC   RCSTA1, FERR        ; Framing error?
    GOTO    uart_rx_read_discard

    ; Read data
    MOVF    RCREG1, W           ; Read received data
    RETURN

uart_rx_clear_error:
    ; Clear overrun error by resetting CREN
    BCF     RCSTA1, CREN
    BSF     RCSTA1, CREN
    GOTO    uart_rx_byte        ; Try again

uart_rx_read_discard:
    ; Discard erroneous data
    MOVF    RCREG1, W
    GOTO    uart_rx_byte        ; Try again

; ============================================================================
; uart_available - Check if received data is available
;
; Input:  None
; Output: WREG = 1 if data available, 0 if not
;         Z flag set if no data, cleared if data available
; Modifies: WREG
; ============================================================================
uart_available:
    BTFSC   PIR1, RC1IF         ; Check RCIF
    GOTO    uart_avail_yes

    ; No data
    CLRF    WREG
    RETURN

uart_avail_yes:
    MOVLW   0x01
    RETURN

; ============================================================================
; uart_tx_string - Transmit null-terminated string from program memory
;
; Input:  TBLPTRL, TBLPTRH, TBLPTRU = pointer to string in program memory
; Output: None
; Modifies: WREG, TABLAT, TBLPTR
; ============================================================================
uart_tx_string:
    TBLRD*+                     ; Read byte from program memory, increment
    MOVF    TABLAT, W           ; Get byte
    BZ      uart_tx_string_done ; If null, we're done

    CALL    uart_tx_byte        ; Transmit byte
    GOTO    uart_tx_string      ; Continue with next byte

uart_tx_string_done:
    RETURN

; ============================================================================
; uart_tx_string_ram - Transmit null-terminated string from RAM
;
; Input:  FSR2 = pointer to string in RAM
; Output: None
; Modifies: WREG, FSR2
; ============================================================================
uart_tx_string_ram:
    MOVF    POSTINC2, W         ; Get byte, increment pointer
    BZ      uart_tx_str_ram_done; If null, we're done

    CALL    uart_tx_byte        ; Transmit byte
    GOTO    uart_tx_string_ram  ; Continue

uart_tx_str_ram_done:
    RETURN

; ============================================================================
; uart_tx_newline - Transmit CR+LF (carriage return + line feed)
;
; Input:  None
; Output: None
; Modifies: WREG
; ============================================================================
uart_tx_newline:
    MOVLW   ASCII_CR
    CALL    uart_tx_byte
    MOVLW   ASCII_LF
    CALL    uart_tx_byte
    RETURN

; ============================================================================
; uart_tx_space - Transmit space character
;
; Input:  None
; Output: None
; Modifies: WREG
; ============================================================================
uart_tx_space:
    MOVLW   ASCII_SPACE
    CALL    uart_tx_byte
    RETURN

; ============================================================================
; uart_rx_line - Receive a line of text (until CR or LF)
;
; Input:  FSR2 = pointer to buffer
;         temp1 = buffer size
; Output: temp2 = number of characters received
; Modifies: WREG, FSR2, temp1, temp2
; Notes:  Blocking function
; ============================================================================
uart_rx_line:
    CLRF    temp2               ; Character count = 0

uart_rx_line_loop:
    CALL    uart_rx_byte        ; Get character

    ; Check for CR or LF
    SUBLW   ASCII_CR
    BZ      uart_rx_line_done

    MOVF    WREG, F             ; Restore WREG (subtract destroyed it)
    SUBLW   ASCII_LF
    BZ      uart_rx_line_done

    ; Check for backspace (optional - handle delete)
    MOVF    WREG, W
    SUBLW   0x08                ; Backspace
    BZ      uart_rx_line_backspace

    ; Regular character - add to buffer
    MOVF    WREG, W
    MOVWF   POSTINC2            ; Store in buffer, increment pointer
    INCF    temp2, F            ; Increment count

    ; Echo character
    CALL    uart_tx_byte

    ; Check buffer size
    MOVF    temp2, W
    SUBWF   temp1, W            ; buffer_size - count
    BNZ     uart_rx_line_loop   ; Continue if not full

uart_rx_line_done:
    ; Null-terminate string
    CLRF    INDF2
    RETURN

uart_rx_line_backspace:
    ; Handle backspace (if count > 0)
    MOVF    temp2, F
    BZ      uart_rx_line_loop   ; Ignore if buffer empty

    ; Remove last character
    DECF    FSR2L, F            ; Move pointer back
    DECF    temp2, F            ; Decrement count

    ; Echo backspace sequence
    MOVLW   0x08                ; Backspace
    CALL    uart_tx_byte
    MOVLW   ' '                 ; Space (erase)
    CALL    uart_tx_byte
    MOVLW   0x08                ; Backspace again
    CALL    uart_tx_byte

    GOTO    uart_rx_line_loop

; ============================================================================
; uart_print_hex - Print byte as two hex digits
;
; Input:  WREG = byte to print
; Output: None
; Modifies: WREG, temp1, temp2
; ============================================================================
uart_print_hex:
    MOVWF   temp1               ; Save byte

    ; Print high nibble
    SWAPF   temp1, W            ; Get high nibble
    ANDLW   0x0F
    CALL    uart_hex_digit

    ; Print low nibble
    MOVF    temp1, W
    ANDLW   0x0F
    CALL    uart_hex_digit

    RETURN

uart_hex_digit:
    ; Convert nibble (0-F) to ASCII
    SUBLW   0x09
    BC      uart_hex_digit_num  ; 0-9

    ; A-F
    MOVF    WREG, W
    ADDLW   'A' - 10
    GOTO    uart_hex_send

uart_hex_digit_num:
    ADDLW   '0'

uart_hex_send:
    CALL    uart_tx_byte
    RETURN

; ============================================================================
; uart_print_dec - Print byte as decimal (0-255)
;
; Input:  WREG = byte to print
; Output: None
; Modifies: WREG, temp1, temp2, temp3
; ============================================================================
uart_print_dec:
    MOVWF   temp1               ; Save value
    CLRF    temp2               ; Hundreds digit
    CLRF    temp3               ; Tens digit

    ; Count hundreds
uart_dec_100:
    MOVLW   100
    SUBWF   temp1, W
    BNC     uart_dec_10         ; If result negative, done with hundreds
    MOVWF   temp1               ; Update remainder
    INCF    temp2, F            ; Increment hundreds
    GOTO    uart_dec_100

uart_dec_10:
    ; Count tens
    MOVLW   10
    SUBWF   temp1, W
    BNC     uart_dec_print      ; If result negative, done with tens
    MOVWF   temp1               ; Update remainder
    INCF    temp3, F            ; Increment tens
    GOTO    uart_dec_10

uart_dec_print:
    ; Print hundreds (if non-zero or if printing larger numbers)
    MOVF    temp2, F
    BZ      uart_dec_skip_100

    MOVF    temp2, W
    ADDLW   '0'
    CALL    uart_tx_byte

uart_dec_skip_100:
    ; Print tens (if non-zero or if we printed hundreds)
    MOVF    temp3, F
    BZ      uart_dec_check_tens

    MOVF    temp3, W
    ADDLW   '0'
    CALL    uart_tx_byte
    GOTO    uart_dec_ones

uart_dec_check_tens:
    ; Print tens if we printed hundreds
    MOVF    temp2, F
    BZ      uart_dec_ones

    MOVF    temp3, W
    ADDLW   '0'
    CALL    uart_tx_byte

uart_dec_ones:
    ; Always print ones
    MOVF    temp1, W
    ADDLW   '0'
    CALL    uart_tx_byte

    RETURN

; ============================================================================
; End of uart.asm
; ============================================================================
