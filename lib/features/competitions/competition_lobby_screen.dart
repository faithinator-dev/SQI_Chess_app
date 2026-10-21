import 'dart:async';

import 'package:flutter/material.dart';

import '../match/chess_match_screen.dart';

class CompetitionLobbyScreen extends StatefulWidget {
  final Map<String, dynamic> competition;

  const CompetitionLobbyScreen({super.key, required this.competition});

  @override
  State<CompetitionLobbyScreen> createState() => _CompetitionLobbyScreenState();
}

class _CompetitionLobbyScreenState extends State<CompetitionLobbyScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  // static const Color danger = Color(0xFFFF5C70);

  Timer? _timer;

  int _secondsUntilStart = 38;
  final int _players = 128;
  bool _ready = false;
  bool _paired = false;

  Map<String, dynamic> get competition => widget.competition;

  String get name => (competition['name'] ?? 'SQI Checkmate Cup').toString();

  String get competitionId => (competition['id'] ?? 'SQC-2026-001').toString();

  String? get gameId {
    final value = competition['gameId'] ?? competition['game_id'];

    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();

    return normalized.isEmpty ? null : normalized;
  }

  String get date => (competition['date'] ?? 'Sep 28, 2026').toString();

  String get time => (competition['time'] ?? '10:00 AM').toString();

  String get timeControl => (competition['timeControl'] ?? '10+5').toString();

  String get skill => (competition['skill'] ?? 'All Levels').toString();

  String get format => (competition['format'] ?? 'Swiss').toString();

  String get rounds => (competition['rounds'] ?? '7').toString();
  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_secondsUntilStart > 0) {
        setState(() {
          _secondsUntilStart--;
        });
      } else {
        _timer?.cancel();

        if (!mounted) {
          return;
        }

        setState(() {
          _paired = gameId != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 18,
                      vertical: 18,
                    ),
                    child: isDesktop ? _buildDesktop() : _buildMobile(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 25),
        _buildCompetitionBanner(),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildPlayerSection(),
                  const SizedBox(height: 20),
                  _buildPairingSection(),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildPlayerCard(),
                  const SizedBox(height: 20),
                  _buildCompetitionInfo(),
                  const SizedBox(height: 20),
                  _buildRulesCard(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildCompetitionBanner(),
        const SizedBox(height: 18),
        _buildStatusCard(),
        const SizedBox(height: 18),
        _buildPlayerCard(),
        const SizedBox(height: 18),
        _buildPlayerSection(),
        const SizedBox(height: 18),
        _buildPairingSection(),
        const SizedBox(height: 18),
        _buildCompetitionInfo(),
        const SizedBox(height: 18),
        _buildRulesCard(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _iconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Competition Lobby',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Prepare for battle',
                style: TextStyle(fontSize: 20, color: muted),
              ),
            ],
          ),
        ),
        _statusBadge(
          _paired ? 'MATCH READY' : 'REGISTERED',
          _paired ? green : blue,
        ),
      ],
    );
  }

  Widget _buildCompetitionBanner() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142956), Color(0xFF0E1A31), Color(0xFF0A111F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -90,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withValues(alpha: 0.09),
              ),
            ),
          ),
          Row(
            children: [
              _competitionLogo(),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SQI CHECKMATE ARENA',
                      style: TextStyle(
                        fontSize: 20,
                        color: blue,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      competitionId,
                      style: const TextStyle(
                        fontSize: 20,
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final ready = _secondsUntilStart <= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: ready
              ? green.withValues(alpha: 0.22)
              : blue.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ready
                      ? green.withValues(alpha: 0.10)
                      : blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  ready
                      ? Icons.play_circle_outline_rounded
                      : Icons.hourglass_top_rounded,
                  color: ready ? green : blue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament Status',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stay in the lobby while the tournament prepares.',
                      style: TextStyle(fontSize: 20, color: muted),
                    ),
                  ],
                ),
              ),
              _statusBadge(ready ? 'LIVE' : 'WAITING', ready ? green : gold),
            ],
          ),
          const SizedBox(height: 27),
          _buildCountdown(),
          const SizedBox(height: 24),
          if (!ready) _buildReadyButton(),
          if (ready) _buildEnterMatchButton(),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    if (_secondsUntilStart <= 0) {
      return Column(
        children: [
          const Text(
            'PAIRING READY',
            style: TextStyle(
              fontSize: 20,
              color: green,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your match is ready',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    final minutes = (_secondsUntilStart ~/ 60).toString().padLeft(2, '0');

    final seconds = (_secondsUntilStart % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        const Text(
          'COMPETITION STARTS IN',
          style: TextStyle(
            fontSize: 20,
            color: muted,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '$date • $time',
          style: const TextStyle(fontSize: 20, color: muted),
        ),
      ],
    );
  }

  Widget _buildReadyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _ready = !_ready;
          });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _ready
                ? green.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.10),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _ready
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: _ready ? green : muted,
              size: 19,
            ),
            const SizedBox(width: 9),
            Text(
              _ready ? 'You are ready' : 'Mark me as ready',
              style: TextStyle(
                fontSize: 20,
                color: _ready ? green : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterMatchButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _enterMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_rounded, size: 20),
            SizedBox(width: 9),
            Text(
              'Enter Your Match',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Player Card',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _avatar(initials: 'FT', size: 52),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faith Toluwanimi',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Intermediate • 1,284',
                      style: TextStyle(fontSize: 20, color: muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'P 1,284',
                  style: TextStyle(
                    fontSize: 20,
                    color: gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF202B40), height: 1),
          const SizedBox(height: 17),
          Row(
            children: [
              _smallStat('RATING', '1,284'),
              _smallStat('WINS', '18'),
              _smallStat('WIN RATE', '67%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection() {
    return _panel(
      title: 'Players',
      icon: Icons.groups_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _playerMetric(
                  icon: Icons.people_alt_outlined,
                  value: '$_players',
                  label: 'Registered',
                ),
              ),
              Expanded(
                child: _playerMetric(
                  icon: Icons.person_add_alt_1_outlined,
                  value: '14',
                  label: 'Joining',
                ),
              ),
              Expanded(
                child: _playerMetric(
                  icon: Icons.online_prediction_rounded,
                  value: '98',
                  label: 'Online',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _playerProgress(),
        ],
      ),
    );
  }

  Widget _buildPairingSection() {
    return _panel(
      title: 'Pairing',
      icon: Icons.compare_arrows_rounded,
      child: _paired
          ? _buildPairedOpponent()
          : Column(
              children: [
                const SizedBox(height: 5),
                Icon(
                  Icons.shuffle_rounded,
                  color: blue.withValues(alpha: 0.8),
                  size: 35,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Automatic pairing',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Players will be paired according to skill level and tournament rules.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: muted, height: 1.5),
                ),
                const SizedBox(height: 17),
                _pairingRule('Skill level', skill),
                _pairingRule('Format', format),
                _pairingRule('Time control', timeControl),
              ],
            ),
    );
  }

  Widget _buildPairedOpponent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: green.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              _avatar(initials: 'DA', size: 48),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daniel Ade',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Intermediate • 1,301',
                      style: TextStyle(fontSize: 20, color: muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: green, size: 23),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _pairingRule('Match', '#SQA-28491'),
        _pairingRule('Time control', timeControl),
        _pairingRule('Side', 'White'),
      ],
    );
  }

  Widget _buildCompetitionInfo() {
    return _panel(
      title: 'Competition Info',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          _infoRow('Format', format),
          _infoRow('Rounds', rounds),
          _infoRow('Skill', skill),
          _infoRow('Time', timeControl),
          _infoRow('Date', date),
          _infoRow('Start', time),
          _infoRow('ID', competitionId),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    return _panel(
      title: 'Quick Rules',
      icon: Icons.gavel_outlined,
      child: Column(
        children: [
          _quickRule(
            Icons.timer_outlined,
            'Respect the clock',
            'Games use the listed time control.',
          ),
          _quickRule(
            Icons.handshake_outlined,
            'Play fair',
            'Follow competition fair-play rules.',
          ),
          _quickRule(
            Icons.wifi_rounded,
            'Stay connected',
            'Keep a stable connection during games.',
          ),
          _quickRule(
            Icons.support_agent_outlined,
            'Need help?',
            'Contact an administrator if an issue occurs.',
          ),
        ],
      ),
    );
  }

  Widget _playerProgress() {
    final progress = (_players / 256).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Tournament capacity',
              style: TextStyle(fontSize: 20, color: muted),
            ),
            const Spacer(),
            Text(
              '$_players / 256',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(blue),
          ),
        ),
      ],
    );
  }

  Widget _playerMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 20, color: muted)),
      ],
    );
  }

  Widget _pairingRule(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 20, color: muted)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickRule(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 20,
                    color: muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, color: muted),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
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

  Widget _panel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: blue, size: 18),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _smallStat(String label, String value) {
    return Expanded(
      child: Column(
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
            style: const TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar({required String initials, required double size}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4A3E), Color(0xFF1749B8)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 2,
        ),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _competitionLogo() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4A3E), Color(0xFF1749B8)],
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text('N', style: TextStyle(fontSize: 20, color: Colors.white)),
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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _enterMatch() {
    final id = gameId;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your match has not been assigned yet. Please wait for pairing.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChessMatchScreen(gameId: id)),
    );
  }
}
