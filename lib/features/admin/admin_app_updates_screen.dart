import 'package:flutter/material.dart';

import '../../core/models/app_release_model.dart';
import '../../core/repositories/app_update_repository.dart';

class AdminAppUpdatesScreen extends StatefulWidget {
  const AdminAppUpdatesScreen({super.key});

  @override
  State<AdminAppUpdatesScreen> createState() => _AdminAppUpdatesScreenState();
}

class _AdminAppUpdatesScreenState extends State<AdminAppUpdatesScreen> {
  static const _background = Color(0xFFF9F8F6);
  static const _surface = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2D4A3E);
  static const _muted = Color(0xFF737A74);

  final AppUpdateRepository _repository = AppUpdateRepository();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<AppReleaseModel> _releases = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final releases = await _repository.getReleasesForAdmin();
      if (!mounted) return;
      setState(() {
        _releases = releases;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'App update releases could not be loaded.';
        _loading = false;
      });
    }
  }

  Future<void> _setPublished(AppReleaseModel release, bool value) async {
    try {
      await _repository.setPublished(releaseId: release.id, published: value);
      await _load();
    } catch (error) {
      _message('Release status could not be changed: $error');
    }
  }

  Future<void> _createRelease() async {
    final version = TextEditingController();
    final build = TextEditingController();
    final title = TextEditingController();
    final purpose = TextEditingController();
    final changes = TextEditingController();
    final instructions = TextEditingController();
    final url = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String platform = 'android';
    String? formError;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          title: const Text('Publish an app update'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width * .82)
                .clamp(240.0, 460.0)
                .toDouble(),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: platform,
                      decoration: const InputDecoration(labelText: 'Platform'),
                      items: const [
                        DropdownMenuItem(
                          value: 'android',
                          child: Text('Android'),
                        ),
                        DropdownMenuItem(value: 'ios', child: Text('iOS')),
                        DropdownMenuItem(
                          value: 'windows',
                          child: Text('Windows'),
                        ),
                        DropdownMenuItem(value: 'macos', child: Text('macOS')),
                        DropdownMenuItem(value: 'linux', child: Text('Linux')),
                        DropdownMenuItem(value: 'web', child: Text('Web')),
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All platforms'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => platform = value);
                        }
                      },
                    ),
                    _field(version, 'Version name', required: true),
                    _field(
                      build,
                      'Build number',
                      required: true,
                      numeric: true,
                    ),
                    _field(title, 'Release title', required: true),
                    _field(purpose, 'Purpose', required: true, lines: 3),
                    _field(
                      changes,
                      'What changes? (one item per line)',
                      lines: 4,
                    ),
                    _field(
                      instructions,
                      'How to install',
                      required: true,
                      lines: 3,
                    ),
                    _field(url, 'HTTPS download or store URL', required: true),
                    if (formError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        formError!,
                        style: const TextStyle(color: Color(0xFFB56767)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final buildNumber = int.tryParse(build.text.trim());
                      if (buildNumber == null || buildNumber <= 0) {
                        setDialogState(
                          () => formError =
                              'Build number must be a positive whole number.',
                        );
                        return;
                      }
                      setDialogState(() {
                        _saving = true;
                        formError = null;
                      });
                      try {
                        await _repository.createRelease(
                          platform: platform,
                          versionName: version.text,
                          buildNumber: buildNumber,
                          title: title.text,
                          purpose: purpose.text,
                          changes: changes.text
                              .split('\n')
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .toList(),
                          instructions: instructions.text,
                          downloadUrl: url.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        setDialogState(
                          () => formError = 'Could not publish update: $error',
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Publishing…' : 'Publish'),
            ),
          ],
        ),
      ),
    );

    version.dispose();
    build.dispose();
    title.dispose();
    purpose.dispose();
    changes.dispose();
    instructions.dispose();
    url.dispose();
    if (created == true && mounted) await _load();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text('App Updates'),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _createRelease,
        icon: const Icon(Icons.publish_rounded),
        label: const Text('Publish update'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: _muted)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _releases.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Icon(
                          Icons.system_update_alt_rounded,
                          size: 44,
                          color: _muted,
                        ),
                        SizedBox(height: 14),
                        Center(
                          child: Text(
                            'No releases have been published.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _releases.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _releaseTile(_releases[index]),
                    ),
            ),
    );
  }

  Widget _releaseTile(AppReleaseModel release) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded, color: _blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  release.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${release.versionName} • Build ${release.buildNumber} • ${release.platform.toUpperCase()}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: release.isPublished,
            onChanged: (value) => _setPublished(release, value),
          ),
        ],
      ),
    );
  }
}
