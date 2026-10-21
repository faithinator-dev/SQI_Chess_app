import 'package:flutter/material.dart';
import '../../../app/app.dart' show updateAppAppearance;
import '../controllers/settings_controller.dart';
import '../widgets/settings_dropdown_tile.dart';
import 'settings_page.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});
  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  late final SettingsController c;
  @override
  void initState() {
    super.initState();
    c = SettingsController()..load();
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final s = c.settings;
      return SettingsPage(
        title: 'App preferences',
        description: 'Personalize how SQI Checkmate looks and displays time.',
        errorMessage: s == null ? null : c.error,
        onRetry: _retry,
        children: s == null
            ? [
                SizedBox(
                  height: 260,
                  child: SettingsLoadState(
                    loading: c.loading,
                    error: c.error,
                    onRetry: _retry,
                  ),
                ),
              ]
            : [
                SettingsDropdownTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  value: s.appearance,
                  options: const ['System', 'Light', 'Dark'],
                  onChanged: (v) async {
                    await c.update(s.copyWith(appearance: v));
                    if (mounted && c.settings != null)
                      updateAppAppearance(context, c.settings!.appearance);
                  },
                ),
                settingsDivider(),
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
      );
    },
  );
}
