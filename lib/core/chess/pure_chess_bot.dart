import 'dart:math';

import 'package:dartchess/dartchess.dart';

import 'bot_difficulty.dart';

class PureChessBot {
  PureChessBot({required this.difficulty});

  final BotDifficulty difficulty;

  final Random _random = Random();

  Move? findBestMove(Position position) {
    final legalMoves = _allLegalMoves(position);

    if (legalMoves.isEmpty) {
      return null;
    }

    switch (difficulty) {
      case BotDifficulty.beginner:
        return _beginnerMove(position, legalMoves);

      case BotDifficulty.intermediate:
        return _searchBestMove(position, legalMoves, depth: 2);

      case BotDifficulty.advanced:
        return _searchBestMove(position, legalMoves, depth: 3);

      case BotDifficulty.expert:
        return _searchBestMove(position, legalMoves, depth: 4);
      case BotDifficulty.creator:
        return _searchBestMove(position, legalMoves, depth: 5);
    }
  }

  // ------------------------------------------------------------
  // MOVE GENERATION
  // ------------------------------------------------------------

  List<Move> _allLegalMoves(Position position) {
    final moves = <Move>[];

    for (final entry in position.legalMoves.entries) {
      final from = entry.key;

      for (final to in entry.value.squares) {
        final movingPiece = position.board.pieceAt(from);

        if (movingPiece?.role == Role.pawn && _isPromotionSquare(to)) {
          const promotionRoles = <Role>[
            Role.queen,
            Role.rook,
            Role.bishop,
            Role.knight,
          ];

          for (final role in promotionRoles) {
            final move = NormalMove(from: from, to: to, promotion: role);

            if (position.isLegal(move)) {
              moves.add(move);
            }
          }
        } else {
          final move = NormalMove(from: from, to: to);

          if (position.isLegal(move)) {
            moves.add(move);
          }
        }
      }
    }

    return moves;
  }

  bool _isPromotionSquare(Square square) {
    final rank = square.truncate() ~/ 8;
    return rank == 0 || rank == 7;
  }

  // ------------------------------------------------------------
  // BEGINNER
  // ------------------------------------------------------------

