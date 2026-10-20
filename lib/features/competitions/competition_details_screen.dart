import 'package:flutter/material.dart';

import 'competition_lobby_screen.dart';

class CompetitionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> competition;

  const CompetitionDetailsScreen({super.key, required this.competition});

  @override
  State<CompetitionDetailsScreen> createState() =>
      _CompetitionDetailsScreenState();
}

class _CompetitionDetailsScreenState extends State<CompetitionDetailsScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  // static const Color danger = Color(0xFFFF5C70);

  late bool _registered;

  Map<String, dynamic> get competition => widget.competition;

  String get status => (competition['status'] ?? 'Upcoming').toString();

  String get name => (competition['name'] ?? 'Chess Competition').toString();

  String get shortName => (competition['shortName'] ?? 'SQC').toString();

  String get competitionId => (competition['id'] ?? 'SQC-2026-001').toString();

  String get date => (competition['date'] ?? 'Sep 28, 2026').toString();

  String get time => (competition['time'] ?? '10:00 AM').toString();

  String get players => (competition['players'] ?? '0').toString();

  String get capacity => (competition['capacity'] ?? '0').toString();

  String get timeControl => (competition['timeControl'] ?? '10+5').toString();

  String get skill => (competition['skill'] ?? 'All Levels').toString();

  String get format => (competition['format'] ?? 'Swiss').toString();

  String get rounds => (competition['rounds'] ?? '7').toString();

  String get description =>
      (competition['description'] ??
              'Compete against players, test your chess skills, and battle your way through the tournament.')
          .toString();

  @override
  void initState() {
    super.initState();
    _registered = competition['registered'] == true;
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
                    child: isDesktop
                        ? _buildDesktopLayout()
                        : _buildMobileLayout(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        const SizedBox(height: 28),
        _buildHero(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  _buildAboutSection(),
                  const SizedBox(height: 20),
                  _buildRulesSection(),
                ],
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildActionCard(),
                  const SizedBox(height: 20),
                  _buildCompetitionInfo(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(),
        const SizedBox(height: 22),
        _buildHero(),
        const SizedBox(height: 18),
        _buildActionCard(),
        const SizedBox(height: 18),
        _buildAboutSection(),
        const SizedBox(height: 18),
        _buildCompetitionInfo(),
        const SizedBox(height: 18),
        _buildRulesSection(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _iconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Competition Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _iconButton(icon: Icons.share_outlined, onTap: _shareCompetition),
      ],
    );
  }

  Widget _buildHero() {
    // final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14254A), Color(0xFF0D172B), Color(0xFF0A101D)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -70,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withValues(alpha: 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _competitionLogo(size: 58),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortName.toUpperCase(),
                          style: TextStyle(
                            color: blue.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                description,
                style: const TextStyle(color: muted, fontSize: 14, height: 1.7),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _heroMeta(Icons.calendar_today_outlined, date),
                  _heroMeta(Icons.schedule_outlined, time),
                  _heroMeta(Icons.timer_outlined, timeControl),
                  _heroMeta(
                    Icons.groups_outlined,
                    '$players / $capacity players',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('About this competition', Icons.info_outline_rounded),
          const SizedBox(height: 18),
          Text(
            'Welcome to $name. This competition is designed to give players a structured environment to compete, improve their decision-making, and experience tournament chess.',
            style: const TextStyle(color: muted, fontSize: 14, height: 1.75),
          ),
          const SizedBox(height: 22),
          _featureRow(
            Icons.psychology_outlined,
            'Competitive chess',
            'Play against other registered participants.',
          ),
          _featureRow(
            Icons.auto_graph_rounded,
            'Track your progress',
            'Your games and results can be reviewed after the competition.',
          ),
          _featureRow(
            Icons.emoji_events_outlined,
            'Tournament experience',
            'Advance through the competition and test your skills.',
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Competition Rules', Icons.gavel_rounded),
          const SizedBox(height: 18),
          _ruleItem(
            '01',
            'Fair Play',
            'Players are expected to compete fairly and follow the competition guidelines.',
          ),
          _ruleItem(
            '02',
            'Time Control',
            'Each player receives $timeControl for every game.',
          ),
          _ruleItem(
            '03',
            'Match Result',
            'The result of every completed game is recorded automatically.',
          ),
          _ruleItem(
            '04',
            'Conduct',
            'Respectful behaviour is required throughout the competition.',
          ),
          _ruleItem(
            '05',
            'Administration',
            'Administrators may manually adjust pairings when necessary.',
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionInfo() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Competition Information',
            Icons.dashboard_customize_outlined,
          ),
          const SizedBox(height: 18),
          _infoRow('Competition ID', competitionId, copyable: true),
          _infoRow('Skill Level', skill),
          _infoRow('Format', format),
          _infoRow('Rounds', rounds),
          _infoRow('Time Control', timeControl),
          _infoRow('Players', '$players / $capacity'),
          _infoRow('Start', '$date • $time'),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    final isLive = status.toLowerCase() == 'live';
    final isCompleted = status.toLowerCase() == 'completed';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Competition',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _actionDescription(),
            style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _registrationProgress(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLive
                  ? _watchCompetition
                  : isCompleted
                  ? _viewResults
                  : _registered
                  ? _openLobby
                  : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLive
                    ? green
                    : isCompleted
                    ? surfaceLight
                    : blue,
                foregroundColor: isCompleted ? Colors.white : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLive
                        ? Icons.visibility_outlined
                        : isCompleted
                        ? Icons.emoji_events_outlined
                        : _registered
                        ? Icons.login_rounded
                        : Icons.how_to_reg_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    isLive
                        ? 'Watch Competition'
                        : isCompleted
                        ? 'View Results'
                        : _registered
                        ? 'Enter Lobby'
                        : 'Register Now',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_registered && !isLive && !isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: green.withValues(alpha: 0.18)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: green, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'You are registered for this competition.',
                      style: TextStyle(
                        color: green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _registrationProgress() {
    final current = int.tryParse(players.replaceAll(',', '')) ?? 0;
    final max = int.tryParse(capacity.replaceAll(',', '')) ?? 1;

    final progress = (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Registration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '$players / $capacity',
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.85 ? gold : blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: blue, size: 19),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue, size: 20),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: blue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 15),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () => _copyCompetitionId(value),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy_rounded, color: blue, size: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMeta(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 15),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String value) {
    final color = _statusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _competitionLogo({double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D4A3E), Color(0xFF1749B8)],
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text('â™ž', style: TextStyle(color: Colors.white, fontSize: 29)),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
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

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'live':
        return green;
      case 'completed':
        return muted;
      default:
        return blue;
    }
  }

  String _actionDescription() {
    switch (status.toLowerCase()) {
      case 'live':
        return 'This competition is currently live. Watch ongoing matches and follow the action.';
      case 'completed':
        return 'This competition has ended. Explore the final standings and recorded results.';
      default:
        if (_registered) {
          return 'You are registered. Enter the lobby to prepare for the competition.';
        }

        return 'Secure your place before registration closes.';
    }
  }

  void _register() {
    setState(() {
      _registered = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration successful. Welcome to the competition!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openLobby() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompetitionLobbyScreen(
          competition: {...competition, 'registered': true},
        ),
      ),
    );
  }

  void _watchCompetition() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Spectator mode will open when live matches are available.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Competition results screen will be connected next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareCompetition() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Competition ID: $competitionId'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyCompetitionId(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$value copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
