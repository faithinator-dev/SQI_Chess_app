import 'match_mode.dart';

class MatchConfig {
  const MatchConfig({
    required this.mode,
    required this.initialTimeSeconds,
    this.incrementSeconds = 0,
    this.gameId,
    this.whitePlayerName = 'White',
    this.blackPlayerName = 'Black',
    this.isGuest = false,
  });

  final MatchMode mode;
  final int initialTimeSeconds;
  final int incrementSeconds;

  final String? gameId;

  final String whitePlayerName;
  final String blackPlayerName;

  final bool isGuest;

  bool get isOnline => mode == MatchMode.quickMatch || mode == MatchMode.friend;

  bool get isLocal => mode == MatchMode.local;

  bool get isLan => mode == MatchMode.lan;

  bool get isBot => mode == MatchMode.bot;
}
