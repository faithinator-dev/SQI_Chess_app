import 'package:shared_preferences/shared_preferences.dart';

class GuestPreferencesRepository {
  static const _nameKey = 'guest_player_name_v1';
  static const _activeKey = 'guest_session_active_v1';
  static const _appearanceKey = 'app_appearance_v1';

  Future<String?> getName() async =>
      (await SharedPreferences.getInstance()).getString(_nameKey);

  Future<String?> getActiveGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_activeKey) ?? false)) return null;
    return prefs.getString(_nameKey);
  }

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  Future<void> startSession(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setBool(_activeKey, true);
  }

  Future<void> endSession() async =>
      (await SharedPreferences.getInstance()).setBool(_activeKey, false);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_activeKey);
  }

  Future<String?> getAppearance() async =>
      (await SharedPreferences.getInstance()).getString(_appearanceKey);

  Future<void> saveAppearance(String appearance) async =>
      (await SharedPreferences.getInstance()).setString(_appearanceKey, appearance);
}
