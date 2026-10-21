import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'match_found_screen.dart';
import 'matchmaking_repository.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color green = Color(0xFF557B63);
  static const Color danger = Color(0xFFFF5C70);
  static const Color muted = Color(0xFF737A74);

  final MatchmakingRepository _repository = MatchmakingRepository();

  Timer? _countdownTimer;
  Timer? _pollTimer;
  RealtimeChannel? _queueChannel;

  int _secondsSearching = 0;
  bool _searching = true;
  bool _loading = true;
  bool _navigating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    try {
      final existingGameId = await _repository.getMatchedGameId();

      if (existingGameId != null && existingGameId.isNotEmpty) {
        await _handleMatchedGame(existingGameId);
        return;
      }

      final entry = await _repository.joinQuickMatch();

      if (!mounted || !_searching) {
        return;
      }

      setState(() {
        _loading = false;
      });

      if (entry.status == 'matched' &&
          entry.matchedGameId != null &&
          entry.matchedGameId!.isNotEmpty) {
        await _handleMatchedGame(entry.matchedGameId!);
        return;
      }

      _startSearchTimers();
      _subscribeToQueue();
      await _checkForMatch();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _searching = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  void _startSearchTimers() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_searching) {
        return;
      }

      setState(() {
        _secondsSearching++;
      });
    });

    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_searching || _navigating) {
        return;
      }

      unawaited(_checkForMatch());
    });
  }

  void _subscribeToQueue() {
    _queueChannel?.unsubscribe();

    _queueChannel = _repository.watchQueue(
      onChanged: () {
        if (!_searching || _navigating) {
          return;
        }

        unawaited(_checkForMatch());
      },
    );
  }

  Future<void> _checkForMatch() async {
    if (!_searching || _navigating) {
      return;
    }

    try {
      final gameId = await _repository.getMatchedGameId();

      if (!mounted || !_searching || _navigating) {
        return;
      }

      if (gameId == null || gameId.isEmpty) {
        return;
      }

      await _handleMatchedGame(gameId);
    } catch (_) {
      // Polling and realtime will retry.
    }
  }

  Future<void> _handleMatchedGame(String gameId) async {
    if (_navigating || gameId.isEmpty) {
      return;
    }

    _navigating = true;

    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    final channel = _queueChannel;
    _queueChannel = null;

    if (channel != null) {
      try {
        await _repository.removeChannel(channel);
      } catch (_) {
        // Channel cleanup is best effort.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _loading = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => MatchFoundScreen(gameId: gameId)),
    );
  }

  Future<void> _cancelSearch() async {
    if (!_searching) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _searching = false;

    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    final channel = _queueChannel;
    _queueChannel = null;

    if (channel != null) {
      try {
        await _repository.removeChannel(channel);
      } catch (_) {
        // Channel cleanup is best effort.
      }
    }

    try {
      await _repository.leaveQueue();
    } catch (_) {
      // Queue cleanup is best effort.
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('You must be signed in')) {
      return 'Please sign in before entering Quick Match.';
    }

    if (message.contains('join_matchmaking')) {
      return 'Matchmaking is temporarily unavailable.';
    }

    return 'We could not start Quick Match. Please try again.';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    final channel = _queueChannel;
    _queueChannel = null;

    if (channel != null) {
      unawaited(_repository.removeChannel(channel));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 18 : 28,
                  vertical: compact ? 18 : 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _buildContent(compact),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(compact),
        const SizedBox(height: 22),
        _buildMainCard(compact),
        const SizedBox(height: 16),
        _buildMatchInfo(),
        const SizedBox(height: 18),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildHeader(bool compact) {
    final title = const Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Match',
            style: TextStyle(
              fontSize: 20,
              color: primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Finding your next opponent',
            style: TextStyle(fontSize: 20, color: muted),
          ),
        ],
      ),
    );
    final badge = _statusBadge(
      _searching ? 'SEARCHING' : 'READY',
      _searching ? blue : green,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _iconButton(Icons.arrow_back_rounded, _cancelSearch),
              const SizedBox(width: 14),
              title,
            ],
          ),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: badge),
        ],
      );
    }

    return Row(
      children: [
        _iconButton(Icons.arrow_back_rounded, _cancelSearch),
        const SizedBox(width: 14),
        title,
        badge,
      ],
    );
  }

  Widget _buildMainCard(bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: blue.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchIcon(),
          const SizedBox(height: 25),
          Text(
            _errorMessage != null
                ? 'Matchmaking unavailable'
                : _loading
                ? 'Joining the queue'
                : 'Finding an opponent',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _errorMessage ??
                'SQI is searching for a player with a suitable rating.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          if (_errorMessage == null) ...[
            _buildTimer(),
            const SizedBox(height: 25),
            _buildProgress(),
          ] else
            _buildErrorState(),
        ],
      ),
    );
  }

  Widget _buildSearchIcon() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: blue.withValues(alpha: 0.08),
        border: Border.all(color: blue.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2D4A3E), Color(0xFF1749B8)],
            ),
            boxShadow: [
              BoxShadow(color: blue.withValues(alpha: 0.25), blurRadius: 24),
            ],
          ),
          child: const Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 31,
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = (_secondsSearching ~/ 60).toString().padLeft(2, '0');

    final seconds = (_secondsSearching % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
            fontSize: 20,
            color: primaryText,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'SEARCH TIME',
          style: TextStyle(
            fontSize: 20,
            color: muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const LinearProgressIndicator(
            minHeight: 6,
            backgroundColor: surface2,
            valueColor: AlwaysStoppedAnimation<Color>(blue),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sync_rounded, color: blue, size: 16),
            SizedBox(width: 7),
            Text(
              'Searching the live player pool',
              style: TextStyle(fontSize: 20, color: muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: danger.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: danger, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 20,
                color: primaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _infoItem(Icons.timer_outlined, '10:00', 'START TIME'),
          ),
          Container(width: 1, height: 38, color: surface2),
          Expanded(child: _infoItem(Icons.bolt_rounded, '+0', 'INCREMENT')),
          Container(width: 1, height: 38, color: surface2),
          Expanded(child: _infoItem(Icons.groups_outlined, 'LIVE', 'POOL')),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: blue, size: 18),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            color: muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _loading && _errorMessage == null ? null : _cancelSearch,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          side: const BorderSide(color: surface2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _errorMessage == null ? 'Cancel Search' : 'Go Back',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: primaryText, size: 20),
        ),
      ),
    );
  }
}
