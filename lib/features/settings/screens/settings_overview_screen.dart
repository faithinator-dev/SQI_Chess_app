import 'package:flutter/material.dart';

import '../../../core/models/profile_model.dart';
import '../../../core/repositories/profile_repository.dart';
import '../widgets/settings_tile.dart';
import 'about_support_screen.dart';
import 'account_actions_screen.dart';
import 'app_preferences_screen.dart';
import 'game_preferences_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'profile_edit_screen.dart';
import 'settings_page.dart';

class SettingsOverviewScreen extends StatefulWidget {
  const SettingsOverviewScreen({super.key});

  @override
  State<SettingsOverviewScreen> createState() => _SettingsOverviewScreenState();
}

class _SettingsOverviewScreenState extends State<SettingsOverviewScreen> {
  ProfileModel? _profile;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profile = await ProfileRepository().getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loadFailed)
          SettingsErrorBanner(
            message:
                'We couldn’t load your profile. Check your connection and retry.',
            onRetry: _load,
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _loadFailed
                              ? Icons.person_off_outlined
                              : Icons.person_outline,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'Loading profile...'
                            : _loadFailed
                            ? 'Profile unavailable'
                            : (_profile?.fullName ?? 'Your account'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _loadFailed
                            ? 'Retry loading your account details above'
                            : _profile == null
                            ? 'Manage your account and preferences'
                            : '@${_profile!.username}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: 'Name, chess handle and bio',
                onTap: () => _open(const ProfileEditScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: 'Push, email and community updates',
                onTap: () => _open(const NotificationSettingsScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.sports_esports_outlined,
                title: 'Game preferences',
                subtitle: 'Board and match behavior',
                onTap: () => _open(const GamePreferencesScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: 'Profile visibility and motion',
                onTap: () => _open(const PrivacySettingsScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.tune,
                title: 'App preferences',
                subtitle: 'Theme, language and timezone',
                onTap: () => _open(const AppPreferencesScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.help_outline,
                title: 'About & support',
                subtitle: 'Updates, policies and help',
                onTap: () => _open(const AboutSupportScreen()),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.manage_accounts_outlined,
                title: 'Account actions',
                subtitle: 'Sign out and account deletion',
                onTap: () => _open(const AccountActionsScreen()),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
