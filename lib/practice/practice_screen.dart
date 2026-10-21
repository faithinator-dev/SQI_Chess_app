import 'package:flutter/material.dart';
import 'package:sqi_chess_club/practice/practice_game_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.playerName});

  final String? playerName;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color purple = Color(0xFF9B7BFF);
  static const Color white = Color(0xFF1A1A1A);

  int _selectedLevel = 1;

  final List<Map<String, dynamic>> _levels = [
    {
      'title': 'Beginner',
      'subtitle': 'Build your foundation',
      'description':
          'Learn basic tactics, piece movement, check, captures and simple winning patterns.',
      'rating': '600 - 900',
      'exercises': '120+',
      'icon': Icons.school_rounded,
      'color': green,
      'focus': [
        'Piece movement',
        'Basic tactics',
        'Check & checkmate',
        'Simple captures',
      ],
    },
    {
      'title': 'Intermediate',
      'subtitle': 'Sharpen your game',
      'description':
          'Improve tactical awareness, calculation, positional understanding and decision making.',
      'rating': '900 - 1300',
      'exercises': '240+',
      'icon': Icons.psychology_rounded,
      'color': blue,
      'focus': [
        'Tactical patterns',
        'Calculation',
        'Forks & pins',
        'Position evaluation',
      ],
    },
    {
      'title': 'Advanced',
      'subtitle': 'Think several moves ahead',
      'description':
          'Train deeper calculation, strategic planning, advanced tactics and difficult positions.',
      'rating': '1300 - 1700',
      'exercises': '180+',
      'icon': Icons.auto_awesome_rounded,
      'color': purple,
      'focus': [
        'Deep calculation',
        'Advanced tactics',
        'Strategic play',
        'Endgame technique',
      ],
    },
    {
      'title': 'Expert',
      'subtitle': 'Master the position',
      'description':
          'Face complex positions that demand accurate calculation, patience and strong technique.',
      'rating': '1700+',
      'exercises': '100+',
      'icon': Icons.workspace_premium_rounded,
      'color': gold,
      'focus': [
        'Complex positions',
        'Engine-like calculation',
        'Advanced strategy',
        'Difficult endgames',
      ],
    },
    {
      'title': 'Creator',
      'subtitle': 'Just Challenge The Creator if you can',
      'description': 'You Challenge either you win or losses',
      'rating': '1200+',
      'exercises': '180+',
      'icon': Icons.person,
      'color': const Color.fromARGB(255, 196, 9, 202),
      'focus': [
        'Challenging',
        'Engine-like calculation',
        'Advanced strategy',
        'Difficult endgames',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1000;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 34 : 16,
                vertical: desktop ? 28 : 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(desktop),
                      const SizedBox(height: 28),
                      _hero(desktop),
                      const SizedBox(height: 28),
                      _sectionHeader(),
                      const SizedBox(height: 16),
                      _levelGrid(desktop),
                      const SizedBox(height: 28),
                      _practiceInfo(desktop),
                      const SizedBox(height: 30),
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

  Widget _topBar(bool desktop) {
    return Row(
      children: [
        _backButton(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Practice',
                style: TextStyle(
                  fontSize: 16,
                  color: white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Train your mind. Improve your game.',
                style: TextStyle(
                  fontSize: 16,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (desktop) ...[
          _topIcon(Icons.notifications_none_rounded),
          const SizedBox(width: 10),
          _topIcon(Icons.help_outline_rounded),
        ],
      ],
    );
  }

  Widget _backButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: white, size: 20),
      ),
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: white, size: 19),
      ),
    );
  }

  Widget _hero(bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 28 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage("assets/images/herobg2.jpg"),
          fit: .fill,
        ),
        border: Border.all(color: blue.withValues(alpha: 0.20)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: purple.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: green, size: 7),
                        SizedBox(width: 6),
                        Text(
                          'NO RATING IMPACT',
                          style: TextStyle(
                            fontSize: 16,
                            color: green,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Train like a\nbetter player.',
                style: TextStyle(
                  fontSize: 16,
                  color: white,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 650,
                child: Text(
                  'Choose your level and solve chess positions \ndesigned to improve your tactical vision, \ncalculation and decision making.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1B3057),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _heroStat(Icons.bolt_rounded, '640+', 'Exercises', blue),
                  const SizedBox(width: 24),
                  _heroStat(Icons.trending_up_rounded, '4', 'Levels', purple),
                  const SizedBox(width: 24),
                  _heroStat(Icons.timer_outlined, '--', 'Attempts', gold),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 16, color: muted)),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Level',
                style: TextStyle(
                  fontSize: 16,
                  color: white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Select a difficulty that matches your current skill.',
                style: TextStyle(fontSize: 16, color: muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: muted, size: 14),
              SizedBox(width: 6),
              Text(
                'Practice is unrated',
                style: TextStyle(
                  fontSize: 16,
                  color: muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelGrid(bool desktop) {
    if (!desktop) {
      return Column(
        children: [
          for (int i = 0; i < _levels.length; i++) ...[
            _levelCard(_levels[i], i, false),
            if (i != _levels.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _levels.length; i++) ...[
          Expanded(child: _levelCard(_levels[i], i, true)),
          if (i != _levels.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _levelCard(Map<String, dynamic> level, int index, bool desktop) {
    final Color color = level['color'];
    final bool selected = _selectedLevel == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Color.lerp(surface, color, 0.06) : surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.06),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(level['icon'], color: color, size: 21),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              level['title'],
              style: const TextStyle(
                fontSize: 16,
                color: white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              level['subtitle'],
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              level['description'],
              maxLines: desktop ? 4 : 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, color: muted, height: 1.55),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: surfaceLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: muted, size: 14),
                  const SizedBox(width: 7),
                  const Text(
                    'Rating',
                    style: TextStyle(fontSize: 16, color: muted),
                  ),
                  const Spacer(),
                  Text(
                    level['rating'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: surfaceLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(Icons.extension_rounded, color: muted, size: 14),
                  const SizedBox(width: 7),
                  const Text(
                    'Exercises',
                    style: TextStyle(fontSize: 16, color: muted),
                  ),
                  const Spacer(),
                  Text(
                    level['exercises'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FOCUS',
              style: TextStyle(
                fontSize: 16,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final focus in level['focus'])
                  _focusChip(focus.toString(), color),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _startPractice(level),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? color : surfaceLight,
                  foregroundColor: selected ? Colors.white : white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected
                          ? color
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: selected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Start Practice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: color.withValues(alpha: 0.9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _practiceInfo(bool desktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(desktop ? 22 : 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: desktop
          ? Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.lightbulb_outline_rounded,
                    'Solve',
                    'Study the position and find the strongest move.',
                    gold,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _infoItem(
                    Icons.touch_app_rounded,
                    'Play',
                    'Make your move directly on the board.',
                    blue,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _infoItem(
                    Icons.analytics_outlined,
                    'Learn',
                    'Review the position and understand the idea.',
                    purple,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _infoItem(
                  Icons.lightbulb_outline_rounded,
                  'Solve',
                  'Study the position and find the strongest move.',
                  gold,
                ),
                const SizedBox(height: 16),
                _infoItem(
                  Icons.touch_app_rounded,
                  'Play',
                  'Make your move directly on the board.',
                  blue,
                ),
                const SizedBox(height: 16),
                _infoItem(
                  Icons.analytics_outlined,
                  'Learn',
                  'Review the position and understand the idea.',
                  purple,
                ),
              ],
            ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: muted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startPractice(Map<String, dynamic> level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(level['icon'], color: level['color'], size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${level['title']} practice selected',
                style: const TextStyle(
                  fontSize: 16,
                  color: white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Later:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeGameScreen(
          level: level['title'],
          playerName: widget.playerName,
        ),
      ),
    );
  }
}
