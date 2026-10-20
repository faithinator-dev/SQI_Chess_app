import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_settings_model.dart';

class SettingsRepository {
  SettingsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<UserSettingsModel> getCurrentSettings() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final data = await _client
        .from('user_settings')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (data != null) {
      return UserSettingsModel.fromMap(data);
    }

    final defaults = UserSettingsModel(
      userId: user.id,
      timezone: _detectTimezone(),
    );

    final inserted = await _client
        .from('user_settings')
        .upsert(defaults.toMap(), onConflict: 'user_id')
        .select()
        .single();

    return UserSettingsModel.fromMap(inserted);
  }

  Future<UserSettingsModel> saveSettings(UserSettingsModel settings) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    if (settings.userId != user.id) {
      throw StateError('You cannot modify another user\'s settings.');
    }

    final data = await _client
        .from('user_settings')
        .upsert(settings.toMap(), onConflict: 'user_id')
        .select()
        .single();

    return UserSettingsModel.fromMap(data);
  }

  Future<void> updateProfileVisibility(bool visible) async {
    final result = await _client.rpc(
      'update_my_profile_visibility',
      params: {'p_public_profile': visible},
    );

    if (result is! Map && result is! Map<String, dynamic>) {
      throw StateError('Profile visibility could not be updated.');
    }
  }

  String _detectTimezone() {
    final offset = DateTime.now().timeZoneOffset;

    if (offset.inMinutes == 60) {
      return 'Africa/Lagos';
    }

    return 'Africa/Lagos';
  }
}
