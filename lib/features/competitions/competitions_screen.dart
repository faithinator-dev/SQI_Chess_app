import 'package:flutter/material.dart';

import '../../core/models/competition_model.dart';
import '../../core/repositories/competition_repository.dart';
import 'competition_details_screen.dart';

class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  // static const Color danger = Color(0xFFFF5C70);

  String _selectedFilter = 'Upcoming';
  String _searchQuery = '';
  final CompetitionRepository _repository = CompetitionRepository();
  List<Map<String, dynamic>> _competitions = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  /* final List<Map<String, dynamic>> _competitions = [
    {
      'id': 'SQC-2026-001',
      'shortName': 'SQC',
      'name': 'SQI Checkmate Cup',
      'status': 'Upcoming',
      'date': 'Sep 28, 2026',
      'time': '10:00 AM',
      'players': '128',
      'capacity': '256',
      'timeControl': '10+5',
      'skill': 'All Levels',
      'format': 'Swiss',
      'rounds': '7',
      'registered': true,
    },
    {
      'id': 'SQC-2026-002',
      'shortName': 'BB',
      'name': 'Beginner Battle',
      'status': 'Upcoming',
      'date': 'Sep 30, 2026',
      'time': '4:00 PM',
      'players': '46',
      'capacity': '100',
      'timeControl': '10+0',
      'skill': 'Beginner',
      'format': 'Arena',
      'rounds': '5',
      'registered': false,
    },
    {
      'id': 'SQC-2026-003',
      'shortName': 'RM',
      'name': 'Rapid Masters',
      'status': 'Live',
      'date': 'Sep 25, 2026',
      'time': '8:00 PM',
      'players': '184',
      'capacity': '200',
      'timeControl': '15+10',
      'skill': 'Intermediate+',
      'format': 'Swiss',
      'rounds': '9',
      'registered': false,
    },
    {
      'id': 'SQC-2026-004',
      'shortName': 'CCC',
      'name': 'Campus Chess Clash',
      'status': 'Upcoming',
      'date': 'Oct 03, 2026',
      'time': '2:00 PM',
      'players': '73',
      'capacity': '150',
      'timeControl': '10+5',
      'skill': 'All Levels',
      'format': 'Swiss',
      'rounds': '7',
      'registered': false,
    },
    {
      'id': 'SQC-2026-005',
      'shortName': 'LA',
      'name': 'Lightning Arena',
      'status': 'Completed',
      'date': 'Sep 20, 2026',
      'time': '6:00 PM',
      'players': '96',
      'capacity': '100',
      'timeControl': '3+2',
      'skill': 'All Levels',
      'format': 'Arena',
      'rounds': '10',
      'registered': false,
    },
  ]; */

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final competitions = await _repository.getCompetitions(
        status: _selectedFilter,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _competitions = competitions.map(_toLegacyMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _competitions = <Map<String, dynamic>>[];
      });
    }
  }

  Map<String, dynamic> _toLegacyMap(CompetitionModel competition) {
    final start = competition.startsAt;
    final status = switch (competition.status) {
      'registration_open' || 'published' || 'registration_closed' => 'Upcoming',
      'in_progress' => 'Live',
      'completed' => 'Completed',
      _ => competition.status,
    };

    return {
      'id': competition.id,
      'shortName': competition.title.length >= 3
          ? competition.title.substring(0, 3).toUpperCase()
          : competition.title.toUpperCase(),
      'name': competition.title,
      'status': status,
      'date': start == null
          ? 'Date unavailable'
          : '${start.day}/${start.month}/${start.year}',
      'time': start == null
          ? 'Time unavailable'
          : '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
      'players': competition.registeredPlayers.toString(),
      'capacity': competition.capacity?.toString() ?? '—',
      'timeControl': competition.timeControl,
      'skill': 'All Levels',
      'format': competition.format,
      'rounds': '—',
      'registered': competition.registered,
    };
  }

  List<Map<String, dynamic>> get _filteredCompetitions {
    var results = List<Map<String, dynamic>>.from(_competitions);

    if (_selectedFilter != 'All') {
      results = results
          .where((competition) => competition['status'] == _selectedFilter)
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();

      results = results.where((competition) {
        final name = competition['name'].toString().toLowerCase();
        final id = competition['id'].toString().toLowerCase();

        return name.contains(query) || id.contains(query);
      }).toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 950;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 18,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 25),
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        _buildFilters(),
                        const SizedBox(height: 22),
                        _buildCompetitionContent(isDesktop),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.emoji_events_outlined, color: blue, size: 23),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arena',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Compete. Improve. Conquer.',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ),
        ),
        _headerButton(Icons.search_rounded, _showSearchDialog),
        const SizedBox(width: 9),
        _headerButton(Icons.tune_rounded, _showFilterInfo),
      ],
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF142A5A), Color(0xFF0E1A31), Color(0xFF0A101D)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue.withValues(alpha: 0.09),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -110,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.035),
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: green.withValues(alpha: 0.16)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: green, size: 7),
                        SizedBox(width: 7),
                        Text(
                          'ARENA OPEN',
                          style: TextStyle(
                            color: green,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Your next tournament\nstarts here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose your competition, enter the lobby,\nand prepare for your next battle.',
                style: TextStyle(color: muted, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 23),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _heroStat('5', 'Events'),
                  _heroStat('527', 'Players'),
                  _heroStat('24/7', 'Competition'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const filters = ['Upcoming', 'Live', 'Completed', 'All'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                _loadCompetitions();
              },
              borderRadius: BorderRadius.circular(13),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: selected ? blue : surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected
                        ? blue
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: selected ? Colors.white : muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompetitionContent(bool isDesktop) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded, color: muted, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Competitions are unavailable.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect to the competition service and try again.',
                style: TextStyle(color: muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _loadCompetitions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final competitions = _filteredCompetitions;

    if (competitions.isEmpty) {
      return _buildEmptyState();
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: competitions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.30,
        ),
        itemBuilder: (context, index) {
          final competition = competitions[index];

          return _competitionCard(competition: competition);
        },
      );
    }

    return Column(
      children: competitions.map((competition) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _competitionCard(competition: competition),
        );
      }).toList(),
    );
  }

  Widget _competitionCard({required Map<String, dynamic> competition}) {
    final status = competition['status'].toString();

    final registered = competition['registered'] == true;

    final statusColor = _statusColor(status);

    final players = competition['players'].toString();

    final capacity = competition['capacity'].toString();

    final currentPlayers = int.tryParse(players.replaceAll(',', '')) ?? 0;

    final maxPlayers = int.tryParse(capacity.replaceAll(',', '')) ?? 1;

    final progress = (currentPlayers / maxPlayers).clamp(0.0, 1.0);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _openCompetition(competition),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _competitionLogo(competition['shortName'].toString()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          competition['shortName'].toString().toUpperCase(),
                          style: TextStyle(
                            color: blue.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          competition['name'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status, statusColor),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _metaItem(
                    Icons.calendar_today_outlined,
                    competition['date'].toString(),
                  ),
                  const SizedBox(width: 16),
                  _metaItem(
                    Icons.schedule_outlined,
                    competition['time'].toString(),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  _metaItem(
                    Icons.timer_outlined,
                    competition['timeControl'].toString(),
                  ),
                  const SizedBox(width: 16),
                  _metaItem(
                    Icons.bar_chart_rounded,
                    competition['skill'].toString(),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_outlined,
                              color: muted,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$players / $capacity players',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress > 0.85 ? gold : blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  _cardAction(status: status, registered: registered),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardAction({required String status, required bool registered}) {
    String text;

    IconData icon;

    if (status == 'Live') {
      text = 'Watch';
      icon = Icons.visibility_outlined;
    } else if (status == 'Completed') {
      text = 'Results';
      icon = Icons.emoji_events_outlined;
    } else if (registered) {
      text = 'Lobby';
      icon = Icons.login_rounded;
    } else {
      text = 'Register';
      icon = Icons.how_to_reg_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: blue.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: blue, size: 15),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: muted, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _competitionLogo(String text) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4A3E), Color(0xFF1749B8)],
        ),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text.length > 3 ? text.substring(0, 3) : text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 55),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: blue, size: 28),
          ),
          const SizedBox(height: 17),
          const Text(
            'No competitions found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try another filter or search for a different competition.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _searchQuery = '';
              });
            },
            child: const Text(
              'Show all competitions',
              style: TextStyle(color: blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return green;
      case 'completed':
        return muted;
      default:
        return blue;
    }
  }

  void _openCompetition(Map<String, dynamic> competition) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompetitionDetailsScreen(competition: competition),
      ),
    );
  }

  void _showSearchDialog() {
    final controller = TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Search Competitions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Competition name or ID',
              hintStyle: const TextStyle(color: muted),
              prefixIcon: const Icon(Icons.search_rounded, color: muted),
              filled: true,
              fillColor: surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) {
              _performSearch(controller.text, dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel', style: TextStyle(color: muted)),
            ),
            ElevatedButton(
              onPressed: () {
                _performSearch(controller.text, dialogContext);
              },
              style: ElevatedButton.styleFrom(backgroundColor: blue),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String query, BuildContext dialogContext) {
    Navigator.pop(dialogContext);

    setState(() {
      _searchQuery = query;
      _selectedFilter = 'All';
    });

    final results = _filteredCompetitions;

    if (results.isNotEmpty) {
      _openCompetition(results.first);
    }
  }

  void _showFilterInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Competition Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the filters above to browse competitions by their current state.',
                  style: TextStyle(color: muted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                _filterInfoRow('Upcoming', 'Registration is available.', blue),
                _filterInfoRow(
                  'Live',
                  'Games are currently being played.',
                  green,
                ),
                _filterInfoRow('Completed', 'Competition has ended.', muted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterInfoRow(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
