// lib/features/admin/admin_competitions_screen.dart

import 'package:flutter/material.dart';

class AdminCompetitionsScreen extends StatefulWidget {
  const AdminCompetitionsScreen({super.key});

  @override
  State<AdminCompetitionsScreen> createState() =>
      _AdminCompetitionsScreenState();
}

class _AdminCompetitionsScreenState extends State<AdminCompetitionsScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);
  static const Color white = Color(0xFF1A1A1A);

  String _filter = 'All';
  String _search = '';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _competitions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCompetitions {
    return _competitions.where((competition) {
      final matchesFilter =
          _filter == 'All' || competition['status'] == _filter;

      final query = _search.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          competition['name'].toString().toLowerCase().contains(query) ||
          competition['id'].toString().toLowerCase().contains(query) ||
          competition['skill'].toString().toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get _totalPlayers =>
      _competitions.fold(0, (sum, item) => sum + (item['players'] as int));

  int get _liveCount =>
      _competitions.where((item) => item['status'] == 'Live').length;

  int get _upcomingCount =>
      _competitions.where((item) => item['status'] == 'Upcoming').length;

  int get _completedCount =>
      _competitions.where((item) => item['status'] == 'Completed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1050;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 34 : 18,
                vertical: isDesktop ? 30 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop),
                  const SizedBox(height: 28),
                  _buildStats(isDesktop),
                  const SizedBox(height: 28),
                  _buildToolbar(isDesktop),
                  const SizedBox(height: 20),
                  if (_filteredCompetitions.isEmpty)
                    _buildEmptyState()
                  else if (isDesktop)
                    _buildDesktopTable()
                  else
                    _buildMobileList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _iconButton(
              Icons.arrow_back_rounded,
              () => Navigator.pop(context),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Competitions',
                style: TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Published competition records will appear here when available.',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          _iconButton(Icons.refresh_rounded, () {
            setState(() {});
          }),
          const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildStats(bool isDesktop) {
    final cards = [
      _StatData(
        'Total Competitions',
        '${_competitions.length}',
        Icons.emoji_events_rounded,
        blue,
      ),
      _StatData('Live Now', '$_liveCount', Icons.sensors_rounded, green),
      _StatData('Upcoming', '$_upcomingCount', Icons.schedule_rounded, gold),
      _StatData(
        'Completed',
        '$_completedCount',
        Icons.check_circle_rounded,
        muted,
      ),
      _StatData(
        'Registered Players',
        '$_totalPlayers',
        Icons.people_alt_rounded,
        const Color(0xFF9B7BFF),
      ),
    ];

    if (!isDesktop) {
      return SizedBox(
        height: 125,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            return SizedBox(width: 190, child: _statCard(cards[index]));
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 245,
        mainAxisExtent: 120,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) => _statCard(cards[index]),
    );
  }

  Widget _statCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    color: muted.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 16),
                _filterButtons(),
              ],
            )
          : Column(
              children: [
                _searchField(),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _filterButtons(),
                ),
              ],
            ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _search = value;
          });
        },
        style: const TextStyle(fontSize: 20, color: white),
        decoration: InputDecoration(
          hintText: 'Search competitions, IDs or skill levels...',
          hintStyle: TextStyle(
            fontSize: 20,
            color: muted.withValues(alpha: 0.7),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 20),
          filled: true,
          fillColor: surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: blue.withValues(alpha: 0.65)),
          ),
        ),
      ),
    );
  }

  Widget _filterButtons() {
    const filters = ['All', 'Upcoming', 'Live', 'Completed'];

    return Row(
      children: filters.map((filter) {
        final selected = _filter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _filter = filter;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? blue.withValues(alpha: 0.16) : surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? blue.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.045),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 20,
                  color: selected ? blue : muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: surfaceLight.withValues(alpha: 0.55),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 310, child: Text('COMPETITION')),
                SizedBox(width: 110, child: Text('STATUS')),
                SizedBox(width: 150, child: Text('DATE')),
                SizedBox(width: 135, child: Text('PLAYERS')),
                SizedBox(width: 150, child: Text('FORMAT')),
                Expanded(child: Text('ACTION')),
              ],
            ),
          ),
          ..._filteredCompetitions.map(_desktopRow),
        ],
      ),
    );
  }

  Widget _desktopRow(Map<String, dynamic> competition) {
    final progress =
        (competition['players'] as int) / (competition['capacity'] as int);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 310,
            child: Row(
              children: [
                _competitionLogo(competition),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              competition['name'],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                color: white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (competition['featured'] == true) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star_rounded,
                              color: gold,
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        competition['id'],
                        style: TextStyle(
                          fontSize: 20,
                          color: muted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 110, child: _statusBadge(competition['status'])),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  competition['date'],
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  competition['time'],
                  style: TextStyle(
                    fontSize: 20,
                    color: muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 135,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${competition['players']} / ${competition['capacity']}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: surfaceLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 0.9 ? danger : blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Row(
              children: [
                _smallInfo(competition['format'], Icons.account_tree_rounded),
                const SizedBox(width: 8),
                _smallInfo(competition['timeControl'], Icons.timer_outlined),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _actionButton(competition),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _filteredCompetitions
          .map(
            (competition) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _mobileCompetitionCard(competition),
            ),
          )
          .toList(),
    );
  }

  Widget _mobileCompetitionCard(Map<String, dynamic> competition) {
    final progress =
        (competition['players'] as int) / (competition['capacity'] as int);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _competitionLogo(competition),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      competition['id'],
                      style: TextStyle(
                        fontSize: 20,
                        color: muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(competition['status']),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detailChip(Icons.calendar_today_rounded, competition['date']),
              _detailChip(Icons.schedule_rounded, competition['time']),
              _detailChip(Icons.timer_outlined, competition['timeControl']),
              _detailChip(Icons.bar_chart_rounded, competition['skill']),
              _detailChip(Icons.account_tree_rounded, competition['format']),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registration',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${competition['players']} / ${competition['capacity']} players',
                style: const TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9 ? danger : blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCompetitionDetails(competition),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    minimumSize: const Size(0, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text(
                    'Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: _primaryActionButton(competition, height: 45)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _competitionLogo(Map<String, dynamic> competition) {
    final status = competition['status'];

    final color = status == 'Live'
        ? green
        : status == 'Completed'
        ? muted
        : blue;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          competition['short'],
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Live':
        color = green;
        break;
      case 'Completed':
        color = muted;
        break;
      default:
        color = gold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(Map<String, dynamic> competition) {
    return _primaryActionButton(competition, height: 38, width: 110);
  }

  Widget _primaryActionButton(
    Map<String, dynamic> competition, {
    double height = 44,
    double? width,
  }) {
    final status = competition['status'];

    String label;
    IconData icon;

    if (status == 'Live') {
      label = 'Monitor';
      icon = Icons.monitor_heart_outlined;
    } else if (status == 'Completed') {
      label = 'Results';
      icon = Icons.bar_chart_rounded;
    } else {
      label = 'Manage';
      icon = Icons.settings_outlined;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: () => _showCompetitionDetails(competition),
        style: ElevatedButton.styleFrom(
          backgroundColor: blue.withValues(alpha: 0.13),
          foregroundColor: blue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: blue.withValues(alpha: 0.18)),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: white, size: 20),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 70),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: blue, size: 32),
          ),
          const SizedBox(height: 18),
          const Text(
            'No competitions found',
            style: TextStyle(
              fontSize: 20,
              color: white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(
              fontSize: 20,
              color: muted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompetitionDetails(Map<String, dynamic> competition) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _CompetitionDetailsSheet(
          competition: competition,
          onDelete: () {
            Navigator.pop(context);
            _confirmDelete(competition);
          },
          onEdit: () {
            Navigator.pop(context);
            _showEditCompetitionDialog(competition);
          },
        );
      },
    );
  }

  void _showEditCompetitionDialog(Map<String, dynamic> competition) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Competition editing is unavailable until a verified admin operation is configured.',
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> competition) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Competition deletion is unavailable until a verified admin operation is configured.',
        ),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _CompetitionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> competition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompetitionDetailsSheet({
    required this.competition,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);
  static const Color white = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final status = competition['status'].toString();

    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 23),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: blue,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          competition['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            color: white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          competition['id'],
                          style: TextStyle(
                            fontSize: 20,
                            color: muted.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 25),
              _infoGrid(),
              const SizedBox(height: 22),
              _sectionTitle('Registration'),
              const SizedBox(height: 10),
              _registrationProgress(),
              const SizedBox(height: 25),
              _sectionTitle('Admin Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Competition controls require a verified admin service.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text(
                        'Manage',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: danger,
                    minimumSize: const Size(0, 46),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Delete Competition',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoGrid() {
    final items = [
      ('Date', competition['date'], Icons.calendar_today_rounded),
      ('Time', competition['time'], Icons.schedule_rounded),
      ('Time Control', competition['timeControl'], Icons.timer_outlined),
      ('Skill', competition['skill'], Icons.bar_chart_rounded),
      ('Format', competition['format'], Icons.account_tree_rounded),
      ('Rounds', '${competition['rounds']}', Icons.layers_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 76,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, index) {
        final item = items[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Icon(item.$3, color: blue, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 20,
                        color: muted.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _registrationProgress() {
    final players = competition['players'] as int;
    final capacity = competition['capacity'] as int;
    final progress = players / capacity;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: blue, size: 19),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Registered Players',
                  style: TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$players / $capacity',
                style: const TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9 ? gold : green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        color: white,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Live':
        color = green;
        break;
      case 'Completed':
        color = muted;
        break;
      default:
        color = gold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
