import 'package:dartchess/dartchess.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chess_game_model.dart';
import '../models/profile_model.dart';

class GameHistoryEntry {
  const GameHistoryEntry({
    required this.game,
    required this.isWhite,
    this.opponent,
  });

  final ChessGameModel game;
  final bool isWhite;
  final ProfileModel? opponent;

  String get result {
    if (game.result == 'draw') return 'Draw';
    if (game.result == null) return 'Unknown';

    final won =
        (isWhite && game.result == 'white') ||
        (!isWhite && game.result == 'black');
    return won ? 'Victory' : 'Defeat';
  }
}

class ActiveGameEntry {
  const ActiveGameEntry({
    required this.game,
    required this.isWhite,
    this.opponent,
  });

  final ChessGameModel game;
  final bool isWhite;
  final ProfileModel? opponent;
}

class ChessGameMove {
  const ChessGameMove({
    required this.id,
    required this.gameId,
    required this.moveNumber,
    required this.ply,
    required this.color,
    required this.san,
    required this.uci,
    required this.fenAfter,
    required this.remainingTimeMs,
    this.createdAt,
  });

  final String id;
  final String gameId;
  final int moveNumber;
  final int ply;
  final String color;
  final String san;
  final String uci;
  final String fenAfter;
  final int? remainingTimeMs;
  final DateTime? createdAt;

