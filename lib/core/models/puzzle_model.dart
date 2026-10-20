import 'package:dartchess/dartchess.dart';

class PuzzleModel {
  const PuzzleModel({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.fen,
    required this.solutionUci,
    this.instruction = '',
  });

  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String fen;
  final List<String> solutionUci;
  final String instruction;

  Position get position => Chess.fromSetup(Setup.parseFen(fen));

  factory PuzzleModel.fromMap(Map<String, dynamic> map) {
    final rawSolution = map['solution_uci'];
    return PuzzleModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'Tactics',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      fen: map['fen'] as String,
      solutionUci: rawSolution is List
          ? rawSolution.map((move) => move.toString()).toList()
          : const <String>[],
      instruction: map['instruction'] as String? ?? '',
    );
  }
}

enum PuzzleMoveResult { correct, incorrect, illegal, complete }

class PuzzleAttempt {
  const PuzzleAttempt({
    required this.result,
    required this.position,
    required this.nextMoveIndex,
  });

  final PuzzleMoveResult result;
  final Position position;
  final int nextMoveIndex;
}
