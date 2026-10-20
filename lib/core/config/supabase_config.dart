import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const String _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _definedPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _definedAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _definedLegacyPublishableKey = String.fromEnvironment(
    'sb_publishable',
  );

  static String get url =>
      _definedUrl.isNotEmpty ? _definedUrl : dotenv.env['SUPABASE_URL'] ?? '';

  static String get publishableKey {
    if (_definedPublishableKey.isNotEmpty) return _definedPublishableKey;
    if (_definedAnonKey.isNotEmpty) return _definedAnonKey;
    if (_definedLegacyPublishableKey.isNotEmpty) {
      return _definedLegacyPublishableKey.startsWith('sb_publishable_')
          ? _definedLegacyPublishableKey
          : 'sb_publishable_$_definedLegacyPublishableKey';
    }
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'] ??
        '';
  }

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static void validate() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. '
        'Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to assets/.env, '
        'or pass the values with --dart-define.',
      );
    }
  }
}
