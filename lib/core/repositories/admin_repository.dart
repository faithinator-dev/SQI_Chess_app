import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository {
  AdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, int>> getDashboardStats() async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to view the admin dashboard.');
    }
    final results = await Future.wait([
      _client.from('profiles').select('id').count(CountOption.exact),
      _client.from('games').select('id').count(CountOption.exact),
      _client
          .from('games')
          .select('id')
          .eq('status', 'active')
          .count(CountOption.exact),
      _client
          .from('competitions')
          .select('id')
          .neq('status', 'cancelled')
          .count(CountOption.exact),
    ]);
    return {
      'players': results[0].count,
      'games': results[1].count,
      'active_games': results[2].count,
      'competitions': results[3].count,
    };
  }

  Future<List<Map<String, dynamic>>> getPlayers() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw StateError('Sign in to manage players.');

    final profiles = await _client
        .from('profiles')
        .select(
          'id, username, full_name, skill_level, chess_rating, games_played, role, created_at',
        )
        .order('created_at', ascending: false)
        .limit(200);
    final ids = profiles.map((row) => row['id'] as String).toList();
    final presence = ids.isEmpty
        ? <dynamic>[]
        : await _client
              .from('player_presence')
              .select('user_id,status')
              .inFilter('user_id', ids);
    final statusByUser = <String, String>{
      for (final row in presence)
        row['user_id'] as String: row['status'] as String,
    };

    return profiles.map((row) {
      final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
      return <String, dynamic>{
        'id': row['id'] as String,
        'name': row['full_name'] as String? ?? 'SQI Player',
        'username': '@${row['username'] as String? ?? ''}',
        'rating': row['chess_rating'] as int? ?? 0,
        'level': row['skill_level'] as String? ?? 'Beginner',
        'games': row['games_played'] as int? ?? 0,
        'role': row['role'] as String? ?? 'player',
        'status': _displayStatus(statusByUser[row['id']] ?? 'offline'),
        'joinedAt': createdAt,
        'joined': createdAt == null
            ? 'Unknown'
            : '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
      };
    }).toList();
  }

  Future<void> setPlayerAdminRole(
    String playerId, {
    required bool makeAdmin,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to manage administrator roles.');
    }
    await _client.rpc(
      'set_player_admin_role',
      params: {'p_user_id': playerId, 'p_make_admin': makeAdmin},
    );
  }

  static String _displayStatus(String status) => switch (status) {
    'online' => 'Online',
    'playing' => 'Playing',
    'away' => 'Away',
    _ => 'Offline',
  };
}
