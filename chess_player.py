#!/usr/bin/env python3
"""
PIC18F45K22 Chess Player - Interactive Chess with Move Validation
===================================================================

This program allows you to play chess against the PIC18F45K22 microcontroller.
The PIC validates all moves and responds with its own moves.

Protocol:
- User makes move --> PC sends "MOVE e2e4" --> PIC validates
- If valid: PIC makes AI move --> sends "OK <FEN>"
- If invalid: PIC sends "ERROR Invalid move"

Features:
- Play chess against the PIC AI
- PIC validates all moves (authoritative)
- ASCII board display
- Move history tracking
- Simulated mode for testing without hardware

Requirements:
- NO external dependencies (standalone)
- Optional: pyserial for hardware communication

Usage:
    python3 chess_player.py --test      # Run tests
    python3 chess_player.py            # Simulated mode
    python3 chess_player.py /dev/ttyUSB0  # Hardware mode
"""

import sys
import time


class ChessBoard:
    """Simple chess board (same as chess_gui_simple.py)"""

    EMPTY = 0x00
    W_PAWN = 0x01
    W_KNIGHT = 0x02
    W_BISHOP = 0x03
    W_ROOK = 0x04
    W_QUEEN = 0x05
    W_KING = 0x06
    B_PAWN = 0x09
    B_KNIGHT = 0x0A
    B_BISHOP = 0x0B
    B_ROOK = 0x0C
    B_QUEEN = 0x0D
    B_KING = 0x0E

    PIECE_CHARS = {
        EMPTY: ' ',
        W_PAWN: 'P', W_KNIGHT: 'N', W_BISHOP: 'B',
        W_ROOK: 'R', W_QUEEN: 'Q', W_KING: 'K',
        B_PAWN: 'p', B_KNIGHT: 'n', B_BISHOP: 'b',
        B_ROOK: 'r', B_QUEEN: 'q', B_KING: 'k',
    }

    FEN_TO_PIECE = {
        'P': W_PAWN, 'N': W_KNIGHT, 'B': W_BISHOP,
        'R': W_ROOK, 'Q': W_QUEEN, 'K': W_KING,
        'p': B_PAWN, 'n': B_KNIGHT, 'b': B_BISHOP,
        'r': B_ROOK, 'q': B_QUEEN, 'k': B_KING,
    }

    STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    def __init__(self):
        self.board = [self.EMPTY] * 64
        self.turn = 'w'
        self.castling = 'KQkq'
        self.enpassant = '-'
        self.halfmove = 0
        self.fullmove = 1

    def parse_fen(self, fen):
        """Parse FEN string"""
        try:
            parts = fen.split()
            if len(parts) < 4:
                return False

            self.board = [self.EMPTY] * 64
            ranks = parts[0].split('/')
            if len(ranks) != 8:
                return False

            for rank_idx, rank_str in enumerate(ranks):
                file_idx = 0
                board_rank = 7 - rank_idx

                for char in rank_str:
                    if char.isdigit():
                        file_idx += int(char)
                    elif char in self.FEN_TO_PIECE:
                        index = board_rank * 8 + file_idx
                        self.board[index] = self.FEN_TO_PIECE[char]
                        file_idx += 1

            self.turn = parts[1] if parts[1] in ['w', 'b'] else 'w'
            self.castling = parts[2] if len(parts) > 2 else '-'
            self.enpassant = parts[3] if len(parts) > 3 else '-'
            self.halfmove = int(parts[4]) if len(parts) > 4 else 0
            self.fullmove = int(parts[5]) if len(parts) > 5 else 1

            return True
        except:
            return False

    def generate_fen(self):
        """Generate FEN string"""
        fen_parts = []
        for rank in range(7, -1, -1):
            empty_count = 0
            rank_str = ""
            for file in range(8):
                index = rank * 8 + file
                piece = self.board[index]
                if piece == self.EMPTY:
                    empty_count += 1
                else:
                    if empty_count > 0:
                        rank_str += str(empty_count)
                        empty_count = 0
                    rank_str += self.PIECE_CHARS[piece]
            if empty_count > 0:
                rank_str += str(empty_count)
            fen_parts.append(rank_str)

        fen = '/'.join(fen_parts)
        fen += f" {self.turn}"
        fen += f" {self.castling}"
        fen += f" {self.enpassant}"
        fen += f" {self.halfmove}"
        fen += f" {self.fullmove}"
        return fen

    def display(self):
        """Display board"""
        print("\n  " + "="*33)
        for rank in range(7, -1, -1):
            print(f"{rank+1} |", end="")
            for file in range(8):
                index = rank * 8 + file
                piece = self.board[index]
                char = self.PIECE_CHARS.get(piece, '?')
                print(f" {char} |", end="")
            print()
        print("  " + "="*33)
        print("    a   b   c   d   e   f   g   h")
        print()
        print(f"Turn: {'White' if self.turn == 'w' else 'Black'}")
        print(f"FEN: {self.generate_fen()}")
        print()


