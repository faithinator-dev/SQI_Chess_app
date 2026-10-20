import 'package:flutter/material.dart';
import 'package:sqi_chess_club/features/admin/community_admin_screen.dart';
import 'package:sqi_chess_club/features/admin/player_management_screen.dart';

import '../../core/repositories/admin_repository.dart';
import 'analytics_dashboard_screen.dart';
import 'tournament_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
            'We could not load the admin overview. Check your access and connection, then retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final destinations = <_AdminDestination>[
      _AdminDestination(
        'Players',
        'Search accounts and manage administrator access.',
        Icons.people_alt_outlined,
        const PlayerManagementScreen(),
      ),
      _AdminDestination(
        'Community',
        'Publish official updates to the club feed.',
        Icons.campaign_outlined,
        const CommunityAdminScreen(),
      ),
      _AdminDestination(
        'Analytics',
        'Review current players, games, and published competitions.',
        Icons.query_stats_rounded,
        const AnalyticsDashboardScreen(),
      ),
      _AdminDestination(
        'Tournaments',
        'Review published competitions and tournament availability.',
        Icons.emoji_events_outlined,
        const TournamentAdminScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin center',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh overview',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'CHECKMATE ADMINISTRATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Club overview',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage the club from one place. Counts below come directly from the current platform data.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                color: color.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: color.onErrorContainer,
                  ),
                  title: Text(
                    _error!,
                    style: TextStyle(color: color.onErrorContainer),
                  ),
                  trailing: TextButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 800 ? 4 : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatCard(
                        width: width,
                        icon: Icons.people_alt_outlined,
                        title: 'Players',
                        value: '${_stats['players'] ?? 0}',
                        color: color.primary,
                      ),
                      _StatCard(
                        width: width,
                        icon: Icons.sports_esports_outlined,
                        title: 'Visible games',
                        value: '${_stats['games'] ?? 0}',
                        color: color.tertiary,
                      ),
                      _StatCard(
                        width: width,
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Active games',
                        value: '${_stats['active_games'] ?? 0}',
                        color: color.secondary,
                      ),
                      _StatCard(
                        width: width,
                        icon: Icons.emoji_events_outlined,
                        title: 'Published competitions',
                        value: '${_stats['competitions'] ?? 0}',
                        color: color.primary,
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 28),
            Text(
              'Administration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final destination in destinations)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.primaryContainer,
                    foregroundColor: color.primary,
                    child: Icon(destination.icon),
                  ),
                  title: Text(
                    destination.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(destination.description),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => destination.screen)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination(this.title, this.description, this.icon, this.screen);
  final String title;
  final String description;
  final IconData icon;
  final Widget screen;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final double width;
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
