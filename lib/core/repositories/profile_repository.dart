import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ProfileModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    final preferences = await SharedPreferences.getInstance();

    if (user == null) {
      final cached = preferences.getString('profile_cache_last');
      if (cached == null) return null;
      return ProfileModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    }

    final cacheKey = 'profile_cache_${user.id}';
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final profile = ProfileModel.fromMap(data);
        final encoded = jsonEncode(profile.toMap());
        await preferences.setString(cacheKey, encoded);
        await preferences.setString('profile_cache_last', encoded);
        return profile;
      }
    } catch (_) {
      // Fall through to the last locally cached profile when offline.
    }

    final cached = preferences.getString(cacheKey);
    if (cached != null) {
      return ProfileModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(cached) as Map),
      );
    }

    return ProfileModel(
      id: user.id,
      username: user.userMetadata?['username'] as String? ?? 'player',
      fullName: user.userMetadata?['full_name'] as String? ?? 'SQI Player',
      skillLevel: 'Beginner',
      chessRating: 1000,
      gamesPlayed: 0,
      wins: 0,
      losses: 0,
      draws: 0,
      currentStreak: 0,
      sqiStatus: 'Student',
      role: 'player',
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
    );
  }

  Future<ProfileModel> updateCurrentProfile({
    required String fullName,
    required String username,
    required String bio,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in to update your profile.');
    }

    final cleanFullName = fullName.trim();
    final cleanUsername = username.trim().toLowerCase();
    final cleanBio = bio.trim();

    if (cleanFullName.isEmpty) {
      throw const FormatException('Full name cannot be empty.');
    }

    if (cleanUsername.isEmpty) {
      throw const FormatException('Username cannot be empty.');
    }

    final result = await _client.rpc(
      'update_my_profile',
      params: {
        'p_full_name': cleanFullName,
        'p_username': cleanUsername,
        'p_bio': cleanBio,
      },
    );

    if (result is Map<String, dynamic>) {
      return ProfileModel.fromMap(result);
    }

    if (result is Map) {
      return ProfileModel.fromMap(Map<String, dynamic>.from(result));
    }

    final profile = await getCurrentProfile();

    if (profile == null) {
      throw StateError('Profile could not be loaded after saving.');
    }

    return profile;
  }
}
