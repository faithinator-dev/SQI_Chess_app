import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/app_release_model.dart';
import '../../core/repositories/app_update_repository.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  static const _background = Color(0xFFF9F8F6);
  static const _surface = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF2D4A3E);
  static const _green = Color(0xFF557B63);
  static const _gold = Color(0xFFF5C451);
  static const _muted = Color(0xFF737A74);

  final AppUpdateRepository _repository = AppUpdateRepository();
  bool _loading = true;
  bool _openingLink = false;
  String? _error;
  String _currentVersion = 'Unknown';
  String _platform = 'all';
  AppReleaseModel? _release;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final package = await PackageInfo.fromPlatform();
      final platform = _platformName();
      final build = int.tryParse(package.buildNumber) ?? 0;
      final release = await _repository.getLatestAvailable(
        platform: platform,
        currentBuild: build,
      );
      if (!mounted) return;
      setState(() {
        _currentVersion = '${package.version}+${package.buildNumber}';
        _platform = platform;
        _release = release;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Could not check for updates. Check your connection and retry.';
      });
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'all',
    };
  }

  Future<void> _startDownload() async {
    final release = _release;
    if (release == null || _openingLink) return;
    final uri = Uri.tryParse(release.downloadUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _showMessage(
        'This release has an invalid download link. Contact support.',
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: Text('Download ${release.versionName}?'),
        content: Text(
          'You are leaving SQI Checkmate Arena to download from ${uri.host}. '
          'Review the release details on this page before continuing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    setState(() => _openingLink = true);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Could not open the update download link.');
      }
    } catch (_) {
      if (mounted) _showMessage('Could not open the update download link.');
    } finally {
      if (mounted) setState(() => _openingLink = false);
    }
  }

  void _showMessage(String message) {
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
            onPressed: _loading ? null : _checkForUpdate,
            tooltip: 'Check again',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : _error != null
            ? _errorState()
            : RefreshIndicator(
                onRefresh: _checkForUpdate,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                  children: [
                    _currentVersionCard(),
                    const SizedBox(height: 14),
                    if (_release == null)
                      _upToDateCard()
                    else
                      _releaseCard(_release!),
                    const SizedBox(height: 14),
                    _howUpdatesWorkCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _gold, size: 42),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _checkForUpdate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentVersionCard() {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: _blue, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installed version',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentVersion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _platform.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upToDateCard() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _green),
              SizedBox(width: 10),
              Text(
                'You are up to date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'We checked for a newer release for this device. There is no update available right now.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _releaseCard(AppReleaseModel release) {
    final uri = Uri.tryParse(release.downloadUrl);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update_alt_rounded, color: _green),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'UPDATE AVAILABLE',
                  style: TextStyle(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              Text(
                'Build ${release.buildNumber}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            release.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Version ${release.versionName} • ${release.platform.toUpperCase()}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          _sectionLabel('PURPOSE'),
          const SizedBox(height: 6),
          Text(
            release.purpose,
            style: const TextStyle(color: Colors.white, height: 1.5),
          ),
          if (release.changes.isNotEmpty) ...[
            const SizedBox(height: 18),
            _sectionLabel('WHAT WILL CHANGE'),
            const SizedBox(height: 8),
            ...release.changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle, color: _blue, size: 6),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        change,
                        style: const TextStyle(color: _muted, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _sectionLabel('HOW TO INSTALL'),
          const SizedBox(height: 6),
          Text(
            release.instructions,
            style: const TextStyle(color: _muted, height: 1.5),
          ),
          if (uri != null && uri.host.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Download source: ${uri.host}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openingLink ? null : _startDownload,
              icon: _openingLink
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                _openingLink
                    ? 'Opening download…'
                    : 'Review details, then download',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'The download opens outside the app. Review the version and source above before continuing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 6),
          const Text(
            'This page explains the release; it does not scan the downloaded installer.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _howUpdatesWorkCard() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why update?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Updates can add features, fix problems, and improve security. This page checks the published release information for your device and shows its purpose and installation steps before you choose to download.',
            style: TextStyle(color: _muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: _blue,
      fontSize: 12,
      fontWeight: FontWeight.w900,
      letterSpacing: .8,
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: child,
  );
}
