import 'package:flutter/material.dart';

class SpectatorChessBoard extends StatelessWidget {
  final String fen;
  final bool showCoordinates;
  final bool flipped;

  const SpectatorChessBoard({
    super.key,
    required this.fen,
    this.showCoordinates = true,
    this.flipped = false,
  });

  static const Color lightSquare = Color(0xFFE8EDF5);
  static const Color darkSquare = Color(0xFF52627A);

  static const Map<String, String> pieces = {
    'K': '♔',
    'Q': '♕',
    'R': '♖',
    'B': '♗',
    'N': '♘',
    'P': '♙',
    'k': '♚',
    'q': '♛',
    'r': '♜',
    'b': '♝',
    'n': '♞',
    'p': '♟',
  };

  List<String> _parseFen(String fen) {
    final boardPart = fen.split(' ').first;
    final rows = boardPart.split('/');

    final board = <String>[];

    for (final row in rows) {
      for (final char in row.split('')) {
        final empty = int.tryParse(char);

        if (empty != null) {
          board.addAll(List.filled(empty, ''));
        } else {
          board.add(char);
        }
      }
    }

    while (board.length < 64) {
      board.add('');
    }

    return board.take(64).toList();
  }

  String _fileName(int index) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return files[index];
  }

  String _rankName(int index) {
    return '${8 - index}';
  }

  @override
  Widget build(BuildContext context) {
    final board = _parseFen(fen);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final squareSize = size / 8;

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final actualIndex = flipped ? 63 - index : index;

                    final row = actualIndex ~/ 8;
                    final column = actualIndex % 8;

                    final isDark = (row + column).isOdd;
                    final piece = board[actualIndex];

                    return Container(
                      color: isDark ? darkSquare : lightSquare,
                      alignment: Alignment.center,
                      child: piece.isEmpty
                          ? null
                          : FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                pieces[piece] ?? '',
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1,
                                  color: piece == piece.toUpperCase()
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    );
                  },
                ),

                if (showCoordinates)
                  IgnorePointer(
                    child: Stack(
                      children: [
                        for (int i = 0; i < 8; i++)
                          Positioned(
                            left: flipped ? null : i * squareSize + 4,
                            right: flipped ? i * squareSize + 4 : null,
                            bottom: 3,
                            child: Text(
                              _fileName(i),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: i.isEven ? darkSquare : lightSquare,
                              ),
                            ),
                          ),

                        for (int i = 0; i < 8; i++)
                          Positioned(
                            left: 3,
                            top: flipped ? null : i * squareSize + 3,
                            bottom: flipped ? i * squareSize + 3 : null,
                            child: Text(
                              _rankName(i),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: i.isEven ? lightSquare : darkSquare,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
