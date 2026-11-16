import 'package:supabase_flutter/supabase_flutter.dart';

class FriendRecord {
  const FriendRecord({
    required this.requestId,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.status,
    required this.isIncoming,
  });

  final String requestId;
  final String userId;
  final String username;
  final String fullName;
  final String status;
  final bool isIncoming;
}

class FriendsRepository {
  FriendsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw StateError('Sign in to use friends.'));

  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final clean = query.trim().replaceFirst(RegExp(r'^@'), '');
    if (clean.isEmpty) return [];
    final rows = await _client
        .from('profiles')
        .select('id,username,full_name,chess_rating')
        .ilike('username', '%$clean%')
        .neq('id', _userId)
        .order('username')
        .limit(20);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<FriendRecord>> getRelationships() async {
    final rows = await _client
        .from('friend_requests')
        .select('id,requester_id,addressee_id,status')
        .or('requester_id.eq.$_userId,addressee_id.eq.$_userId')
        .order('updated_at', ascending: false);
    final ids = rows
        .map(
          (row) => row['requester_id'] == _userId
              ? row['addressee_id']
              : row['requester_id'],
        )
        .cast<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return [];
    final profiles = await _client
        .from('profiles')
        .select('id,username,full_name')
        .inFilter('id', ids);
    final byId = <String, Map<String, dynamic>>{
      for (final profile in profiles)
        profile['id'] as String: Map<String, dynamic>.from(profile),
    };
    return rows.map((row) {
      final incoming = row['addressee_id'] == _userId;
      final id = incoming
          ? row['requester_id'] as String
          : row['addressee_id'] as String;
      final profile = byId[id] ?? {};
      return FriendRecord(
        requestId: row['id'] as String,
        userId: id,
        username: profile['username'] as String? ?? 'player',
        fullName: profile['full_name'] as String? ?? 'Player',
        status: row['status'] as String,
        isIncoming: incoming,
      );
    }).toList();
  }

  Future<void> sendRequest(String username) async {
    await _client.rpc(
      'send_friend_request',
      params: {'p_username': username.trim()},
    );
  }

  Future<void> respond(String requestId, bool accept) async {
    await _client.rpc(
      'respond_friend_request',
      params: {'p_request_id': requestId, 'p_accept': accept},
    );
  }

  Future<void> remove(String friendId) async {
    await _client.rpc('remove_friend', params: {'p_friend_id': friendId});
  }

  Future<String> createChallenge(String friendId) async {
    final result = await _client.rpc(
      'create_friend_game',
      params: {'p_opponent_id': friendId},
    );
    return (result as Map)['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getInvitations() async {
    final rows = await _client
        .from('games')
        .select('id,white_player_id,created_at')
        .eq('game_type', 'online_friend')
        .eq('status', 'pending')
        .eq('invited_player_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
