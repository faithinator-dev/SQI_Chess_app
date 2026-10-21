import 'package:flutter/material.dart';

import '../../core/repositories/admin_repository.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _repository = AdminRepository();
  bool _loading = true;
  String? _error;
  Map<String, int> _stats = const {};

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
      final stats = await _repository.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Analytics are unavailable. Check administrator access and retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Platform analytics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh analytics',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'PLATFORM ACTIVITY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analytics',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current totals available from the connected database.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                color: colors.errorContainer,
                child: ListTile(
                  title: Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 20,
                      color: colors.onErrorContainer,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ),
              )
            else ...[
              _metric(
                context,
                'Registered profiles',
                _stats['players'] ?? 0,
                Icons.people_alt_outlined,
              ),
              _metric(
                context,
                'Games visible to this admin account',
                _stats['games'] ?? 0,
                Icons.sports_esports_outlined,
              ),
              _metric(
                context,
                'Active games visible to this admin account',
                _stats['active_games'] ?? 0,
                Icons.play_circle_outline_rounded,
              ),
              _metric(
                context,
                'Published competitions',
                _stats['competitions'] ?? 0,
                Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 12),
              Card(
                color: colors.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'DAU/MAU, retention funnels, and game mode ratios are not available because this project has no analytics aggregation pipeline. Game totals follow the database account’s row access policies.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(label),
      trailing: Text(
        '$value',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
