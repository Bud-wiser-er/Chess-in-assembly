#!/usr/bin/env python3
"""
PIC18F45K22 Chess Engine - Simple Python Interface
===================================================

Standalone chess interface with NO external dependencies.
Implements basic chess board and FEN parsing/generation.

Usage:
    python3 chess_gui_simple.py --test    # Run tests
    python3 chess_gui_simple.py           # Interactive simulated mode
"""

import sys
import time


class ChessBoard:
    """Simple chess board implementation"""

    # Piece encoding (matches PIC assembly)
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

    # Piece characters for display
    PIECE_CHARS = {
        EMPTY: ' ',
        W_PAWN: 'P', W_KNIGHT: 'N', W_BISHOP: 'B',
        W_ROOK: 'R', W_QUEEN: 'Q', W_KING: 'K',
        B_PAWN: 'p', B_KNIGHT: 'n', B_BISHOP: 'b',
        B_ROOK: 'r', B_QUEEN: 'q', B_KING: 'k',
    }

    # FEN character to piece mapping
    FEN_TO_PIECE = {
        'P': W_PAWN, 'N': W_KNIGHT, 'B': W_BISHOP,
        'R': W_ROOK, 'Q': W_QUEEN, 'K': W_KING,
        'p': B_PAWN, 'n': B_KNIGHT, 'b': B_BISHOP,
        'r': B_ROOK, 'q': B_QUEEN, 'k': B_KING,
    }

    # Starting position FEN
    STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    def __init__(self):
        """Initialize empty board"""
        self.board = [self.EMPTY] * 64
        self.turn = 'w'  # 'w' or 'b'
        self.castling = 'KQkq'
        self.enpassant = '-'
        self.halfmove = 0
        self.fullmove = 1

    def square_to_index(self, square_name):
        """Convert algebraic notation to index (e.g., 'e4' -> 28)"""
        file = ord(square_name[0]) - ord('a')  # 0-7
        rank = int(square_name[1]) - 1  # 0-7
        return rank * 8 + file

    def index_to_square(self, index):
        """Convert index to algebraic notation (e.g., 28 -> 'e4')"""
        rank = index // 8
        file = index % 8
        return chr(ord('a') + file) + str(rank + 1)

    def get_piece(self, index):
        """Get piece at index"""
        return self.board[index]

    def set_piece(self, index, piece):
        """Set piece at index"""
        self.board[index] = piece

    def clear(self):
        """Clear board"""
        self.board = [self.EMPTY] * 64

    def setup_starting_position(self):
        """Setup standard chess starting position"""
        self.parse_fen(self.STARTING_FEN)

    def parse_fen(self, fen):
        """
        Parse FEN string and update board

        Args:
            fen: FEN string

        Returns:
            True if successful, False otherwise
        """
        try:
            parts = fen.split()
            if len(parts) < 4:
                return False

            # Clear board
            self.clear()

            # Parse piece placement
            ranks = parts[0].split('/')
            if len(ranks) != 8:
                return False

            for rank_idx, rank_str in enumerate(ranks):
                file_idx = 0
                board_rank = 7 - rank_idx  # FEN starts from rank 8

                for char in rank_str:
                    if char.isdigit():
                        # Empty squares
                        file_idx += int(char)
                    elif char in self.FEN_TO_PIECE:
                        # Piece
                        index = board_rank * 8 + file_idx
                        self.board[index] = self.FEN_TO_PIECE[char]
                        file_idx += 1

            # Parse active color
            self.turn = parts[1] if parts[1] in ['w', 'b'] else 'w'

            # Parse castling rights
            self.castling = parts[2] if len(parts) > 2 else '-'

            # Parse en passant
            self.enpassant = parts[3] if len(parts) > 3 else '-'

            # Parse halfmove clock
            self.halfmove = int(parts[4]) if len(parts) > 4 else 0

            # Parse fullmove number
            self.fullmove = int(parts[5]) if len(parts) > 5 else 1

            return True

        except Exception as e:
            print(f"FEN parse error: {e}")
            return False

    def generate_fen(self):
        """
        Generate FEN string from current board

        Returns:
            FEN string
        """
        fen_parts = []

        # Piece placement
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

        # Add other fields
        fen += f" {self.turn}"
        fen += f" {self.castling}"
        fen += f" {self.enpassant}"
        fen += f" {self.halfmove}"
        fen += f" {self.fullmove}"

        return fen

    def display(self):
        """Display board in terminal"""
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

    def make_simple_move(self, from_sq, to_sq):
        """
        Make a simple move (no validation)

        Args:
            from_sq: Source square (e.g., 'e2')
            to_sq: Destination square (e.g., 'e4')
        """
        from_idx = self.square_to_index(from_sq)
        to_idx = self.square_to_index(to_sq)

        piece = self.board[from_idx]
        self.board[from_idx] = self.EMPTY
        self.board[to_idx] = piece

        # Toggle turn
        self.turn = 'b' if self.turn == 'w' else 'w'


