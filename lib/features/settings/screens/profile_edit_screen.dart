import 'package:flutter/material.dart';

import '../../../core/models/profile_model.dart';
import '../../../core/repositories/profile_repository.dart';
import '../widgets/settings_tile.dart';
import 'settings_page.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _repository = ProfileRepository();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();

  ProfileModel? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _repository.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _name.text = profile?.fullName ?? '';
        _username.text = profile?.username ?? '';
        _bio.text = profile?.bio ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError =
            'We couldn’t load your profile. Check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.updateCurrentProfile(
        fullName: _name.text,
        username: _username.text,
        bio: _bio.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        await showSettingsErrorDialog(
          context,
          title: 'Could not save profile',
          message:
              'Your profile changes were not saved. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? SettingsLoadState(
              loading: false,
              error: _loadError ?? 'No profile is available for this account.',
              onRetry: _load,
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      child: Text(
                        _profile!.initials,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: _decoration('Full name', Icons.person_outline),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Full name is required.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _username,
                    decoration: _decoration(
                      'Chess handle',
                      Icons.alternate_email,
                    ),
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.length < 3)
                        return 'Use at least 3 characters.';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
                        return 'Use letters, numbers and underscores.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    decoration: _decoration('Chess bio', Icons.notes_outlined),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Icons.emoji_events_outlined,
                          title: 'Chess rating',
                          value: _profile!.formattedRating,
                        ),
                        const Divider(height: 1),
                        SettingsTile(
                          icon: Icons.school_outlined,
                          title: 'SQI affiliation',
                          subtitle:
                              [
                                    _profile!.department,
                                    _profile!.level,
                                    _profile!.campus,
                                  ]
                                  .whereType<String>()
                                  .where((value) => value.isNotEmpty)
                                  .join(' · '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Saving...' : 'Save profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
