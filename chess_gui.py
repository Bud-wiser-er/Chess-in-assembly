#!/usr/bin/env python3
"""
PIC18F45K22 Chess Engine - Python GUI Interface
================================================

This program provides a graphical interface to communicate with the
PIC18F45K22 chess engine via serial port using FEN notation.

Features:
- Display chess board in terminal (ASCII art)
- Make moves using UCI notation (e.g., 'e2e4')
- Send FEN to PIC microcontroller
- Receive FEN from PIC (AI response)
- Full FEN parsing and validation
- Simulated mode for testing without hardware

Requirements:
- python-chess: pip install python-chess
- pyserial: pip install pyserial

Usage:
    python chess_gui.py              # Simulated mode (no hardware)
    python chess_gui.py /dev/ttyUSB0 # Hardware mode with serial port
"""

import sys
import time
import chess
import chess.pgn

try:
    import serial
    SERIAL_AVAILABLE = True
except ImportError:
    print("Warning: pyserial not installed. Running in simulated mode only.")
    print("Install with: pip install pyserial")
    SERIAL_AVAILABLE = False


class ChessGUI:
    """Chess GUI for PIC18F45K22 communication"""

    def __init__(self, port=None, baudrate=9600, simulated=False):
        """
        Initialize chess GUI

        Args:
            port: Serial port name (e.g., '/dev/ttyUSB0', 'COM3')
            baudrate: Serial baud rate (default: 9600)
            simulated: Run in simulated mode without serial connection
        """
        self.board = chess.Board()
        self.port = port
        self.baudrate = baudrate
        self.simulated = simulated
        self.serial_conn = None
        self.move_history = []

        # Connect to serial port if not simulated
        if not simulated and port:
            self._connect_serial()

    def _connect_serial(self):
        """Connect to serial port"""
        if not SERIAL_AVAILABLE:
            print("ERROR: pyserial not available. Install with: pip install pyserial")
            self.simulated = True
            return

        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=5.0
            )
            print(f"✓ Connected to {self.port} at {self.baudrate} baud")
            time.sleep(2)  # Wait for Arduino/PIC reset
        except Exception as e:
            print(f"ERROR: Could not connect to {self.port}: {e}")
            print("Running in simulated mode...")
            self.simulated = True

    def send_fen(self, fen=None):
        """
        Send FEN string to PIC via serial

        Args:
            fen: FEN string (uses current board if None)
        """
        if fen is None:
            fen = self.board.fen()

        if self.simulated:
            print(f"[SIMULATED] Sending FEN: {fen}")
            return True

        try:
            # Send FEN with newline
            message = f"{fen}\r\n"
            self.serial_conn.write(message.encode('ascii'))
            self.serial_conn.flush()
            print(f"→ Sent FEN: {fen}")
            return True
        except Exception as e:
            print(f"ERROR: Failed to send FEN: {e}")
            return False

    def receive_fen(self, timeout=30.0):
        """
        Receive FEN string from PIC via serial

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            FEN string or None on timeout/error
        """
        if self.simulated:
            # In simulated mode, make a random legal move
            print("[SIMULATED] AI thinking...")
            time.sleep(0.5)
            legal_moves = list(self.board.legal_moves)
            if legal_moves:
                move = legal_moves[0]  # Just take first legal move
                self.board.push(move)
                fen = self.board.fen()
                print(f"[SIMULATED] AI moved: {move}")
                print(f"[SIMULATED] Received FEN: {fen}")
                return fen
            return None

        try:
            self.serial_conn.timeout = timeout
            line = self.serial_conn.readline().decode('ascii').strip()

            if line:
                print(f"← Received FEN: {line}")
                return line
            else:
                print("WARNING: No response from PIC (timeout)")
                return None
        except Exception as e:
            print(f"ERROR: Failed to receive FEN: {e}")
            return None

    def display_board(self):
        """Display chess board in terminal"""
        print("\n" + "="*50)
        print(self.board)
        print("="*50)
        print(f"FEN: {self.board.fen()}")
        print(f"Turn: {'White' if self.board.turn == chess.WHITE else 'Black'}")

        # Check game status
        if self.board.is_checkmate():
            print("🏁 CHECKMATE!")
        elif self.board.is_stalemate():
            print("🏁 STALEMATE!")
        elif self.board.is_check():
            print("⚠️  CHECK!")

        print("="*50 + "\n")

    def set_position_from_fen(self, fen):
        """
        Set board position from FEN string

        Args:
            fen: FEN string

        Returns:
            True if successful, False otherwise
        """
        try:
            self.board = chess.Board(fen)
            print(f"✓ Position set from FEN: {fen}")
            return True
        except ValueError as e:
            print(f"ERROR: Invalid FEN: {e}")
            return False

    def make_user_move(self, move_str):
        """
        Make a move on the board

        Args:
            move_str: Move in UCI notation (e.g., 'e2e4', 'e7e8q')

        Returns:
            True if move was legal and made, False otherwise
        """
        try:
            move = chess.Move.from_uci(move_str)

            if move in self.board.legal_moves:
                self.board.push(move)
                self.move_history.append(move)
                print(f"✓ Move made: {move_str}")
                return True
            else:
                print(f"ERROR: Illegal move: {move_str}")
                print(f"Legal moves: {', '.join([m.uci() for m in self.board.legal_moves])}")
                return False
        except ValueError:
            print(f"ERROR: Invalid move format: {move_str}")
            print("Use UCI notation like 'e2e4' or 'e7e8q' (for promotion)")
            return False

    def sync_with_pic(self):
        """
        Synchronize position with PIC
        - Send current FEN to PIC
        - Receive updated FEN from PIC (after AI move)
        """
        print("\n📡 Syncing with PIC...")

        # Send current position
        if not self.send_fen():
            return False

        # Wait for AI response
        print("⏳ Waiting for AI response...")
        fen = self.receive_fen(timeout=30.0)

        if fen:
            # Update board with AI's move
            self.set_position_from_fen(fen)
            return True
        else:
            print("ERROR: No response from PIC")
            return False

    def run_interactive(self):
        """Run interactive chess session"""
        print("\n" + "="*50)
        print("  PIC18F45K22 Chess Engine - Python Interface")
        print("="*50)

        if self.simulated:
            print("⚠️  Running in SIMULATED mode (no hardware)")
        else:
            print(f"✓ Connected to {self.port}")

        print("\nCommands:")
        print("  <move>     - Make a move (e.g., 'e2e4')")
        print("  fen <fen>  - Set position from FEN")
        print("  show       - Display current board")
        print("  sync       - Sync with PIC (send FEN, get AI move)")
        print("  new        - New game")
        print("  quit       - Exit")
        print("="*50)

        self.display_board()

        while True:
            try:
                # Get user input
                cmd = input("\nYour move > ").strip()

                if not cmd:
                    continue

                # Parse command
                parts = cmd.lower().split()

                if parts[0] == 'quit' or parts[0] == 'exit':
                    print("Goodbye!")
                    break

                elif parts[0] == 'show':
                    self.display_board()

                elif parts[0] == 'new':
                    self.board = chess.Board()
                    self.move_history = []
                    print("✓ New game started")
                    self.display_board()

                elif parts[0] == 'fen':
                    if len(parts) > 1:
                        fen = ' '.join(parts[1:])
                        if self.set_position_from_fen(fen):
                            self.display_board()
                    else:
                        print(f"Current FEN: {self.board.fen()}")

                elif parts[0] == 'sync':
                    if self.sync_with_pic():
                        self.display_board()

                else:
                    # Treat as move
                    if self.make_user_move(cmd):
                        self.display_board()

                        # Auto-sync with PIC after user move
                        if self.sync_with_pic():
                            self.display_board()

            except KeyboardInterrupt:
                print("\n\nInterrupted. Goodbye!")
                break
            except Exception as e:
                print(f"ERROR: {e}")

    def close(self):
        """Close serial connection"""
        if self.serial_conn:
            self.serial_conn.close()
            print("Serial connection closed")


