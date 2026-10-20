import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_release_model.dart';

class AppUpdateRepository {
  AppUpdateRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AppReleaseModel?> getLatestAvailable({
    required String platform,
    required int currentBuild,
  }) async {
    final rows = await _client
        .from('app_updates')
        .select()
        .eq('is_published', true)
        .inFilter('platform', [platform, 'all'])
        .gt('build_number', currentBuild)
        .order('build_number', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return AppReleaseModel.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<List<AppReleaseModel>> getReleasesForAdmin() async {
    final isAdmin = await _client.rpc('current_user_is_admin');
    if (isAdmin != true) {
      throw StateError('Administrator access is required.');
    }
    final rows = await _client
        .from('app_updates')
        .select()
        .order('created_at', ascending: false);
    return rows
        .map((row) => AppReleaseModel.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<void> createRelease({
    required String platform,
    required String versionName,
    required int buildNumber,
    required String title,
    required String purpose,
    required List<String> changes,
    required String instructions,
    required String downloadUrl,
  }) async {
    final isAdmin = await _client.rpc('current_user_is_admin');
    if (isAdmin != true) {
      throw StateError('Administrator access is required.');
    }
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Use a valid HTTPS download or store URL.');
    }
    await _client.from('app_updates').insert({
      'platform': platform,
      'version_name': versionName.trim(),
      'build_number': buildNumber,
      'title': title.trim(),
      'purpose': purpose.trim(),
      'changes': changes,
      'instructions': instructions.trim(),
      'download_url': uri.toString(),
      'is_published': true,
    });
  }

  Future<void> setPublished({
    required String releaseId,
    required bool published,
  }) async {
    final isAdmin = await _client.rpc('current_user_is_admin');
    if (isAdmin != true) {
      throw StateError('Administrator access is required.');
    }
    await _client
        .from('app_updates')
        .update({'is_published': published})
        .eq('id', releaseId);
  }
}
