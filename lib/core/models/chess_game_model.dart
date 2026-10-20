class ChessGameModel {
  const ChessGameModel({
    required this.id,
    required this.gameType,
    required this.status,
    required this.timeControl,
    required this.initialTimeSeconds,
    required this.incrementSeconds,
    required this.whitePlayerId,
    required this.blackPlayerId,
    required this.currentFen,
    required this.currentTurn,
    required this.whiteTimeMs,
    required this.blackTimeMs,
    required this.stateVersion,
    this.result,
    this.terminationReason,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String gameType;
  final String status;
  final String timeControl;

  final int initialTimeSeconds;
  final int incrementSeconds;

  final String? whitePlayerId;
  final String? blackPlayerId;

  final String currentFen;
  final String currentTurn;

  final int whiteTimeMs;
  final int blackTimeMs;
  final int stateVersion;

  final String? result;
  final String? terminationReason;

  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChessGameModel.fromMap(Map<String, dynamic> map) {
    return ChessGameModel(
      id: map['id'] as String,
      gameType: map['game_type'] as String? ?? 'online_random',
      status: map['status'] as String? ?? 'pending',
      timeControl: map['time_control'] as String? ?? '10+5',
      initialTimeSeconds: (map['initial_time_seconds'] as num?)?.toInt() ?? 600,
      incrementSeconds: (map['increment_seconds'] as num?)?.toInt() ?? 5,
      whitePlayerId: map['white_player_id'] as String?,
      blackPlayerId: map['black_player_id'] as String?,
      currentFen:
          map['current_fen'] as String? ??
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: map['current_turn'] as String? ?? 'white',
      whiteTimeMs: (map['white_time_ms'] as num?)?.toInt() ?? 600000,
      blackTimeMs: (map['black_time_ms'] as num?)?.toInt() ?? 600000,
      stateVersion: (map['state_version'] as num?)?.toInt() ?? 0,
      result: map['result'] as String?,
      terminationReason: map['termination_reason'] as String?,
      startedAt: _parseDate(map['started_at']),
      endedAt: _parseDate(map['ended_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool get isFinished =>
      status == 'completed' || status == 'abandoned' || status == 'cancelled';

  bool get isActive => status == 'active';

  String get winnerName {
    switch (result) {
      case 'white':
        return 'White';
      case 'black':
        return 'Black';
      case 'draw':
        return 'Draw';
      case 'abandoned':
        return 'Abandoned';
      default:
        return '';
    }
  }
}
