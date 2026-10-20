import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_switch_tile.dart';
import 'settings_page.dart';

class NotificationSettingsScreen extends StatefulWidget { const NotificationSettingsScreen({super.key}); @override State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState(); }
class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late final SettingsController c;
  @override void initState() { super.initState(); c = SettingsController()..load(); }
  @override void dispose() { c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: c, builder: (context, _) {
    final s = c.settings;
    return SettingsPage(title: 'Notifications', description: 'Choose which updates you receive.', errorMessage: s == null ? null : c.error, onRetry: c.retry, children: s == null ? [SizedBox(height: 260, child: SettingsLoadState(loading: c.loading, error: c.error, onRetry: c.retry))] : [
      SettingsSwitchTile(icon: Icons.notifications_active_outlined, title: 'Notifications', subtitle: 'Master notification preference', value: s.notifications, onChanged: (v) => c.update(s.copyWith(notifications: v))),
      settingsDivider(), SettingsSwitchTile(icon: Icons.phone_iphone, title: 'Push notifications', value: s.pushNotifications, onChanged: (v) => c.update(s.copyWith(pushNotifications: v))),
      settingsDivider(), SettingsSwitchTile(icon: Icons.email_outlined, title: 'Email notifications', value: s.emailNotifications, onChanged: (v) => c.update(s.copyWith(emailNotifications: v))),
      settingsDivider(), SettingsSwitchTile(icon: Icons.mail_outline, title: 'Match invites', subtitle: 'When another player invites you to a game', value: s.matchInvites, onChanged: (v) => c.update(s.copyWith(matchInvites: v))),
      settingsDivider(), SettingsSwitchTile(icon: Icons.alternate_email, title: 'Community mentions', subtitle: 'When someone mentions you in the community', value: s.communityMentions, onChanged: (v) => c.update(s.copyWith(communityMentions: v))),
    ]);
  });
}