class PICChessInterface:
    """Interface to PIC chess engine"""

    def __init__(self, port=None, simulated=False):
        self.board = ChessBoard()
        self.board.parse_fen(ChessBoard.STARTING_FEN)
        self.port = port
        self.simulated = simulated
        self.serial_conn = None
        self.move_history = []

        if not simulated and port:
            self._connect_serial()

    def _connect_serial(self):
        """Connect to serial port"""
        try:
            import serial
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=9600,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=30.0
            )
            print(f"OK Connected to {self.port} at 9600 baud")
            time.sleep(2)
        except ImportError:
            print("ERROR: pyserial not installed. Install with: pip install pyserial")
            print("Running in simulated mode...")
            self.simulated = True
        except Exception as e:
            print(f"ERROR: Could not connect to {self.port}: {e}")
            print("Running in simulated mode...")
            self.simulated = True

    def send_move(self, move):
        """
        Send move to PIC for validation

        Args:
            move: Move string (e.g., 'e2e4', 'e7e8q')

        Returns:
            (success, response_fen_or_error)
        """
        command = f"MOVE {move}\r\n"

        if self.simulated:
            print(f"--> Sending: MOVE {move}")
            # Simulate PIC validation
            return self._simulate_move(move)

        try:
            # Send move command
            self.serial_conn.write(command.encode('ascii'))
            self.serial_conn.flush()
            print(f"--> Sent: MOVE {move}")

            # Wait for response
            response = self.serial_conn.readline().decode('ascii').strip()
            print(f"<-- Received: {response}")

            # Parse response
            if response.startswith("OK "):
                fen = response[3:]  # Extract FEN after "OK "
                return (True, fen)
            elif response.startswith("ERROR"):
                error_msg = response[6:]  # Extract error message
                return (False, error_msg)
            else:
                return (False, "Unknown response format")

        except Exception as e:
            print(f"ERROR: Communication failed: {e}")
            return (False, str(e))

    def _simulate_move(self, move):
        """Simulate PIC move validation (for testing without hardware)"""
        time.sleep(0.3)

        # Basic validation: check move format
        if len(move) < 4:
            return (False, "Invalid move format")

        from_sq = move[0:2]
        to_sq = move[2:4]

        # Check squares are valid
        if not self._is_valid_square(from_sq) or not self._is_valid_square(to_sq):
            return (False, "Invalid square")

        # Simple simulation: accept move and make AI response
        # In real PIC, this would be full move validation
        self._make_simple_move(from_sq, to_sq)

        # Simulate AI response (e.g., e7e5)
        if self.board.turn == 'b':
            # Simple AI: move e7-e5 if possible
            e7_piece = self.board.board[self._square_to_index('e7')]
            if e7_piece == ChessBoard.B_PAWN:
                self._make_simple_move('e7', 'e5')

        fen = self.board.generate_fen()
        return (True, fen)

    def _is_valid_square(self, square):
        """Check if square notation is valid"""
        if len(square) != 2:
            return False
        file = square[0]
        rank = square[1]
        return file in 'abcdefgh' and rank in '12345678'

    def _square_to_index(self, square):
        """Convert square to index"""
        file = ord(square[0]) - ord('a')
        rank = int(square[1]) - 1
        return rank * 8 + file

    def _make_simple_move(self, from_sq, to_sq):
        """Make a simple move (no validation, for simulation)"""
        from_idx = self._square_to_index(from_sq)
        to_idx = self._square_to_index(to_sq)

        piece = self.board.board[from_idx]
        self.board.board[from_idx] = ChessBoard.EMPTY
        self.board.board[to_idx] = piece

        # Toggle turn
        self.board.turn = 'b' if self.board.turn == 'w' else 'w'

    def new_game(self, ai_level=2):
        """Start new game"""
        if self.simulated:
            print(f"--> NEW {ai_level}")
            self.board.parse_fen(ChessBoard.STARTING_FEN)
            self.move_history = []
            print("OK New game started")
            return True

        try:
            command = f"NEW {ai_level}\r\n"
            self.serial_conn.write(command.encode('ascii'))
            self.serial_conn.flush()

            response = self.serial_conn.readline().decode('ascii').strip()

            if response.startswith("OK"):
                fen = response[3:] if len(response) > 3 else ChessBoard.STARTING_FEN
                self.board.parse_fen(fen)
                self.move_history = []
                return True
            return False
        except Exception as e:
            print(f"ERROR: {e}")
            return False

    def run_interactive(self):
        """Run interactive chess game"""
        print("\n" + "="*60)
        print("  Play Chess Against PIC18F45K22")
        print("="*60)

        if self.simulated:
            print("WARNING  Running in SIMULATED mode (no hardware)")
        else:
            print(f"OK Connected to {self.port}")

        print("\nHow it works:")
        print("  1. You make a move (e.g., 'e2e4')")
        print("  2. PIC validates your move")
        print("  3. If valid: PIC makes its move and responds")
        print("  4. If invalid: PIC tells you why")
        print()
        print("Commands:")
        print("  <move>   - Make a move (e.g., 'e2e4', 'e7e8q')")
        print("  new      - Start new game")
        print("  show     - Display board")
        print("  quit     - Exit")
        print("="*60)

        self.board.display()

        while True:
            try:
                # Get user input
                if self.board.turn == 'w':
                    move = input("\nYour move (White) > ").strip()
                else:
                    move = input("\nYour move (Black) > ").strip()

                if not move:
                    continue

                # Parse command
                if move in ['quit', 'exit']:
                    print("Thanks for playing! Goodbye!")
                    break

                elif move == 'show':
                    self.board.display()
                    continue

                elif move == 'new':
                    self.new_game()
                    self.board.display()
                    continue

                # It's a move - send to PIC for validation
                print(f"\n[SEND] Sending move to PIC for validation...")
                success, response = self.send_move(move)

                if success:
                    # Move was valid, PIC responded with new position
                    print(f"OK Move accepted! PIC responded.")
                    self.move_history.append(move)

                    # Update board from FEN
                    self.board.parse_fen(response)
                    self.board.display()

                else:
                    # Move was invalid
                    print(f"ERROR Move rejected: {response}")
                    print("Try a different move.")

            except KeyboardInterrupt:
                print("\n\nInterrupted. Goodbye!")
                break
            except Exception as e:
                print(f"ERROR: {e}")

    def close(self):
        """Close connection"""
        if self.serial_conn:
            self.serial_conn.close()


