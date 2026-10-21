import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentAdminScreen extends StatefulWidget {
  const TournamentAdminScreen({super.key});

  @override
  State<TournamentAdminScreen> createState() => _TournamentAdminScreenState();
}

class _TournamentAdminScreenState extends State<TournamentAdminScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _competitions = const [];

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
      final rows = await Supabase.instance.client
          .from('competitions')
          .select('id,title,status,format,time_control,starts_at')
          .neq('status', 'draft')
          .order('starts_at', ascending: true)
          .limit(100);
      if (!mounted) return;
      setState(() {
        _competitions = rows
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Tournament records could not be loaded. Check your administrator access and retry.';
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
          'Tournament administration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh tournaments',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'COMPETITIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tournament overview',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Review competitions currently visible to your administrator account.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                color: colors.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.error_outline,
                    color: colors.onErrorContainer,
                  ),
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
            else if (_competitions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No published competitions are available. Draft competitions are private and are not included in the current admin database policy.',
                  ),
                ),
              )
            else
              for (final competition in _competitions)
                _competitionCard(context, competition),
            const SizedBox(height: 12),
            Card(
              color: colors.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tournament creation, pairing overrides, and bracket controls need administrator write policies and server-side validation. They are not enabled in the current database schema.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _competitionCard(BuildContext context, Map<String, dynamic> row) {
    final startsAt = DateTime.tryParse(
      row['starts_at']?.toString() ?? '',
    )?.toLocal();
    final startLabel = startsAt == null
        ? 'Start date not set'
        : '${startsAt.day}/${startsAt.month}/${startsAt.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.emoji_events_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          row['title']?.toString() ?? 'Competition',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${row['status']} · ${row['format']} · ${row['time_control']}\n$startLabel',
        ),
        isThreeLine: true,
      ),
    );
  }
}
