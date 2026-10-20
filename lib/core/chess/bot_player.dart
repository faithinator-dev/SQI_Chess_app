import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'bot_difficulty.dart';
import 'pure_chess_bot.dart';

class BotPlayer {
  BotPlayer({required this.difficulty})
    : _bot = PureChessBot(difficulty: difficulty);

  final BotDifficulty difficulty;
  final PureChessBot _bot;

  bool _thinking = false;

  bool get isReady => true;
  bool get isThinking => _thinking;

  Future<void> initialize() async {
    // Reserved for future engine initialization.
    // The current bot is pure Dart, so there is no native
    // engine or external process to start.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  Future<String?> findBestMove(String fen) async {
    if (_thinking) {
      return null;
    }

    _thinking = true;

    try {
      final setup = Setup.parseFen(fen);
      final position = Chess.fromSetup(setup);

      // Run the calculation asynchronously from the caller's
      // point of view. The actual search is still Dart code.
      final move = await Future<Move?>(() => _bot.findBestMove(position));

      return move?.uci;
    } catch (error, stackTrace) {
      debugPrint('Bot error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _thinking = false;
    }
  }

  void stop() {
    _thinking = false;
  }

  Future<void> dispose() async {
    _thinking = false;
  }
}
