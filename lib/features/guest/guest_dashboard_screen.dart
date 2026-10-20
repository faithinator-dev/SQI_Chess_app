import 'package:flutter/material.dart';

import '../match/local_pvp_screen.dart';
import '../match/match_config.dart';
import '../match/match_mode.dart';
import '../../practice/practice_screen.dart';
import '../matches/matches_screen.dart';

class GuestDashboardScreen extends StatelessWidget {
  const GuestDashboardScreen({super.key, required this.playerName});

  final String playerName;

  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color purple = Color(0xFF9B7BFF);
  static const Color muted = Color(0xFF737A74);

  void _openLocalPvp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalPvpScreen(
          config: MatchConfig(
            mode: MatchMode.local,
            initialTimeSeconds: 600,
            incrementSeconds: 0,
            whitePlayerName: playerName,
            blackPlayerName: 'Player 2',
          ),
        ),
      ),
    );
  }

  void _openPractice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeScreen(playerName: playerName),
      ),
    );
  }

  void _openLan(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LanLobbyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Guest Dashboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _welcomeCard(),
            const SizedBox(height: 22),
            const Text(
              'PLAY WITHOUT AN ACCOUNT',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _modeCard(
              icon: Icons.smart_toy_rounded,
              color: purple,
              title: 'Play Computer',
              subtitle: 'Play against the computer offline',
              trailing: 'OFFLINE',
              onTap: () => _openPractice(context),
            ),
            const SizedBox(height: 10),
            _modeCard(
              icon: Icons.phone_android_rounded,
              color: green,
              title: 'Local PvP',
              subtitle: 'Two players on this device',
              trailing: 'LOCAL',
              onTap: () => _openLocalPvp(context),
            ),
            const SizedBox(height: 10),
            _modeCard(
              icon: Icons.wifi_rounded,
              color: gold,
              title: 'LAN / Wi-Fi',
              subtitle: 'Play with someone on the same network',
              trailing: 'LAN',
              onTap: () => _openLan(context),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: blue.withValues(alpha: 0.14)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_rounded, color: blue, size: 19),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guest mode does not sign in or use the online database. Online matches and account features are available after signing in.',
                      style: TextStyle(color: muted, height: 1.4, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              playerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.person_outline_rounded, color: muted),
        ],
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