  factory ChessGameMove.fromMap(Map<String, dynamic> map) {
    return ChessGameMove(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      moveNumber: (map['move_number'] as num).toInt(),
      ply: (map['ply'] as num).toInt(),
      color: map['color'] as String,
      san: map['san'] as String,
      uci: map['uci'] as String? ?? '',
      fenAfter: map['fen_after'] as String,
      remainingTimeMs: (map['remaining_time_ms'] as num?)?.toInt(),
      createdAt: _date(map['created_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class GameDrawOffer {
  const GameDrawOffer({
    required this.id,
    required this.gameId,
    required this.offeredBy,
    required this.offeredTo,
    required this.stateVersion,
    required this.status,
  });

  final String id;
  final String gameId;
  final String offeredBy;
  final String offeredTo;
  final int stateVersion;
  final String status;

  factory GameDrawOffer.fromMap(Map<String, dynamic> map) {
    return GameDrawOffer(
      id: map['id'] as String,
      gameId: map['game_id'] as String,
      offeredBy: map['offered_by'] as String,
      offeredTo: map['offered_to'] as String,
      stateVersion: (map['state_version'] as num).toInt(),
      status: map['status'] as String,
    );
  }
}

class ChessGameRepository {
  ChessGameRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    return user.id;
  }

  Future<ChessGameModel> getGame(String gameId) async {
    final result = await _client
        .from('games')
        .select()
        .eq('id', gameId)
        .single();

    return ChessGameModel.fromMap(Map<String, dynamic>.from(result));
  }

  Future<List<GameHistoryEntry>> getCurrentHistory() async {
    final currentUserId = userId;
    final rows = await _client
        .from('games')
        .select()
        .or(
          'white_player_id.eq.$currentUserId,black_player_id.eq.$currentUserId',
        )
        .inFilter('status', ['completed', 'abandoned', 'cancelled'])
        .order('ended_at', ascending: false);

    final games = rows
        .map((row) => ChessGameModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final opponentIds = games
        .map(
          (game) => game.whitePlayerId == currentUserId
              ? game.blackPlayerId
              : game.whitePlayerId,
        )
        .whereType<String>()
        .toSet()
        .toList();

    final profilesById = <String, ProfileModel>{};
    if (opponentIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select()
          .inFilter('id', opponentIds);
      for (final row in profiles) {
        final profile = ProfileModel.fromMap(Map<String, dynamic>.from(row));
        profilesById[profile.id] = profile;
      }
    }

    return games.map((game) {
      final isWhite = game.whitePlayerId == currentUserId;
      final opponentId = isWhite ? game.blackPlayerId : game.whitePlayerId;
      return GameHistoryEntry(
        game: game,
        isWhite: isWhite,
        opponent: opponentId == null ? null : profilesById[opponentId],
      );
    }).toList();
  }

  Future<List<ActiveGameEntry>> getCurrentActiveGames() async {
    final currentUserId = userId;
    final rows = await _client
        .from('games')
        .select()
        .or(
          'white_player_id.eq.$currentUserId,black_player_id.eq.$currentUserId',
        )
        .eq('status', 'active')
        .order('updated_at', ascending: false);

    final games = rows
        .map((row) => ChessGameModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
    final opponentIds = games
        .map(
          (game) => game.whitePlayerId == currentUserId
              ? game.blackPlayerId
              : game.whitePlayerId,
        )
        .whereType<String>()
        .toSet()
        .toList();
    final profilesById = <String, ProfileModel>{};
    if (opponentIds.isNotEmpty) {
      final profiles = await _client
          .from('profiles')
          .select()
          .inFilter('id', opponentIds);
      for (final row in profiles) {
        final profile = ProfileModel.fromMap(Map<String, dynamic>.from(row));
        profilesById[profile.id] = profile;
      }
    }

    return games.map((game) {
      final isWhite = game.whitePlayerId == currentUserId;
      final opponentId = isWhite ? game.blackPlayerId : game.whitePlayerId;
      return ActiveGameEntry(
        game: game,
        isWhite: isWhite,
        opponent: opponentId == null ? null : profilesById[opponentId],
      );
    }).toList();
  }

  Future<List<ChessGameMove>> getMoves(String gameId) async {
    final result = await _client
        .from('game_moves')
        .select()
        .eq('game_id', gameId)
        .order('ply', ascending: true);

    return result
        .map((row) => ChessGameMove.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Map<String, dynamic>> submitMove({
    required String gameId,
    required Move move,
  }) async {
    final response = await _client.functions.invoke(
      'submit-move',
      body: {'game_id': gameId, 'uci': move.uci},
    );

    final data = response.data;

    if (data is! Map) {
      throw StateError('The move service returned an invalid response.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<ChessGameModel> resignGame(String gameId) async {
    final result = await _client.rpc(
      'resign_game',
      params: {'p_game_id': gameId},
    );

    return ChessGameModel.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<GameDrawOffer> offerDraw(String gameId) async {
    final result = await _client.rpc(
      'offer_draw',
      params: {'p_game_id': gameId},
    );

    return GameDrawOffer.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<ChessGameModel> respondToDrawOffer({
    required String offerId,
    required bool accept,
  }) async {
    final result = await _client.rpc(
      'respond_draw_offer',
      params: {'p_offer_id': offerId, 'p_accept': accept},
    );

    return ChessGameModel.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<ChessGameModel> expireGameOnTimeout(String gameId) async {
    final result = await _client.rpc(
      'expire_game_on_timeout',
      params: {'p_game_id': gameId},
    );

    return ChessGameModel.fromMap(Map<String, dynamic>.from(result as Map));
  }

  Future<GameDrawOffer?> getPendingDrawOffer(String gameId) async {
    final result = await _client
        .from('game_draw_offers')
        .select()
        .eq('game_id', gameId)
        .eq('status', 'pending')
        .maybeSingle();

    if (result == null) {
      return null;
    }

    return GameDrawOffer.fromMap(Map<String, dynamic>.from(result));
  }

  RealtimeChannel watchGame({
    required String gameId,
    required void Function(ChessGameModel game) onChanged,
  }) {
    final channel = _client
        .channel('game:$gameId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'games',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: gameId,
          ),
          callback: (payload) {
            final record = payload.newRecord;

            if (record.isEmpty) return;

            onChanged(
              ChessGameModel.fromMap(Map<String, dynamic>.from(record)),
            );
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_moves',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'game_id',
            value: gameId,
          ),
          callback: (_) {
            // The game UPDATE contains the authoritative FEN,
            // turn and clocks. We reload the game after a move.
            _reloadAndNotify(gameId, onChanged);
          },
        );

    channel.subscribe();

    return channel;
  }

  Future<void> _reloadAndNotify(
    String gameId,
    void Function(ChessGameModel game) onChanged,
  ) async {
    try {
      final game = await getGame(gameId);
      onChanged(game);
    } catch (_) {
      // Realtime can race with the database update.
      // The next event or screen refresh will recover.
    }
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
