import 'package:flutter/material.dart';

import 'spectator_chess_board.dart';
import 'spectator_replay_screen.dart';

class SpectatorMatchScreen extends StatelessWidget {
  final Map<String, dynamic> game;

  const SpectatorMatchScreen({super.key, required this.game});

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);

  static const String demoFen =
      'r1bqk2r/pppp1ppp/2n2n2/4p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1';

  @override
  Widget build(BuildContext context) {
    final whitePlayer = game['white']?.toString() ?? 'Faith Toluwanimi';

    final blackPlayer = game['black']?.toString() ?? 'Daniel Ade';

    final whiteRating = game['whiteRating']?.toString() ?? '1284';

    final blackRating = game['blackRating']?.toString() ?? '1301';

    final matchId = game['id']?.toString() ?? '#SQA-28491';

    final timeControl = game['timeControl']?.toString() ?? '10+5';

    final spectators = game['spectators']?.toString() ?? '128';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.visibility_rounded, color: green, size: 20),
            SizedBox(width: 10),
            Text('Live Match', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: green,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1000;

            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 28 : 16),
              child: desktop
                  ? _desktopLayout(
                      context,
                      whitePlayer,
                      blackPlayer,
                      whiteRating,
                      blackRating,
                      matchId,
                      timeControl,
                      spectators,
                    )
                  : _mobileLayout(
                      context,
                      whitePlayer,
                      blackPlayer,
                      whiteRating,
                      blackRating,
                      matchId,
                      timeControl,
                      spectators,
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _desktopLayout(
    BuildContext context,
    String whitePlayer,
    String blackPlayer,
    String whiteRating,
    String blackRating,
    String matchId,
    String timeControl,
    String spectators,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1350),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _boardSection(
                whitePlayer,
                blackPlayer,
                whiteRating,
                blackRating,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: _sidePanel(
                context,
                matchId,
                timeControl,
                spectators,
                whitePlayer,
                blackPlayer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    String whitePlayer,
    String blackPlayer,
    String whiteRating,
    String blackRating,
    String matchId,
    String timeControl,
    String spectators,
  ) {
    return Column(
      children: [
        _boardSection(whitePlayer, blackPlayer, whiteRating, blackRating),
        const SizedBox(height: 20),
        _sidePanel(
          context,
          matchId,
          timeControl,
          spectators,
          whitePlayer,
          blackPlayer,
        ),
      ],
    );
  }

  Widget _boardSection(
    String whitePlayer,
    String blackPlayer,
    String whiteRating,
    String blackRating,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _playerBar(
            name: blackPlayer,
            rating: blackRating,
            piece: 'â™š',
            active: false,
          ),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: const SpectatorChessBoard(
                fen: demoFen,
                showCoordinates: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _playerBar(
            name: whitePlayer,
            rating: whiteRating,
            piece: 'â™”',
            active: true,
          ),
        ],
      ),
    );
  }

  Widget _playerBar({
    required String name,
    required String rating,
    required String piece,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? blue.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(piece, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rating $rating',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'WHITE',
                style: TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'BLACK',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidePanel(
    BuildContext context,
    String matchId,
    String timeControl,
    String spectators,
    String whitePlayer,
    String blackPlayer,
  ) {
    return Column(
      children: [
        _infoCard(
          title: 'MATCH INFORMATION',
          child: Column(
            children: [
              _infoRow(Icons.tag_rounded, 'Match ID', matchId),
              _infoRow(Icons.timer_outlined, 'Time Control', timeControl),
              _infoRow(Icons.visibility_outlined, 'Spectators', spectators),
              _infoRow(Icons.circle, 'Status', 'Live', valueColor: green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          title: 'RECENT MOVES',
          child: Column(
            children: [
              _moveRow('1.', 'e4', 'e5'),
              _moveRow('2.', 'Nf3', 'Nc6'),
              _moveRow('3.', 'Bc4', 'Nf6'),
              _moveRow('4.', 'O-O', 'Be7'),
              _moveRow('5.', 'Re1', 'd6'),
              _moveRow('6.', 'c3', 'O-O'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          title: 'PLAYERS',
          child: Column(
            children: [
              _simplePlayer(whitePlayer, 'White', blue),
              const SizedBox(height: 10),
              _simplePlayer(blackPlayer, 'Black', Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpectatorReplayScreen(game: game),
                ),
              );
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Review Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveRow(String number, String white, String black) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              white,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              black,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simplePlayer(String name, String side, Color accent) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: accent.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(color: accent, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Text(side, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}
