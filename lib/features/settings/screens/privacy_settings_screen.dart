import 'package:flutter/material.dart';

import '../../../core/models/profile_model.dart';
import '../../../core/repositories/profile_repository.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_switch_tile.dart';
import 'settings_page.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late final SettingsController _controller;
  ProfileModel? _profile;
  bool _profileLoading = true;
  bool _profileFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController()..load();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _profileLoading = true;
        _profileFailed = false;
      });
    }
    try {
      final profile = await ProfileRepository().getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _profileFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final settings = _controller.settings;
      final profileError = _profileFailed
          ? 'We could not load profile visibility. Check your connection and retry.'
          : null;
      return SettingsPage(
        title: 'Privacy',
        description: 'Control profile visibility and interface motion.',
        errorMessage: settings == null || _profileFailed ? null : _controller.error,
        onRetry: () {
          _controller.retry();
          _loadProfile();
        },
        children: [
          if (settings == null || _profileLoading || _profileFailed)
            SizedBox(
              height: 260,
              child: SettingsLoadState(
                loading: _controller.loading || _profileLoading,
                error: profileError ?? _controller.error,
                onRetry: () {
                  _controller.retry();
                  _loadProfile();
                },
              ),
            )
          else ...[
            SettingsSwitchTile(
              icon: Icons.public_outlined,
              title: 'Public profile',
              subtitle: 'Allow other players to view your profile',
              value: _profile?.publicProfile ?? true,
              onChanged: (value) async {
                try {
                  await _controller.updateVisibility(value);
                  await _loadProfile();
                } catch (_) {
                  if (context.mounted) {
                    await showSettingsErrorDialog(
                      context,
                      title: 'Could not update privacy',
                      message: 'Your profile visibility was not changed. Check your connection and try again.',
                    );
                  }
                }
              },
            ),
            settingsDivider(),
            SettingsSwitchTile(
              icon: Icons.accessibility_new_outlined,
              title: 'Reduce motion',
              subtitle: 'Minimize non-essential animations',
              value: settings.reduceMotion,
              onChanged: (value) => _controller.update(
                settings.copyWith(reduceMotion: value),
              ),
            ),
          ],
        ],
      );
    },
  );
}
