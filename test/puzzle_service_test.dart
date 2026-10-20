import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqi_chess_club/core/models/puzzle_model.dart';
import 'package:sqi_chess_club/core/services/puzzle_service.dart';

void main() {
  const puzzle = PuzzleModel(
    id: 'puzzle-1',
    title: 'Opening move',
    category: 'Basics',
    difficulty: 'Beginner',
    fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
    solutionUci: ['e7e5', 'g1f3'],
  );

  test('rejects an illegal move without changing the puzzle', () {
    final service = PuzzleService(puzzle);

    final result = service.play(Move.parse('a2a5')!);

    expect(result.result, PuzzleMoveResult.illegal);
    expect(service.nextMoveIndex, 0);
  });

  test('rejects a legal but incorrect solution move', () {
    final service = PuzzleService(puzzle);

    final result = service.play(Move.parse('d7d5')!);

    expect(result.result, PuzzleMoveResult.incorrect);
    expect(service.nextMoveIndex, 0);
  });

  test('completes after the expected solution sequence', () {
    final service = PuzzleService(puzzle);

    expect(service.play(Move.parse('e7e5')!).result, PuzzleMoveResult.correct);
    expect(service.play(Move.parse('g1f3')!).result, PuzzleMoveResult.complete);
    expect(service.isComplete, isTrue);
  });

  test('retry restores the initial position and solution index', () {
    final service = PuzzleService(puzzle);
    service.play(Move.parse('e7e5')!);

    service.retry();

    expect(service.position.fen, puzzle.position.fen);
    expect(service.nextMoveIndex, 0);
  });

  test('rejects malformed UCI without changing the puzzle', () {
    final service = PuzzleService(puzzle);

    final result = service.tryPlay('not-a-move');

    expect(result.result, PuzzleMoveResult.illegal);
    expect(service.position.fen, puzzle.position.fen);
    expect(service.nextMoveIndex, 0);
  });
}