class SimpleChessGUI:
    """Simple chess GUI for PIC communication"""

    def __init__(self, simulated=True):
        """Initialize GUI"""
        self.board = ChessBoard()
        self.board.setup_starting_position()
        self.simulated = simulated

    def send_fen(self, fen=None):
        """Send FEN (simulated)"""
        if fen is None:
            fen = self.board.generate_fen()

        print(f"--> Sending FEN: {fen}")
        return True

    def receive_fen(self):
        """Receive FEN (simulated - makes random move)"""
        print("<-- AI thinking...")
        time.sleep(0.3)

        # Simulate AI making a move
        # For demo, just move a piece
        if self.board.turn == 'b':
            # Simple e7-e5 move
            self.board.make_simple_move('e7', 'e5')

        fen = self.board.generate_fen()
        print(f"<-- Received FEN: {fen}")
        return fen

    def run_interactive(self):
        """Run interactive mode"""
        print("\n" + "="*50)
        print("  PIC18F45K22 Chess Engine - Simple Interface")
        print("="*50)
        print("\nCommands:")
        print("  <from><to>  - Make a move (e.g., 'e2e4')")
        print("  fen <fen>   - Set position from FEN")
        print("  show        - Display board")
        print("  new         - New game")
        print("  quit        - Exit")
        print("="*50)

        self.board.display()

        while True:
            try:
                cmd = input("\nYour move > ").strip()

                if not cmd:
                    continue

                parts = cmd.split()

                if parts[0] in ['quit', 'exit']:
                    print("Goodbye!")
                    break

                elif parts[0] == 'show':
                    self.board.display()

                elif parts[0] == 'new':
                    self.board.setup_starting_position()
                    print("OK New game started")
                    self.board.display()

                elif parts[0] == 'fen':
                    if len(parts) > 1:
                        fen = ' '.join(parts[1:])
                        if self.board.parse_fen(fen):
                            print("OK Position set from FEN")
                            self.board.display()
                        else:
                            print("ERROR: Invalid FEN")
                    else:
                        print(f"Current FEN: {self.board.generate_fen()}")

                elif len(cmd) >= 4:
                    # Treat as move (e.g., 'e2e4')
                    from_sq = cmd[0:2]
                    to_sq = cmd[2:4]

                    try:
                        self.board.make_simple_move(from_sq, to_sq)
                        print(f"OK Move made: {from_sq}{to_sq}")
                        self.board.display()

                        # Send to PIC and get response
                        self.send_fen()
                        fen = self.receive_fen()
                        self.board.parse_fen(fen)
                        self.board.display()

                    except Exception as e:
                        print(f"ERROR: Invalid move: {e}")

                else:
                    print("Unknown command")

            except KeyboardInterrupt:
                print("\n\nInterrupted. Goodbye!")
                break
            except Exception as e:
                print(f"ERROR: {e}")


