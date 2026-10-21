import 'package:flutter/material.dart';

import '../../core/models/profile_model.dart';
import '../../core/repositories/chess_game_repository.dart';
import '../../core/repositories/profile_repository.dart';
import '../profile/game_history_screen.dart';
import '../match/chess_match_screen.dart';
import '../match/local_pvp_screen.dart';
import '../match/match_config.dart';
import '../match/match_mode.dart';
import 'matchmaking_screen.dart';
import 'matches_screen.dart' show LanLobbyScreen;
import '../../practice/practice_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ChessGameRepository _games = ChessGameRepository();
  final ProfileRepository _profiles = ProfileRepository();
  ProfileModel? _profile;
  List<ActiveGameEntry> _activeGames = [];
  List<GameHistoryEntry> _history = [];
  bool _loading = true;
  String? _error;
  String _selectedMode = 'Quick Match';

  static const _modes = [
    ('Quick Match', Icons.bolt_rounded),
    ('Play Computer', Icons.computer_rounded),
    ('Local PvP', Icons.people_alt_outlined),
    ('Wi-Fi', Icons.wifi_rounded),
  ];

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
      final profile = await _profiles.getCurrentProfile();
      final active = await _games.getCurrentActiveGames();
      final history = await _games.getCurrentHistory();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _activeGames = active;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'We could not load your game activity. Check your connection and retry.';
      });
    }
  }

  void _startMode() {
    final Widget screen = switch (_selectedMode) {
      'Play Computer' => const PracticeScreen(),
      'Local PvP' => LocalPvpScreen(
        config: MatchConfig(
          mode: MatchMode.local,
          initialTimeSeconds: 600,
          incrementSeconds: 0,
          whitePlayerName: 'Player 1',
          blackPlayerName: 'Player 2',
        ),
      ),
      'Wi-Fi' => const LanLobbyScreen(),
      _ => const MatchmakingScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'The Arena',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLAY & CHALLENGE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Choose your game',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'Georgia',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_profile != null)
                  Chip(
                    avatar: Icon(Icons.circle, size: 9, color: colors.primary),
                    label: Text('${_profile!.chessRating} ELO'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a format, find an opponent, or continue a game.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _modes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final mode = _modes[index];
                  final selected = _selectedMode == mode.$1;
                  return ChoiceChip(
                    avatar: Icon(
                      mode.$2,
                      size: 17,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                    label: Text(mode.$1),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedMode = mode.$1),
                    selectedColor: colors.primary,
                    labelStyle: TextStyle(
                      fontSize: 20,
                      color: selected ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _quickStartCard(context),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Active matches', '${_activeGames.length}'),
            const SizedBox(height: 10),
            if (_loading && _activeGames.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                color: colors.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.cloud_off_outlined,
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
            else if (_error == null && _activeGames.isEmpty)
              _emptyPanel(
                context,
                Icons.sports_esports_outlined,
                'No active matches',
                'Your unfinished games will appear here.',
              )
            else
              for (final active in _activeGames.take(5))
                _activeGameCard(context, active),
            const SizedBox(height: 24),
            _sectionHeader(context, 'Match archive', 'Last 10 duels'),
            const SizedBox(height: 10),
            if (!_loading && _error == null && _history.isEmpty)
              _emptyPanel(
                context,
                Icons.history_rounded,
                'No completed games yet',
                'Your game results will appear here after your first match.',
              )
            else
              for (final entry in _history.take(10))
                _historyCard(context, entry),
            if (_history.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GameHistoryScreen(),
                    ),
                  ),
                  child: const Text('View full archive'),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              color: colors.surfaceContainerHighest.withValues(alpha: .55),
              child: const ListTile(
                leading: Icon(Icons.lightbulb_outline_rounded),
                title: Text('Play your way'),
                subtitle: Text(
                  'Quick Match is online. Play Computer, Local PvP and Wi-Fi games are also available.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickStartCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final quick = _selectedMode == 'Quick Match';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _modes.firstWhere((mode) => mode.$1 == _selectedMode).$2,
                    color: colors.primary,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    quick ? 'ONLINE MATCH' : _selectedMode.toUpperCase(),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              quick ? 'Quick Match' : _selectedMode,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(switch (_selectedMode) {
              'Play Computer' =>
                'Practice a game against the computer, whenever you want.',
              'Local PvP' =>
                'Share one device and play from opposite sides of the board.',
              'Wi-Fi' => 'Find and join a chess game on your local network.',
              _ => 'Find an online opponent for a ten-minute game.',
            }, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 17),
            if (quick)
              Row(
                children: [
                  Expanded(
                    child: _fact(
                      context,
                      Icons.timer_outlined,
                      '10 min',
                      'Time control',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _fact(
                      context,
                      Icons.bolt_outlined,
                      '+0',
                      'Increment',
                    ),
                  ),
                ],
              ),
            if (quick) const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _startMode,
                icon: Icon(
                  quick
                      ? Icons.play_arrow_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  quick
                      ? 'Find Match'
                      : 'Start ${_selectedMode == 'Wi-Fi' ? 'Wi-Fi game' : _selectedMode}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fact(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(BuildContext context, String title, String detail) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _activeGameCard(BuildContext context, ActiveGameEntry entry) {
    final isMyTurn =
        (entry.game.currentTurn == 'white' && entry.isWhite) ||
        (entry.game.currentTurn == 'black' && !entry.isWhite);
    final opponent = entry.opponent?.fullName ?? 'Opponent';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  child: Text(
                    opponent.isEmpty ? 'O' : opponent[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opponent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${entry.opponent?.chessRating ?? 1000} ELO  �  ${entry.isWhite ? 'White' : 'Black'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(isMyTurn ? 'Your turn' : 'Opponent turn'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry.game.timeControl}  �  ${isMyTurn ? 'Make your move' : 'Waiting for opponent'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChessMatchScreen(gameId: entry.game.id),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context, GameHistoryEntry entry) {
    final won = entry.result == 'Victory';
    final color = entry.result == 'Draw'
        ? Colors.orange
        : won
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        title: Text(
          entry.opponent?.fullName ?? 'Opponent',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${entry.result}  �  ${entry.game.timeControl}'),
        trailing: Text(
          entry.result,
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyPanel(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
