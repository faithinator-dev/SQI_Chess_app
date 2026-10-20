import 'package:flutter/foundation.dart';

import '../../../core/models/user_settings_model.dart';
import '../../../core/repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;
  UserSettingsModel? settings;
  bool loading = true;
  bool saving = false;
  String? error;
  UserSettingsModel? _retrySettings;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      settings = await _repository.getCurrentSettings();
    } catch (_) {
      error = 'We could not load your settings. Check your connection and try again.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> update(UserSettingsModel next) async {
    if (saving) return;
    final previous = settings;
    error = null;
    _retrySettings = null;
    settings = next;
    saving = true;
    notifyListeners();
    try {
      settings = await _repository.saveSettings(next);
    } catch (_) {
      settings = previous;
      error = 'We could not save that change. Your previous setting has been kept.';
      _retrySettings = next;
    }
    saving = false;
    notifyListeners();
  }

  Future<void> retry() async {
    final pendingSettings = _retrySettings;
    if (pendingSettings != null) return update(pendingSettings);
    return load();
  }

  Future<void> updateVisibility(bool visible) =>
      _repository.updateProfileVisibility(visible);
}