def run_tests():
    """Run automated tests of the chess GUI"""
    print("\n" + "="*60)
    print("  RUNNING AUTOMATED TESTS")
    print("="*60)

    # Test 1: Board initialization
    print("\nTest 1: Board Initialization")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    gui.display_board()
    assert gui.board.fen() == chess.STARTING_FEN
    print("✓ PASS: Board initialized to starting position")

    # Test 2: FEN parsing
    print("\nTest 2: FEN Parsing")
    print("-" * 40)
    test_fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    assert gui.set_position_from_fen(test_fen)
    gui.display_board()
    assert gui.board.fen() == test_fen
    print("✓ PASS: FEN parsing works correctly")

    # Test 3: Legal move
    print("\nTest 3: Legal Move")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    assert gui.make_user_move("e2e4")
    gui.display_board()
    print("✓ PASS: Legal move executed")

    # Test 4: Illegal move rejection
    print("\nTest 4: Illegal Move Rejection")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    assert not gui.make_user_move("e2e5")  # Illegal pawn move
    print("✓ PASS: Illegal move rejected")

    # Test 5: FEN generation
    print("\nTest 5: FEN Generation")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    gui.make_user_move("e2e4")
    fen = gui.board.fen()
    expected_fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    assert fen == expected_fen
    print(f"Generated FEN: {fen}")
    print("✓ PASS: FEN generation works correctly")

    # Test 6: Simulated FEN send/receive
    print("\nTest 6: Simulated FEN Communication")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    gui.send_fen()
    fen = gui.receive_fen()
    assert fen is not None
    print("✓ PASS: Simulated FEN send/receive works")

    # Test 7: Game sequence
    print("\nTest 7: Complete Game Sequence")
    print("-" * 40)
    gui = ChessGUI(simulated=True)
    moves = ["e2e4", "e7e5", "g1f3", "b8c6", "f1c4"]
    for move in moves:
        assert gui.make_user_move(move)
        print(f"  Move: {move}")
    gui.display_board()
    print("✓ PASS: Complete game sequence works")

    # Test 8: Checkmate detection
    print("\nTest 8: Checkmate Detection")
    print("-" * 40)
    # Fool's mate position
    gui = ChessGUI(simulated=True)
    gui.make_user_move("f2f3")
    gui.make_user_move("e7e5")
    gui.make_user_move("g2g4")
    gui.make_user_move("d8h4")
    gui.display_board()
    assert gui.board.is_checkmate()
    print("✓ PASS: Checkmate detected correctly")

    # Test 9: Promotion
    print("\nTest 9: Pawn Promotion")
    print("-" * 40)
    promotion_fen = "8/P7/8/8/8/8/8/4K2k w - - 0 1"
    gui.set_position_from_fen(promotion_fen)
    gui.make_user_move("a7a8q")
    gui.display_board()
    assert gui.board.piece_at(chess.A8) == chess.Piece(chess.QUEEN, chess.WHITE)
    print("✓ PASS: Pawn promotion works")

    # Test 10: FEN roundtrip
    print("\nTest 10: FEN Roundtrip")
    print("-" * 40)
    test_positions = [
        chess.STARTING_FEN,
        "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
        "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
    ]
    for fen in test_positions:
        gui.set_position_from_fen(fen)
        generated_fen = gui.board.fen()
        assert generated_fen == fen
        print(f"  ✓ {fen[:30]}...")
    print("✓ PASS: FEN roundtrip works for all positions")

    print("\n" + "="*60)
    print("  ALL TESTS PASSED! ✓")
    print("="*60)


def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        if sys.argv[1] == '--test':
            # Run tests
            run_tests()
            return
        else:
            # Hardware mode with serial port
            port = sys.argv[1]
            gui = ChessGUI(port=port, simulated=False)
    else:
        # Simulated mode (no hardware)
        print("No serial port specified. Running in simulated mode.")
        print("Usage: python chess_gui.py <serial_port>")
        print("Example: python chess_gui.py /dev/ttyUSB0")
        print("         python chess_gui.py COM3")
        print("         python chess_gui.py --test  (run automated tests)")
        print()
        gui = ChessGUI(simulated=True)

    try:
        gui.run_interactive()
    finally:
        gui.close()


if __name__ == '__main__':
    main()