def run_tests():
    """Run automated tests"""
    print("\n" + "="*60)
    print("  RUNNING AUTOMATED TESTS")
    print("="*60)

    board = ChessBoard()
    passed = 0
    failed = 0

    # Test 1: Board initialization
    print("\nTest 1: Board Initialization")
    print("-" * 40)
    board.setup_starting_position()
    board.display()
    assert board.get_piece(board.square_to_index('e2')) == board.W_PAWN
    assert board.get_piece(board.square_to_index('e7')) == board.B_PAWN
    assert board.turn == 'w'
    print("OK PASS")
    passed += 1

    # Test 2: FEN parsing
    print("\nTest 2: FEN Parsing")
    print("-" * 40)
    test_fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    assert board.parse_fen(test_fen)
    board.display()
    assert board.get_piece(board.square_to_index('e4')) == board.W_PAWN
    assert board.turn == 'b'
    print("OK PASS")
    passed += 1

    # Test 3: FEN generation
    print("\nTest 3: FEN Generation")
    print("-" * 40)
    board.setup_starting_position()
    generated_fen = board.generate_fen()
    print(f"Generated: {generated_fen}")
    print(f"Expected:  {board.STARTING_FEN}")
    assert generated_fen == board.STARTING_FEN
    print("OK PASS")
    passed += 1

    # Test 4: Simple move
    print("\nTest 4: Simple Move")
    print("-" * 40)
    board.setup_starting_position()
    board.make_simple_move('e2', 'e4')
    board.display()
    assert board.get_piece(board.square_to_index('e4')) == board.W_PAWN
    assert board.get_piece(board.square_to_index('e2')) == board.EMPTY
    assert board.turn == 'b'
    print("OK PASS")
    passed += 1

    # Test 5: FEN roundtrip
    print("\nTest 5: FEN Roundtrip")
    print("-" * 40)
    test_positions = [
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
        "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
    ]
    for fen in test_positions:
        board.parse_fen(fen)
        generated = board.generate_fen()
        print(f"  Input:  {fen}")
        print(f"  Output: {generated}")
        assert generated == fen, f"Mismatch: {generated} != {fen}"
        print("  OK OK")
    print("OK PASS")
    passed += 1

    # Test 6: Square conversion
    print("\nTest 6: Square Conversion")
    print("-" * 40)
    test_squares = [('a1', 0), ('h1', 7), ('a8', 56), ('h8', 63), ('e4', 28)]
    for sq_name, sq_idx in test_squares:
        idx = board.square_to_index(sq_name)
        name = board.index_to_square(sq_idx)
        print(f"  {sq_name} -> {idx} (expected {sq_idx})")
        print(f"  {sq_idx} -> {name} (expected {sq_name})")
        assert idx == sq_idx
        assert name == sq_name
    print("OK PASS")
    passed += 1

    # Test 7: Piece encoding
    print("\nTest 7: Piece Encoding")
    print("-" * 40)
    board.setup_starting_position()
    # Check all starting pieces
    assert board.get_piece(0) == board.W_ROOK   # a1
    assert board.get_piece(4) == board.W_KING   # e1
    assert board.get_piece(56) == board.B_ROOK  # a8
    assert board.get_piece(60) == board.B_KING  # e8
    assert board.get_piece(12) == board.W_PAWN  # e2
    assert board.get_piece(52) == board.B_PAWN  # e7
    print("OK PASS")
    passed += 1

    # Test 8: Empty board
    print("\nTest 8: Empty Board")
    print("-" * 40)
    board.clear()
    for i in range(64):
        assert board.get_piece(i) == board.EMPTY
    fen = board.generate_fen()
    print(f"Empty board FEN: {fen}")
    assert '8/8/8/8/8/8/8/8' in fen
    print("OK PASS")
    passed += 1

    # Test 9: Complex position
    print("\nTest 9: Complex Position")
    print("-" * 40)
    complex_fen = "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 4 5"
    board.parse_fen(complex_fen)
    board.display()
    generated = board.generate_fen()
    assert generated == complex_fen
    print("OK PASS")
    passed += 1

    # Test 10: Move sequence
    print("\nTest 10: Move Sequence")
    print("-" * 40)
    board.setup_starting_position()
    moves = [('e2', 'e4'), ('e7', 'e5'), ('g1', 'f3'), ('b8', 'c6')]
    for from_sq, to_sq in moves:
        board.make_simple_move(from_sq, to_sq)
        print(f"  Move: {from_sq}{to_sq}")
    board.display()
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
    if len(sys.argv) > 1 and sys.argv[1] == '--test':
        success = run_tests()
        sys.exit(0 if success else 1)
    else:
        gui = SimpleChessGUI(simulated=True)
        gui.run_interactive()


if __name__ == '__main__':
    main()
