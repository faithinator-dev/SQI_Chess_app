import 'package:flutter/material.dart';

import 'spectator_match_screen.dart';

class SpectatorScreen extends StatelessWidget {
  const SpectatorScreen({super.key});

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);

  final List<Map<String, dynamic>> games = const [
    {
      'white': 'Daniel Ade',
      'black': 'Samuel K',
      'whiteRating': '1,301',
      'blackRating': '1,272',
      'status': 'LIVE',
      'moves': 34,
      'spectators': 128,
      'time': '10+5',
    },
    {
      'white': 'Michael T',
      'black': 'Emmanuel A',
      'whiteRating': '1,290',
      'blackRating': '1,318',
      'status': 'LIVE',
      'moves': 27,
      'spectators': 94,
      'time': '15+10',
    },
    {
      'white': 'Joshua B',
      'black': 'David O',
      'whiteRating': '1,334',
      'blackRating': '1,258',
      'status': 'LIVE',
      'moves': 19,
      'spectators': 67,
      'time': '10+5',
    },
    {
      'white': 'Peter C',
      'black': 'Tobi F',
      'whiteRating': '1,281',
      'blackRating': '1,298',
      'status': 'LIVE',
      'moves': 42,
      'spectators': 51,
      'time': '5+3',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 40 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 26),
                      _buildHero(desktop),
                      const SizedBox(height: 24),
                      _buildStats(),
                      const SizedBox(height: 28),
                      _buildSectionHeader(),
                      const SizedBox(height: 16),
                      _buildGames(context, desktop),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPECTATOR',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Watch Live Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        _iconButton(Icons.search_rounded, () {
          _showSearch(context);
        }),
      ],
    );
  }

  static Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildHero(bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 30 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172F6B), Color(0xFF101B32), Color(0xFF0D1424)],
        ),
        border: Border.all(color: blue.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: desktop ? 64 : 56,
            height: desktop ? 64 : 56,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.visibility_rounded, color: blue, size: 30),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WATCH THE ARENA',
                  style: TextStyle(
                    color: blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Follow the best games live.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Watch every move without entering the match.',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _stat(Icons.live_tv_rounded, '12', 'Live Games', green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _stat(Icons.visibility_rounded, '340', 'Spectators', blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _stat(Icons.emoji_events_rounded, '128', 'Players', gold),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Choose a game to spectate',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          'LIVE NOW',
          style: TextStyle(
            color: green,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGames(BuildContext context, bool desktop) {
    if (desktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: games.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (context, index) {
          return _gameCard(context, games[index]);
        },
      );
    }

    return Column(
      children: games
          .map(
            (game) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _gameCard(context, game),
            ),
          )
          .toList(),
    );
  }

  Widget _gameCard(BuildContext context, Map<String, dynamic> game) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpectatorMatchScreen(game: game)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  _liveBadge(),
                  const Spacer(),
                  const Icon(Icons.visibility_rounded, color: muted, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    '${game['spectators']}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _playerRow(
                game['white'] as String,
                game['whiteRating'] as String,
                true,
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _playerRow(
                game['black'] as String,
                game['blackRating'] as String,
                false,
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  _miniInfo(Icons.timer_outlined, game['time'] as String),
                  const SizedBox(width: 14),
                  _miniInfo(Icons.numbers_rounded, 'Move ${game['moves']}'),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: blue,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: green, size: 6),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerRow(String name, String rating, bool white) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.35),
            border: Border.all(
              color: white
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            color: white ? Colors.white : muted,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          rating,
          style: const TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: muted, size: 13),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Find a Match',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: const TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter match ID',
              hintStyle: TextStyle(color: muted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Search',
                style: TextStyle(color: blue, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
