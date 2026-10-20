import 'package:dartchess/dartchess.dart';

import '../models/puzzle_model.dart';

class PuzzleService {
  PuzzleService(this.puzzle) : _position = puzzle.position;

  final PuzzleModel puzzle;
  Position _position;
  int _nextMoveIndex = 0;

  Position get position => _position;
  int get nextMoveIndex => _nextMoveIndex;
  bool get isComplete => _nextMoveIndex >= puzzle.solutionUci.length;

  PuzzleAttempt tryPlay(String uci) {
    final move = Move.parse(uci);
    if (move == null) {
      return PuzzleAttempt(
        result: PuzzleMoveResult.illegal,
        position: _position,
        nextMoveIndex: _nextMoveIndex,
      );
    }

    return play(move);
  }

  PuzzleAttempt play(Move move) {
    if (isComplete) {
      return PuzzleAttempt(
        result: PuzzleMoveResult.complete,
        position: _position,
        nextMoveIndex: _nextMoveIndex,
      );
    }

    if (!_position.isLegal(move)) {
      return PuzzleAttempt(
        result: PuzzleMoveResult.illegal,
        position: _position,
        nextMoveIndex: _nextMoveIndex,
      );
    }

    if (move.uci != puzzle.solutionUci[_nextMoveIndex]) {
      return PuzzleAttempt(
        result: PuzzleMoveResult.incorrect,
        position: _position,
        nextMoveIndex: _nextMoveIndex,
      );
    }

    _position = _position.play(move);
    _nextMoveIndex++;

    return PuzzleAttempt(
      result: isComplete ? PuzzleMoveResult.complete : PuzzleMoveResult.correct,
      position: _position,
      nextMoveIndex: _nextMoveIndex,
    );
  }

  void retry() {
    _position = puzzle.position;
    _nextMoveIndex = 0;
  }
}
