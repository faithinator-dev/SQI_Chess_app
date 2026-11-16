import 'package:flutter/material.dart';
import '../../../app/app.dart' show updateAppAppearance;
import '../controllers/settings_controller.dart';
import '../widgets/settings_dropdown_tile.dart';
import 'settings_page.dart';
import '../../../core/repositories/guest_preferences_repository.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});
  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  late final SettingsController c;
  String _appearance = 'Light';
  @override
  void initState() {
    super.initState();
    c = SettingsController()..load();
    _loadLocalAppearance();
  }

  Future<void> _loadLocalAppearance() async {
    final saved = await GuestPreferencesRepository().getAppearance();
    if (!mounted ||
        saved == null ||
        !const ['Light', 'Dark', 'System'].contains(saved)) {
      return;
    }
    setState(() => _appearance = saved);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    await c.retry();
    if (mounted && c.settings != null) {
      updateAppAppearance(context, c.settings!.appearance);
    }
  }

  Future<void> _changeAppearance(String value) async {
    setState(() => _appearance = value);
    updateAppAppearance(context, value);
    await GuestPreferencesRepository().saveAppearance(value);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final s = c.settings;
      return SettingsPage(
        title: 'App preferences',
        description: 'Personalize how SQI Checkmate looks and displays time.',
        // Theme is a local preference. A previous cloud settings failure must
        // not keep showing a save error while the user changes appearance.
        errorMessage: null,
        onRetry: null,
        children: [
          SettingsDropdownTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            value: _appearance,
            options: const ['System', 'Light', 'Dark'],
            onChanged: _changeAppearance,
          ),
          settingsDivider(),
          if (s == null) ...[
            SizedBox(
              height: 260,
              child: SettingsLoadState(
                loading: c.loading,
                error: c.error,
                onRetry: _retry,
              ),
            ),
          ] else ...[
            SettingsDropdownTile(
              icon: Icons.language_outlined,
              title: 'Language',
              value: s.language,
              options: const ['English'],
              onChanged: (v) => c.update(s.copyWith(language: v)),
            ),
            settingsDivider(),
            SettingsDropdownTile(
              icon: Icons.schedule_outlined,
              title: 'Timezone',
              value: s.timezone,
              options: const ['Africa/Lagos'],
              onChanged: (v) => c.update(s.copyWith(timezone: v)),
            ),
          ],
        ],
      );
    },
  );
}
