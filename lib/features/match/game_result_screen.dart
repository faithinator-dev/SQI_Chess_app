import 'package:flutter/material.dart';

class GameResultScreen extends StatelessWidget {
  const GameResultScreen({
    super.key,
    this.result = 'Victory',
    this.opponentName = 'Professor Knight',
    this.opponentRating = '1200',
    this.matchId = 'SQI-28491',
    this.timeControl = '10+5',
    this.moveCount = 0,
  });

  final String result;
  final String opponentName;
  final String opponentRating;
  final String matchId;
  final String timeControl;
  final int moveCount;

  static const Color background = Color(0xFFF9F8F6);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color blue = Color(0xFF2D4A3E);

  static const Color muted = Color(0xFF737A74);

  static const Color green = Color(0xFF557B63);

  static const Color gold = Color(0xFFF5C451);

  static const Color danger = Color(0xFFFF5C70);

  bool get isVictory => result.toLowerCase() == 'victory';

  bool get isDraw => result.toLowerCase() == 'draw';

  Color get resultColor {
    if (isVictory) return green;
    if (isDraw) return gold;
    return danger;
  }

  IconData get resultIcon {
    if (isVictory) {
      return Icons.emoji_events_rounded;
    }

    if (isDraw) {
      return Icons.handshake_rounded;
    }

    return Icons.flag_rounded;
  }

  String get resultDescription {
    if (isVictory) {
      return 'You defeated $opponentName.';
    }

    if (isDraw) {
      return 'The game ended in a draw.';
    }

    return 'The game ended with a resignation or timeout.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 850;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: desktop
                      ? _buildDesktop(context)
                      : _buildMobile(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),
        _buildResultHero(),
        const SizedBox(height: 20),
        _buildPlayersCard(),
        const SizedBox(height: 16),
        _buildStatsCard(),
        const SizedBox(height: 16),
        _buildMatchDetails(),
        const SizedBox(height: 24),
        _buildActions(context),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        const SizedBox(height: 42),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildResultHero(),
                  const SizedBox(height: 20),
                  _buildPlayersCard(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildMatchDetails(),
                  const SizedBox(height: 20),
                  _buildActions(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'GAME RESULT',
          style: TextStyle(
            fontSize: 20,
            color: muted,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildResultHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: resultColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: resultColor.withValues(alpha: 0.12),
              border: Border.all(
                color: resultColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(resultIcon, color: resultColor, size: 34),
          ),

          const SizedBox(height: 20),

          Text(
            result.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: resultColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            resultDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'FINAL RESULT',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _player(
                  name: 'You',
                  rating: 'Player',
                  score: isVictory
                      ? '1'
                      : isDraw
                      ? '0.5'
                      : '0',
                  isYou: true,
                  highlighted: isVictory,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    color: muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Expanded(
                child: _player(
                  name: opponentName,
                  rating: opponentRating,
                  score: isVictory
                      ? '0'
                      : isDraw
                      ? '0.5'
                      : '1',
                  highlighted: !isVictory && !isDraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _player({
    required String name,
    required String rating,
    required String score,
    bool isYou = false,
    bool highlighted = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlighted
                ? blue.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? blue.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            if (isYou) ...[
              const SizedBox(width: 5),
              const Text(
                'YOU',
                style: TextStyle(
                  fontSize: 20,
                  color: blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 3),

        Text(
          'Rating $rating',
          style: const TextStyle(fontSize: 20, color: muted),
        ),

        const SizedBox(height: 10),

        Text(
          score,
          style: TextStyle(
            fontSize: 20,
            color: highlighted ? resultColor : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GAME SUMMARY',
            style: TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _stat('MOVES', '$moveCount', Icons.swap_vert_rounded),
              ),
              Expanded(child: _stat('TIME', timeControl, Icons.timer_outlined)),
              Expanded(child: _stat('MODE', 'DEMO', Icons.bolt_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: blue, size: 17),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            color: muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'MATCH DETAILS',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 15),

          _detail('Match ID', matchId),
          _detail('Time Control', timeControl),
          _detail('Opponent', opponentName),
          _detail('Mode', 'Play Computer'),
          _detail('Status', 'Completed'),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 20, color: muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.sports_esports_rounded, size: 18),
            label: const Text('Play Another Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Back to Matches'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
