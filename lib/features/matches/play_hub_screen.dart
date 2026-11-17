import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/widgets/arena_components.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/chess_game_repository.dart';
import '../../core/repositories/profile_repository.dart';
import '../profile/game_history_screen.dart';
import '../match/chess_match_screen.dart';
import '../match/local_pvp_screen.dart';
import '../match/match_config.dart';
import '../match/match_mode.dart';
import 'matchmaking_screen.dart';
import 'friend_game_screen.dart';
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
    ('Play with Friend', Icons.people_alt_outlined),
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
      'Play with Friend' => const FriendGameScreen(),
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
    return Scaffold(
      appBar: const AppTopBar(title: 'Play', subtitle: 'Choose a game mode'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (_profile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_profile!.chessRating} rating',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ..._modes.map((mode) => _modeCard(context, mode)),
            const SizedBox(height: 26),
            _sectionHeader(context, 'Active games', '${_activeGames.length}'),
            const SizedBox(height: 10),
            if (_loading && _activeGames.isEmpty)
              const PremiumCard(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: LoadingState(message: 'Loading active games...'),
              )
            else if (_error != null)
              ErrorState(message: _error!, onRetry: _load)
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
            _sectionHeader(context, 'Recent games', 'Last 10'),
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
          ],
        ),
      ),
    );
  }

  Widget _modeCard(BuildContext context, (String, IconData) mode) {
    final selected = _selectedMode == mode.$1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        onTap: () {
          setState(() => _selectedMode = mode.$1);
          _startMode();
        },
        child: ListTile(
          minVerticalPadding: 14,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (selected ? AppTheme.gold : AppTheme.blue).withValues(
                alpha: .13,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              mode.$2,
              color: selected ? AppTheme.gold : AppTheme.blue,
              size: 22,
            ),
          ),
          title: Text(
            mode.$1,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _modeDescription(mode.$1),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  String _modeDescription(String mode) => switch (mode) {
    'Quick Match' => 'Find an opponent instantly',
    'Play with Friend' => 'Invite a friend to a game',
    'Play Computer' => 'Challenge the AI',
    'Local PvP' => 'Play on this device',
    'Wi-Fi' => 'Play with nearby devices',
    _ => 'Choose this game mode',
  };

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
                  fontSize: 16,
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
                fontWeight: FontWeight.w700,
                fontSize: 17,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${entry.opponent?.chessRating ?? 1000} ELO  •  ${entry.isWhite ? 'White' : 'Black'}',
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
                    '${entry.game.timeControl}  •  ${isMyTurn ? 'Make your move' : 'Waiting for opponent'}',
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
        subtitle: Text('${entry.result}  •  ${entry.game.timeControl}'),
        trailing: Text(
          entry.result,
          style: TextStyle(
            fontSize: 13,
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
                    fontSize: 14,
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
