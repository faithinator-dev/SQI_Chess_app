import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_switch_tile.dart';
import 'settings_page.dart';

class GamePreferencesScreen extends StatefulWidget {
  const GamePreferencesScreen({super.key});
  @override
  State<GamePreferencesScreen> createState() => _GamePreferencesScreenState();
}

class _GamePreferencesScreenState extends State<GamePreferencesScreen> {
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) {
      final s = c.settings;
      return SettingsPage(
        title: 'Game preferences',
        description: 'Set how games and the chessboard behave.',
        errorMessage: s == null ? null : c.error,
        onRetry: c.retry,
        children: s == null
            ? [
                SizedBox(
                  height: 260,
                  child: SettingsLoadState(
                    loading: c.loading,
                    error: c.error,
                    onRetry: c.retry,
                  ),
                ),
              ]
            : [
                SettingsSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound effects',
                  subtitle: 'Play sounds during a game',
                  value: s.gameSounds,
                  onChanged: (v) => c.update(s.copyWith(gameSounds: v)),
                ),
                settingsDivider(),
                SettingsSwitchTile(
                  icon: Icons.vibration,
                  title: 'Vibration',
                  subtitle: 'Haptic feedback for game actions',
                  value: s.vibration,
                  onChanged: (v) => c.update(s.copyWith(vibration: v)),
                ),
                settingsDivider(),
                SettingsSwitchTile(
                  icon: Icons.grid_on_outlined,
                  title: 'Board coordinates',
                  subtitle: 'Show rank and file labels on the board',
                  value: s.boardCoordinates,
                  onChanged: (v) => c.update(s.copyWith(boardCoordinates: v)),
                ),
                settingsDivider(),
                SettingsSwitchTile(
                  icon: Icons.flag_outlined,
                  title: 'Confirm resignation',
                  subtitle: 'Ask before resigning a game',
                  value: s.confirmResignation,
                  onChanged: (v) => c.update(s.copyWith(confirmResignation: v)),
                ),
              ],
      );
    },
  );
}
