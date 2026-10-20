import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/competition_model.dart';

class CompetitionRepository {
  CompetitionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CompetitionModel>> getCompetitions({
    String? status,
    String? search,
    int limit = 50,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('competitions')
        .select('*, competition_registrations(user_id, status)')
        .neq('status', 'draft')
        .order('starts_at', ascending: true)
        .limit(limit);

    return rows
        .where((row) {
          final map = Map<String, dynamic>.from(row);
          final matchesStatus =
              status == null ||
              status == 'All' ||
              map['status'] == _databaseStatus(status);
          final query = search?.trim().toLowerCase() ?? '';
          final matchesSearch =
              query.isEmpty ||
              (map['title'] as String).toLowerCase().contains(query);
          return matchesStatus && matchesSearch;
        })
        .map((row) {
          final map = Map<String, dynamic>.from(row);
          final registrations =
              (map.remove('competition_registrations') as List?)
                  ?.whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              const <Map<String, dynamic>>[];
          final mine = registrations.any(
            (item) =>
                item['user_id'] == user.id && item['status'] == 'registered',
          );
          final count = registrations
              .where((item) => item['status'] == 'registered')
              .length;

          return CompetitionModel.fromMap(
            map,
            registered: mine,
            registeredPlayers: count,
          );
        })
        .toList();
  }

  Future<void> register(String competitionId) async {
    await _client.rpc(
      'register_for_competition',
      params: {'p_competition_id': competitionId},
    );
  }

  Future<void> withdraw(String competitionId) async {
    await _client.rpc(
      'withdraw_from_competition',
      params: {'p_competition_id': competitionId},
    );
  }

  String _databaseStatus(String value) {
    switch (value) {
      case 'Upcoming':
        return 'registration_open';
      case 'Live':
        return 'in_progress';
      case 'Completed':
        return 'completed';
      default:
        return value.toLowerCase();
    }
  }
}