  Move _beginnerMove(Position position, List<Move> legalMoves) {
    final scored = <_ScoredMove>[];

    for (final move in legalMoves) {
      final nextPosition = position.play(move);

      var score = 0.0;

      if (_capturesSomething(position, move)) {
        score += 100;
      }

      if (nextPosition.isCheck) {
        score += 80;
      }

      score += _moveCenterBonus(move);

      scored.add(_ScoredMove(move: move, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // Beginner deliberately has some imperfection.
    final poolSize = min(5, scored.length);

    return scored[_random.nextInt(poolSize)].move;
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Move _searchBestMove(
    Position position,
    List<Move> legalMoves, {
    required int depth,
  }) {
    final orderedMoves = _orderMoves(position, legalMoves);

    Move bestMove = orderedMoves.first;
    var bestScore = double.negativeInfinity;

    var alpha = double.negativeInfinity;
    const beta = double.infinity;

    for (final move in orderedMoves) {
      final nextPosition = position.play(move);

      final score = -_negamax(nextPosition, depth - 1, -beta, -alpha);

      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }

      alpha = max(alpha, score);
    }

    return bestMove;
  }

  double _negamax(Position position, int depth, double alpha, double beta) {
    if (position.isCheckmate) {
      return -1000000;
    }

    if (position.isGameOver) {
      return _evaluate(position);
    }

    if (depth <= 0) {
      return _quiescence(position, alpha, beta, 2);
    }

    final legalMoves = _allLegalMoves(position);

    if (legalMoves.isEmpty) {
      return _evaluate(position);
    }

    final orderedMoves = _orderMoves(position, legalMoves);

    var bestScore = double.negativeInfinity;

    for (final move in orderedMoves) {
      final nextPosition = position.play(move);

      final score = -_negamax(nextPosition, depth - 1, -beta, -alpha);

      bestScore = max(bestScore, score);

      alpha = max(alpha, score);

      if (alpha >= beta) {
        break;
      }
    }

    return bestScore;
  }

  // ------------------------------------------------------------
  // QUIESCENCE SEARCH
  // ------------------------------------------------------------

  double _quiescence(Position position, double alpha, double beta, int depth) {
    final standPat = _evaluate(position);

    if (depth <= 0) {
      return standPat;
    }

    if (standPat >= beta) {
      return beta;
    }

    if (standPat > alpha) {
      alpha = standPat;
    }

    final legalMoves = _allLegalMoves(position);

    final tacticalMoves = legalMoves.where((move) {
      if (_capturesSomething(position, move)) {
        return true;
      }

      if (_isPromotionMove(move)) {
        return true;
      }

      final nextPosition = position.play(move);
      return nextPosition.isCheck;
    }).toList();

    final orderedMoves = _orderMoves(position, tacticalMoves);

    for (final move in orderedMoves) {
      final nextPosition = position.play(move);

      final score = -_quiescence(nextPosition, -beta, -alpha, depth - 1);

      if (score >= beta) {
        return beta;
      }

      if (score > alpha) {
        alpha = score;
      }
    }

    return alpha;
  }

  // ------------------------------------------------------------
  // MOVE ORDERING
  // ------------------------------------------------------------

  List<Move> _orderMoves(Position position, List<Move> moves) {
    final scored = <_ScoredMove>[];

    for (final move in moves) {
      var score = 0.0;

      final captured = position.board.pieceAt(move.to);

      if (captured != null) {
        score += 1000;
        score += _pieceValue(captured.role);
      }

      if (_isPromotionMove(move)) {
        score += 900;
        score += _pieceValue(
          move is NormalMove && move.promotion != null
              ? move.promotion!
              : Role.queen,
        );
      }

      final nextPosition = position.play(move);

      if (nextPosition.isCheck) {
        score += 500;
      }

      score += _moveCenterBonus(move);

      scored.add(_ScoredMove(move: move, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.map((item) => item.move).toList();
  }

  double _moveCenterBonus(Move move) {
    const centerSquares = <Square>{Square.d4, Square.e4, Square.d5, Square.e5};

    if (centerSquares.contains(move.to)) {
      return 25;
    }

    return 0;
  }

  // ------------------------------------------------------------
  // POSITION EVALUATION
  // ------------------------------------------------------------

  double _evaluate(Position position) {
    if (position.isCheckmate) {
      return -1000000;
    }

    if (position.isStalemate) {
      return 0;
    }

    final whiteScore =
        _materialScore(position) +
        _pieceActivityScore(position) +
        _centerControlScore(position) +
        _developmentScore(position) +
        _kingSafetyScore(position) +
        _mobilityScore(position) +
        _pawnStructureScore(position) +
        _hangingPieceScore(position);

    final score = position.turn == Side.white ? whiteScore : -whiteScore;

    return score;
  }

  // ------------------------------------------------------------
  // MATERIAL
  // ------------------------------------------------------------

  double _materialScore(Position position) {
    var score = 0.0;

    for (final entry in position.board.pieces) {
      final piece = entry.$2;
      final value = _pieceValue(piece.role);

      if (piece.color == Side.white) {
        score += value;
      } else {
        score -= value;
      }
    }

    return score;
  }

  double _pieceValue(Role role) {
    switch (role) {
      case Role.pawn:
        return 100;

      case Role.knight:
        return 320;

      case Role.bishop:
        return 330;

      case Role.rook:
        return 500;

      case Role.queen:
        return 900;

      case Role.king:
        return 20000;
    }
  }

  // ------------------------------------------------------------
  // PIECE ACTIVITY
  // ------------------------------------------------------------

  double _pieceActivityScore(Position position) {
    var score = 0.0;

    for (final entry in position.board.pieces) {
      final square = entry.$1;
      final piece = entry.$2;

      final file = square.truncate() % 8;
      final rank = square.truncate() ~/ 8;

      final distanceFromCenter = (3.5 - file).abs() + (3.5 - rank).abs();

      final centrality = max(0.0, 4.0 - distanceFromCenter);

      var pieceScore = 0.0;

      switch (piece.role) {
        case Role.knight:
          pieceScore += centrality * 10;
          break;

        case Role.bishop:
          pieceScore += centrality * 7;
          break;

        case Role.rook:
          if (rank == 6 || rank == 1) {
            pieceScore += 18;
          }
          break;

        case Role.queen:
          pieceScore += centrality * 3;
          break;

        case Role.pawn:
          final advancement = piece.color == Side.white ? rank : 7 - rank;

          pieceScore += advancement * 3;
          break;

        case Role.king:
          break;
      }

      if (piece.color == Side.white) {
        score += pieceScore;
      } else {
        score -= pieceScore;
      }
    }

    return score;
  }

  // ------------------------------------------------------------
  // CENTER CONTROL
  // ------------------------------------------------------------

  double _centerControlScore(Position position) {
    const centerSquares = <Square>[Square.d4, Square.e4, Square.d5, Square.e5];

    var score = 0.0;

    for (final square in centerSquares) {
      final piece = position.board.pieceAt(square);

      if (piece != null) {
        final bonus = piece.role == Role.pawn ? 25.0 : 12.0;

        if (piece.color == Side.white) {
          score += bonus;
        } else {
          score -= bonus;
        }
      }

      final whiteAttacks = position.board
          .attacksTo(square, Side.white)
          .squares
          .length;

      final blackAttacks = position.board
          .attacksTo(square, Side.black)
          .squares
          .length;

      score += (whiteAttacks - blackAttacks) * 4;
    }

    return score;
  }

  // ------------------------------------------------------------
  // DEVELOPMENT
  // ------------------------------------------------------------

  double _developmentScore(Position position) {
    var score = 0.0;

    for (final entry in position.board.pieces) {
      final square = entry.$1;
      final piece = entry.$2;

      if (piece.role != Role.knight && piece.role != Role.bishop) {
        continue;
      }

      final isHomeSquare = piece.color == Side.white
          ? _whiteMinorHomeSquares.contains(square)
          : _blackMinorHomeSquares.contains(square);

      if (!isHomeSquare) {
        if (piece.color == Side.white) {
          score += 18;
        } else {
          score -= 18;
        }
      }
    }

    // Bishop pair bonus.
    final whiteBishops = position.board
        .piecesOf(Side.white, Role.bishop)
        .squares
        .length;

    final blackBishops = position.board
        .piecesOf(Side.black, Role.bishop)
        .squares
        .length;

    if (whiteBishops >= 2) {
      score += 20;
    }

    if (blackBishops >= 2) {
      score -= 20;
    }

    return score;
  }

  static const Set<Square> _whiteMinorHomeSquares = {
    Square.b1,
    Square.g1,
    Square.c1,
    Square.f1,
  };

  static const Set<Square> _blackMinorHomeSquares = {
    Square.b8,
    Square.g8,
    Square.c8,
    Square.f8,
  };

  // ------------------------------------------------------------
  // KING SAFETY
  // ------------------------------------------------------------

  double _kingSafetyScore(Position position) {
    var score = 0.0;

    final whiteKing = position.board.kingOf(Side.white);

    final blackKing = position.board.kingOf(Side.black);

    if (whiteKing == Square.g1 || whiteKing == Square.c1) {
      score += 45;
    }

    if (blackKing == Square.g8 || blackKing == Square.c8) {
      score -= 45;
    }

    if (whiteKing == Square.e1) {
      score -= 18;
    }

    if (blackKing == Square.e8) {
      score += 18;
    }

    if (position.isCheck) {
      if (position.turn == Side.white) {
        score -= 70;
      } else {
        score += 70;
      }
    }

    return score;
  }

  // ------------------------------------------------------------
  // MOBILITY
  // ------------------------------------------------------------

  double _mobilityScore(Position position) {
    final currentMoves = _allLegalMoves(position).length;

    return currentMoves * 1.5;
  }

  // ------------------------------------------------------------
  // PAWN STRUCTURE
  // ------------------------------------------------------------

  double _pawnStructureScore(Position position) {
    var score = 0.0;

    final whiteFiles = List<int>.filled(8, 0);

    final blackFiles = List<int>.filled(8, 0);

    for (final entry in position.board.pieces) {
      final square = entry.$1;
      final piece = entry.$2;

      if (piece.role != Role.pawn) {
        continue;
      }

      final file = square.truncate() % 8;

      if (piece.color == Side.white) {
        whiteFiles[file]++;
      } else {
        blackFiles[file]++;
      }
    }

    for (var file = 0; file < 8; file++) {
      if (whiteFiles[file] > 1) {
        score -= (whiteFiles[file] - 1) * 15;
      }

      if (blackFiles[file] > 1) {
        score += (blackFiles[file] - 1) * 15;
      }
    }

    // Isolated pawns.
    for (var file = 0; file < 8; file++) {
      final whiteCount = whiteFiles[file];

      if (whiteCount > 0) {
        final left = file > 0 ? whiteFiles[file - 1] : 0;

        final right = file < 7 ? whiteFiles[file + 1] : 0;

        if (left == 0 && right == 0) {
          score -= whiteCount * 8;
        }
      }

      final blackCount = blackFiles[file];

      if (blackCount > 0) {
        final left = file > 0 ? blackFiles[file - 1] : 0;

        final right = file < 7 ? blackFiles[file + 1] : 0;

        if (left == 0 && right == 0) {
          score += blackCount * 8;
        }
      }
    }

    return score;
  }

  // ------------------------------------------------------------
  // HANGING PIECES
  // ------------------------------------------------------------

  double _hangingPieceScore(Position position) {
    var score = 0.0;

    for (final entry in position.board.pieces) {
      final square = entry.$1;
      final piece = entry.$2;

      // Do not evaluate kings as ordinary hanging pieces.
      if (piece.role == Role.king) {
        continue;
      }

      final ownAttackers = position.board
          .attacksTo(square, piece.color)
          .squares
          .length;

      final enemySide = piece.color == Side.white ? Side.black : Side.white;

      final enemyAttackers = position.board
          .attacksTo(square, enemySide)
          .squares
          .length;

      if (enemyAttackers > 0 && ownAttackers == 0) {
        final penalty = _pieceValue(piece.role) * 0.10;

        if (piece.color == Side.white) {
          score -= penalty;
        } else {
          score += penalty;
        }
      }
    }

    return score;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  bool _capturesSomething(Position position, Move move) {
    return position.board.pieceAt(move.to) != null;
  }

  bool _isPromotionMove(Move move) {
    if (move is! NormalMove) {
      return false;
    }

    return move.promotion != null;
  }
}

class _ScoredMove {
  const _ScoredMove({required this.move, required this.score});

  final Move move;
  final double score;
}
