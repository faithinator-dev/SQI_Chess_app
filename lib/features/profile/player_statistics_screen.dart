import 'package:flutter/material.dart';

import '../../core/models/profile_model.dart';
import '../../core/repositories/profile_repository.dart';

class PlayerStatisticsScreen extends StatefulWidget {
  const PlayerStatisticsScreen({super.key});

  @override
  State<PlayerStatisticsScreen> createState() => _PlayerStatisticsScreenState();
}

class _PlayerStatisticsScreenState extends State<PlayerStatisticsScreen> {
  final ProfileRepository _repository = ProfileRepository();
  ProfileModel? _profile;
  bool _loading = true;
  String? _error;

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
      final profile = await _repository.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        if (profile == null) _error = 'Your statistics are not available yet.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'We could not load your statistics.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8F6),
        foregroundColor: Colors.white,
        title: const Text(
          'Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _StateMessage(message: _error!, onRetry: _load)
            : _content(_profile!),
      ),
    );
  }

  Widget _content(ProfileModel profile) {
    final total = profile.gamesPlayed;
    final winRate = total == 0 ? 0 : profile.wins / total * 100;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _panel(
            child: Row(
              children: [
                const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFFF5C451),
                  size: 36,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Current rating',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFF737A74),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${profile.chessRating}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.3,
            children: [
              _stat('${profile.gamesPlayed}', 'Games played'),
              _stat('${profile.wins}', 'Wins'),
              _stat('${profile.losses}', 'Losses'),
              _stat('${profile.draws}', 'Draws'),
              _stat('${winRate.toStringAsFixed(0)}%', 'Win percentage'),
              _stat('${profile.currentStreak}', 'Current streak'),
            ],
          ),
          const SizedBox(height: 18),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rating history',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  total == 0
                      ? 'Rating history will appear after your first rated game.'
                      : 'Historical rating points are not available in the current Supabase schema.',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF737A74),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Results breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _resultBar(
                  'Wins',
                  profile.wins,
                  total,
                  const Color(0xFF557B63),
                ),
                _resultBar(
                  'Losses',
                  profile.losses,
                  total,
                  const Color(0xFFFF5C70),
                ),
                _resultBar(
                  'Draws',
                  profile.draws,
                  total,
                  const Color(0xFFF5C451),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
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

  Widget _resultBar(String label, int value, int total, Color color) {
    final ratio = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 20, color: Color(0xFF737A74)),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDE9E2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: child,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 20, color: Color(0xFF737A74)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
