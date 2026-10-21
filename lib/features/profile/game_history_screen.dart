import 'package:flutter/material.dart';

import '../archive/game_review_screen.dart';
import '../../core/repositories/chess_game_repository.dart';

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  final ChessGameRepository _repository = ChessGameRepository();
  String _filter = 'All';
  bool _loading = true;
  String? _error;
  List<GameHistoryEntry> _games = const [];

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
      final games = await _repository.getCurrentHistory();
      if (!mounted) return;
      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'We could not load your game history.';
      });
    }
  }

  List<GameHistoryEntry> get _filteredGames {
    if (_filter == 'All') return _games;
    return _games.where((entry) => entry.result == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        foregroundColor: const Color(0xFF17382B),
        title: const Text(
          'Game History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _StateMessage(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _summary(),
                    const SizedBox(height: 18),
                    _filters(),
                    const SizedBox(height: 16),
                    if (_filteredGames.isEmpty)
                      const _StateMessage(
                        message: 'Completed games will appear here.',
                      )
                    else
                      ..._filteredGames.map(_gameCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summary() {
    final wins = _games.where((game) => game.result == 'Victory').length;
    final losses = _games.where((game) => game.result == 'Defeat').length;
    final draws = _games.where((game) => game.result == 'Draw').length;
    return _panel(
      child: Row(
        children: [
          _summaryItem('${_games.length}', 'Games'),
          _summaryItem('$wins', 'Wins'),
          _summaryItem('$losses', 'Losses'),
          _summaryItem('$draws', 'Draws'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF17382B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 20, color: Color(0xFF737A74)),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Victory', 'Defeat', 'Draw'].map((filter) {
          final selected = filter == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) => setState(() => _filter = filter),
              selectedColor: const Color(0xFF2D4A3E),
              backgroundColor: const Color(0xFFFFFFFF),
              labelStyle: TextStyle(
                fontSize: 20,
                color: selected ? Colors.white : const Color(0xFF737A74),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _gameCard(GameHistoryEntry entry) {
    final color = switch (entry.result) {
      'Victory' => const Color(0xFF557B63),
      'Defeat' => const Color(0xFFFF5C70),
      _ => const Color(0xFFF5C451),
    };
    final opponent = entry.opponent;
    final date = entry.game.endedAt ?? entry.game.createdAt;
    final dateText = date == null ? 'Date unavailable' : _formatDate(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openReview(entry),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2D4A3E),
                child: Text(
                  opponent?.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opponent?.fullName ?? 'Opponent unavailable',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF17382B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.game.timeControl} | $dateText',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF737A74),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                entry.result,
                style: TextStyle(
                  fontSize: 20,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReview(GameHistoryEntry entry) async {
    try {
      final moves = await _repository.getMoves(entry.game.id);
      if (!mounted) return;
      final opponentName = entry.opponent?.fullName ?? 'Opponent';
      final whiteName = entry.isWhite ? 'You' : opponentName;
      final blackName = entry.isWhite ? opponentName : 'You';
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GameReviewScreen(
            matchId: entry.game.id,
            timeControl: entry.game.timeControl,
            result: entry.result,
            opponentName: opponentName,
            whitePlayerName: whiteName,
            blackPlayerName: blackName,
            winnerSide: entry.game.result,
            moves: moves.map((move) => move.san).toList(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not load this game's move history."),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF17382B).withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: Color(0xFF737A74)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
