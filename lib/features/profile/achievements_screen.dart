import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {
        'icon': 'WIN',
        'title': 'First Victory',
        'description': 'Win your first competitive game.',
        'unlocked': true,
        'color': gold,
      },
      {
        'icon': 'SPD',
        'title': 'Speed Demon',
        'description': 'Win a rapid time-control game.',
        'unlocked': true,
        'color': blue,
      },
      {
        'icon': 'HOT',
        'title': 'Hot Streak',
        'description': 'Win three games in a row.',
        'unlocked': true,
        'color': green,
      },
      {
        'icon': 'TRN',
        'title': 'Tournament Player',
        'description': 'Complete your first tournament.',
        'unlocked': false,
        'color': blue,
      },
      {
        'icon': 'RAT',
        'title': 'Rating Climber',
        'description': 'Reach a rating of 1,400.',
        'unlocked': false,
        'color': gold,
      },
      {
        'icon': 'TAC',
        'title': 'Tactical Mind',
        'description': 'Win 10 competitive games.',
        'unlocked': false,
        'color': green,
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        title: const Text(
          'Achievements',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _progressHeader(),
            const SizedBox(height: 20),
            ...achievements.map(
              (achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _achievementCard(achievement),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressHeader() {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF172F67), Color(0xFF0D172B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PROGRESS',
            style: TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                '3',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / 12',
                style: TextStyle(
                  fontSize: 20,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Icon(Icons.workspace_premium_rounded, color: gold, size: 35),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.25,
              minHeight: 8,
              backgroundColor: surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(gold),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Keep playing to unlock more achievements.',
            style: TextStyle(fontSize: 20, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _achievementCard(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'] == true;
    final color = achievement['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: unlocked
              ? color.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: unlocked ? color.withValues(alpha: 0.10) : surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement['icon'].toString(),
                style: TextStyle(fontSize: 20, color: unlocked ? color : muted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['title'].toString(),
                  style: TextStyle(
                    fontSize: 20,
                    color: unlocked ? Colors.white : muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  achievement['description'].toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: unlocked ? green : muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
