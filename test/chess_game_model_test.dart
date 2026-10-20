import 'package:flutter_test/flutter_test.dart';
import 'package:sqi_chess_club/core/models/chess_game_model.dart';

void main() {
  test('preserves the authoritative game state version', () {
    final game = ChessGameModel.fromMap({
      'id': 'game-id',
      'game_type': 'online_random',
      'status': 'active',
      'current_fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'current_turn': 'white',
      'state_version': 7,
    });

    expect(game.stateVersion, 7);
    expect(game.isActive, isTrue);
  });

  test('defaults a missing state version for legacy rows', () {
    final game = ChessGameModel.fromMap({
      'id': 'legacy-game-id',
      'game_type': 'online_random',
      'status': 'completed',
      'current_fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      'current_turn': 'white',
    });

    expect(game.stateVersion, 0);
    expect(game.isFinished, isTrue);
  });
}
