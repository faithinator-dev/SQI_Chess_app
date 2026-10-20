import 'package:supabase_flutter/supabase_flutter.dart';

class MatchmakingQueueEntry {
  const MatchmakingQueueEntry({
    required this.id,
    required this.userId,
    required this.timeControl,
    required this.initialTimeSeconds,
    required this.incrementSeconds,
    required this.rating,
    required this.status,
    this.matchedGameId,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String timeControl;
  final int initialTimeSeconds;
  final int incrementSeconds;
  final int rating;
  final String status;
  final String? matchedGameId;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  factory MatchmakingQueueEntry.fromMap(Map<String, dynamic> map) {
    return MatchmakingQueueEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      timeControl: map['time_control'] as String,
      initialTimeSeconds: (map['initial_time_seconds'] as num).toInt(),
      incrementSeconds: (map['increment_seconds'] as num).toInt(),
      rating: (map['rating'] as num).toInt(),
      status: map['status'] as String,
      matchedGameId: map['matched_game_id'] as String?,
      createdAt: _date(map['created_at']),
      expiresAt: _date(map['expires_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class MatchmakingRepository {
  MatchmakingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    return user.id;
  }

  /// Quick Match is always 10 minutes with no increment.
  Future<MatchmakingQueueEntry> joinQuickMatch() {
    return joinQueue(
      timeControl: '10+0',
      initialTimeSeconds: 600,
      incrementSeconds: 0,
    );
  }

  Future<MatchmakingQueueEntry> joinQueue({
    required String timeControl,
    required int initialTimeSeconds,
    required int incrementSeconds,
  }) async {
    final profile = await _client
        .from('profiles')
        .select('chess_rating')
        .eq('id', _userId)
        .maybeSingle();

    final rating = (profile?['chess_rating'] as num?)?.toInt() ?? 1000;

    final result = await _client.rpc(
      'join_matchmaking',
      params: {
        'p_time_control': timeControl,
        'p_initial_time_seconds': initialTimeSeconds,
        'p_increment_seconds': incrementSeconds,
        'p_rating': rating,
      },
    );

    return MatchmakingQueueEntry.fromMap(
      Map<String, dynamic>.from(result as Map),
    );
  }

  Future<void> leaveQueue() async {
    await _client.rpc('leave_matchmaking');
  }

  Future<MatchmakingQueueEntry?> getCurrentQueueEntry() async {
    final rows = await _client
        .from('matchmaking_queue')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'searching')
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return MatchmakingQueueEntry.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<String?> getMatchedGameId() async {
    final rows = await _client
        .from('matchmaking_queue')
        .select('matched_game_id,status')
        .eq('user_id', _userId)
        .eq('status', 'matched')
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['matched_game_id'] as String?;
  }

  Future<Map<String, dynamic>> getGame(String gameId) async {
    final result = await _client
        .from('games')
        .select()
        .eq('id', gameId)
        .single();

    return Map<String, dynamic>.from(result);
  }

  Future<void> setOnline() async {
    await _client.rpc('set_player_presence', params: {'p_status': 'online'});
  }

  Future<void> setOffline() async {
    await _client.rpc('set_player_presence', params: {'p_status': 'offline'});
  }

  RealtimeChannel watchQueue({required void Function() onChanged}) {
    final channel = _client
        .channel('matchmaking:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matchmaking_queue',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (_) => onChanged(),
        );

    channel.subscribe();

    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
