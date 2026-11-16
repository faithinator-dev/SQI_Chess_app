import 'package:flutter/material.dart';

import '../../core/repositories/guest_preferences_repository.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class GuestSettingsScreen extends StatefulWidget {
  const GuestSettingsScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<GuestSettingsScreen> createState() => _GuestSettingsScreenState();
}

class _GuestSettingsScreenState extends State<GuestSettingsScreen> {
  late final TextEditingController _nameController;
  final _preferences = GuestPreferencesRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.length < 2 || name.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name must be 2 to 20 characters.')));
      return;
    }
    await _preferences.saveName(name);
    if (mounted) Navigator.pop(context, name);
  }

  Future<void> _openAccount(Widget page) async {
    await _preferences.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => page), (route) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guest settings')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your guest profile', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(controller: _nameController, maxLength: 20, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Player name')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _saveName, icon: const Icon(Icons.save_outlined), label: const Text('Save name')),
        const SizedBox(height: 28),
        Text('Use a full account', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Sign in or create an account to use online features. Your guest name stays saved on this device.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => _openAccount(const LoginScreen()), icon: const Icon(Icons.login), label: const Text('Sign in')),
        OutlinedButton.icon(onPressed: () => _openAccount(const RegisterScreen()), icon: const Icon(Icons.person_add_alt_1), label: const Text('Create account')),
      ],
    ),
  );
}

