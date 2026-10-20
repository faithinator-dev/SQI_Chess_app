import 'package:flutter/material.dart';
import '../settings/screens/settings_overview_screen.dart';

/// Backward-compatible entry point used by the profile tab.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const SettingsOverviewScreen();
}