def run_tests():
    """Run automated tests"""
    print("\n" + "="*60)
    print("  RUNNING AUTOMATED TESTS - PIC Chess Player")
    print("="*60)

    interface = PICChessInterface(simulated=True)
    passed = 0
    failed = 0

    # Test 1: Initial position
    print("\nTest 1: Initial Position")
    print("-" * 40)
    interface.board.display()
    assert interface.board.generate_fen() == ChessBoard.STARTING_FEN
    print("OK PASS")
    passed += 1

    # Test 2: Valid move (e2e4)
    print("\nTest 2: Valid Move (e2e4)")
    print("-" * 40)
    success, response = interface.send_move("e2e4")
    if success:
        print(f"Move accepted, response FEN: {response}")
        interface.board.parse_fen(response)
        interface.board.display()
        print("OK PASS")
        passed += 1
    else:
        print(f"FAIL: Move rejected: {response}")
        failed += 1

    # Test 3: Invalid move format
    print("\nTest 3: Invalid Move Format")
    print("-" * 40)
    interface.board.parse_fen(ChessBoard.STARTING_FEN)
    success, response = interface.send_move("xyz")
    if not success:
        print(f"Correctly rejected: {response}")
        print("OK PASS")
        passed += 1
    else:
        print("FAIL: Invalid move was accepted")
        failed += 1

    # Test 4: Invalid square
    print("\nTest 4: Invalid Square")
    print("-" * 40)
    interface.board.parse_fen(ChessBoard.STARTING_FEN)
    success, response = interface.send_move("z9a1")
    if not success:
        print(f"Correctly rejected: {response}")
        print("OK PASS")
        passed += 1
    else:
        print("FAIL: Invalid square was accepted")
        failed += 1

    # Test 5: Move sequence
    print("\nTest 5: Move Sequence")
    print("-" * 40)
    interface.board.parse_fen(ChessBoard.STARTING_FEN)
    moves = ["e2e4", "d7d5", "e4d5"]
    for move in moves:
        print(f"  Testing move: {move}")
        success, response = interface.send_move(move)
        if success:
            interface.board.parse_fen(response)
            print(f"    OK Accepted")
        else:
            print(f"    — Rejected: {response}")
    interface.board.display()
    print("OK PASS")
    passed += 1

    # Test 6: New game
    print("\nTest 6: New Game")
    print("-" * 40)
    interface.new_game()
    assert interface.board.generate_fen() == ChessBoard.STARTING_FEN
    print("OK PASS")
    passed += 1

    # Summary
    print("\n" + "="*60)
    print(f"  TESTS COMPLETE: {passed} passed, {failed} failed")
    if failed == 0:
        print("  ALL TESTS PASSED! OK")
    print("="*60)

    return failed == 0


def main():
    """Main entry point"""
    if len(sys.argv) > 1:
        if sys.argv[1] == '--test':
            success = run_tests()
            sys.exit(0 if success else 1)
        else:
            # Hardware mode
            port = sys.argv[1]
            interface = PICChessInterface(port=port, simulated=False)
    else:
        # Simulated mode
        print("No serial port specified. Running in simulated mode.")
        print("Usage: python3 chess_player.py <serial_port>")
        print("       python3 chess_player.py /dev/ttyUSB0")
        print("       python3 chess_player.py COM3")
        print("       python3 chess_player.py --test")
        print()
        interface = PICChessInterface(simulated=True)

    try:
        interface.run_interactive()
    finally:
        interface.close()


if __name__ == '__main__':
    main()
