import 'package:flutter/material.dart';
import '../../profile/app_update_screen.dart';
import '../widgets/settings_tile.dart';

class AboutSupportScreen extends StatelessWidget {
  const AboutSupportScreen({super.key});
  void _info(BuildContext context, String title, String body) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About & support')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.system_update_alt,
                title: 'App updates',
                subtitle: 'Check for a release and review changes',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
                ),
              ),

              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About SQI Checkmate',
                subtitle: 'Chess for the SQI community',
                onTap: () => _info(
                  context,
                  'SQI Checkmate Arena',
                  'A competitive chess platform built for SQI players.',
                ),
              ),

              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Terms & privacy',
                subtitle: 'Platform policies and privacy information',
                onTap: () => _info(
                  context,
                  'Terms & privacy',
                  'The production legal documents will be connected here before launch.',
                ),
              ),

              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.support_agent_outlined,
                title: 'Help & support',
                subtitle: 'Get assistance with your account',
                onTap: () => _info(
                  context,
                  'Help & support',
                  'Support channels will be connected here.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
