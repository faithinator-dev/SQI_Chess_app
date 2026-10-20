import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/delete_account_dialog.dart';
import '../widgets/settings_tile.dart';
import 'settings_page.dart';

class AccountActionsScreen extends StatelessWidget {
  const AccountActionsScreen({super.key});

  Future<void> _changeEmail(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      await showSettingsErrorDialog(
        context,
        title: 'You’re signed out',
        message: 'Sign in again before changing your email address.',
      );
      return;
    }

    final controller = TextEditingController(text: user.email ?? '');
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update email'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
            validator: (value) {
              final candidate = value?.trim() ?? '';
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(candidate)
                  ? null
                  : 'Enter a valid email address.';
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email == user.email) return;

    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(email: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email to confirm the address change.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        await showSettingsErrorDialog(
          context,
          title: 'Could not update email',
          message: 'Your email was not changed. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (value) => value == null || value.length < 8
                ? 'Use at least 8 characters.'
                : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;

    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        await showSettingsErrorDialog(
          context,
          title: 'Could not update password',
          message: 'Your password was not changed. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (context.mounted) {
        await showSettingsErrorDialog(
          context,
          title: 'Could not sign out',
          message: 'You are still signed in. Check your connection and try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account actions')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.email_outlined,
                title: 'Change email',
                subtitle: 'Update your sign-in email address',
                onTap: () => _changeEmail(context),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                subtitle: 'Set a new account password',
                onTap: () => _changePassword(context),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.logout,
                title: 'Sign out',
                subtitle: 'Sign out of this device',
                danger: true,
                onTap: () => _signOut(context),
              ),
              const Divider(height: 1, indent: 56),
              SettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete account',
                subtitle: 'Permanently remove your account',
                danger: true,
                onTap: () => showDeleteAccountDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Account deletion is currently unavailable until the secure server-side deletion workflow is implemented.',
          ),
        ),
      ],
    ),
  );
}
