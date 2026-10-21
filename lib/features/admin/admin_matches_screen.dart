// lib/features/admin/admin_matches_screen.dart

import 'package:flutter/material.dart';

class AdminMatchesScreen extends StatefulWidget {
  const AdminMatchesScreen({super.key});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);
  static const Color white = Color(0xFF1A1A1A);
  static const Color purple = Color(0xFF9B7BFF);

  String _filter = 'All';
  String _search = '';
  String _selectedCompetition = 'All Competitions';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _competitions = [];

  final List<Map<String, dynamic>> _matches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredMatches {
    return _matches.where((match) {
      final statusMatch = _filter == 'All' || match['status'] == _filter;

      final competitionMatch =
          _selectedCompetition == 'All Competitions' ||
          match['competition'] == _selectedCompetition;

      final query = _search.trim().toLowerCase();

      final searchMatch =
          query.isEmpty ||
          match['id'].toString().toLowerCase().contains(query) ||
          match['white'].toString().toLowerCase().contains(query) ||
          match['black'].toString().toLowerCase().contains(query) ||
          match['whiteUsername'].toString().toLowerCase().contains(query) ||
          match['blackUsername'].toString().toLowerCase().contains(query);

      return statusMatch && competitionMatch && searchMatch;
    }).toList();
  }

  int _countStatus(String status) {
    return _matches.where((match) => match['status'] == status).length;
  }

  int get _totalSpectators {
    return _matches.fold(0, (sum, match) => sum + (match['spectators'] as int));
  }

  int get _totalMoves {
    return _matches.fold(0, (sum, match) => sum + (match['moves'] as int));
  }

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
                  const SizedBox(height: 26),
                  _buildLiveOverview(isDesktop),
                  const SizedBox(height: 24),
                  _buildStats(isDesktop),
                  const SizedBox(height: 24),
                  _buildToolbar(isDesktop),
                  const SizedBox(height: 18),
                  if (_filteredMatches.isEmpty)
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
                'Matches',
                style: TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor live games, results and match activity.',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          _iconButton(Icons.refresh_rounded, () => setState(() {})),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _showMatchTools,
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text(
              'Match Controls',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveOverview(bool isDesktop) {
    final liveMatches = _matches
        .where((match) => match['status'] == 'Live')
        .toList();

    if (!isDesktop) {
      return SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: liveMatches.length,
          separatorBuilder: (_, _) => const SizedBox(width: 13),
          itemBuilder: (_, index) {
            return SizedBox(
              width: 310,
              child: _liveMatchCard(liveMatches[index]),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'LIVE NOW',
                style: TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${liveMatches.length} active games',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filter = 'Live';
                  });
                },
                style: TextButton.styleFrom(foregroundColor: blue),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text(
                  'View all live',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: liveMatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 13),
              itemBuilder: (_, index) {
                return SizedBox(
                  width: 320,
                  child: _liveMatchCard(liveMatches[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveMatchCard(Map<String, dynamic> match) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: green, size: 6),
                    SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 20,
                        color: green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '#${match['id']}',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _livePlayer(
                  match['white'],
                  match['whiteRating'],
                  match['whiteTime'],
                  true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    color: muted.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: _livePlayer(
                  match['black'],
                  match['blackRating'],
                  match['blackTime'],
                  false,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _miniInfo(Icons.swap_vert_rounded, '${match['moves']} moves'),
              const SizedBox(width: 7),
              _miniInfo(Icons.visibility_outlined, '${match['spectators']}'),
              const Spacer(),
              InkWell(
                onTap: () => _showMatchDetails(match),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, color: blue, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 20,
                          color: blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _livePlayer(String name, int rating, String time, bool whiteSide) {
    return Column(
      crossAxisAlignment: whiteSide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            color: white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$rating',
          style: TextStyle(fontSize: 20, color: muted.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: TextStyle(
            fontSize: 20,
            color: time.startsWith('00:') ? danger : white,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 11),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: muted.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDesktop) {
    final cards = [
      _StatData(
        'Total Matches',
        '${_matches.length}',
        Icons.sports_esports_rounded,
        blue,
      ),
      _StatData(
        'Live',
        '${_countStatus('Live')}',
        Icons.sensors_rounded,
        green,
      ),
      _StatData(
        'Ready',
        '${_countStatus('Ready')}',
        Icons.play_circle_outline_rounded,
        gold,
      ),
      _StatData(
        'Spectators',
        '$_totalSpectators',
        Icons.visibility_outlined,
        purple,
      ),
      _StatData(
        'Moves Recorded',
        '$_totalMoves',
        Icons.swap_vert_rounded,
        muted,
      ),
    ];

    if (!isDesktop) {
      return SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            return SizedBox(width: 180, child: _statCard(cards[index]));
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 118,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) => _statCard(cards[index]),
    );
  }

  Widget _statCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(stat.icon, color: stat.color, size: 21),
          ),
          const SizedBox(width: 12),
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
      padding: EdgeInsets.all(isDesktop ? 15 : 13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _searchField()),
                const SizedBox(width: 13),
                SizedBox(width: 190, child: _competitionFilter()),
                const SizedBox(width: 13),
                _filterButtons(),
              ],
            )
          : Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                _competitionFilter(),
                const SizedBox(height: 12),
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
          hintText: 'Search players or match IDs...',
          hintStyle: TextStyle(
            fontSize: 20,
            color: muted.withValues(alpha: 0.7),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 20),
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: blue.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }

  Widget _competitionFilter() {
    return SizedBox(
      height: 46,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCompetition,
        dropdownColor: surfaceLight,
        style: const TextStyle(
          fontSize: 20,
          color: white,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.emoji_events_outlined,
            color: muted,
            size: 18,
          ),
          filled: true,
          fillColor: surfaceLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
        ),
        items: _competitions
            .map(
              (competition) => DropdownMenuItem<String>(
                value: competition,
                child: Text(competition, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _selectedCompetition = value;
          });
        },
      ),
    );
  }

  Widget _filterButtons() {
    const filters = ['All', 'Live', 'Ready', 'Paused', 'Completed', 'Aborted'];

    return Row(
      children: filters.map((filter) {
        final selected = _filter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 7),
          child: InkWell(
            onTap: () {
              setState(() {
                _filter = filter;
              });
            },
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? blue.withValues(alpha: 0.15) : surfaceLight,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? blue.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.045),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 20,
                  color: selected ? blue : muted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 235, child: Text('MATCH')),
                SizedBox(width: 115, child: Text('STATUS')),
                SizedBox(width: 130, child: Text('CLOCK')),
                SizedBox(width: 80, child: Text('MOVES')),
                SizedBox(width: 105, child: Text('SPECTATORS')),
                SizedBox(width: 100, child: Text('RESULT')),
                Expanded(child: Text('ACTION')),
              ],
            ),
          ),
          ..._filteredMatches.map(_desktopRow),
        ],
      ),
    );
  }

  Widget _desktopRow(Map<String, dynamic> match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 235,
            child: Row(
              children: [
                _boardNumber(match['board']),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              match['id'],
                              style: const TextStyle(
                                fontSize: 20,
                                color: white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (match['status'] == 'Live')
                            const Icon(Icons.circle, color: green, size: 6),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${match['white']} vs ${match['black']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          color: muted.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 115, child: _statusBadge(match['status'])),
          SizedBox(
            width: 130,
            child: Row(
              children: [
                _clockText(match['whiteTime'], true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '/',
                    style: TextStyle(fontSize: 20, color: muted),
                  ),
                ),
                _clockText(match['blackTime'], false),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              '${match['moves']}',
              style: const TextStyle(
                fontSize: 20,
                color: white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 105,
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: muted, size: 14),
                const SizedBox(width: 5),
                Text(
                  '${match['spectators']}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              match['result'],
              style: TextStyle(
                fontSize: 20,
                color: match['result'] == '-' ? muted : white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _actionButton(match),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardNumber(int board) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$board',
          style: const TextStyle(
            fontSize: 20,
            color: blue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _clockText(String time, bool isWhite) {
    final isCritical = time.startsWith('00:');

    return Text(
      time,
      style: TextStyle(
        fontSize: 20,
        color: isCritical
            ? danger
            : isWhite
            ? white
            : muted,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _filteredMatches
          .map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _mobileCard(match),
            ),
          )
          .toList(),
    );
  }

  Widget _mobileCard(Map<String, dynamic> match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _boardNumber(match['board']),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match['id'],
                      style: const TextStyle(
                        fontSize: 20,
                        color: white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${match['competition']} | ${match['round']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        color: muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(match['status']),
            ],
          ),
          const SizedBox(height: 16),
          _mobilePlayer(
            match['white'],
            match['whiteUsername'],
            match['whiteRating'],
            match['whiteTime'],
            true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.05)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 20,
                      color: muted.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ],
            ),
          ),
          _mobilePlayer(
            match['black'],
            match['blackUsername'],
            match['blackRating'],
            match['blackTime'],
            false,
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _mobileInfo(Icons.swap_vert_rounded, '${match['moves']} moves'),
              _mobileInfo(
                Icons.visibility_outlined,
                '${match['spectators']} watching',
              ),
              _mobileInfo(Icons.timer_outlined, match['timeControl']),
              _mobileInfo(Icons.flag_outlined, match['result']),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMatchDetails(match),
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
              Expanded(child: _mobileAction(match)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobilePlayer(
    String name,
    String username,
    int rating,
    String time,
    bool whiteSide,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: whiteSide
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: whiteSide ? white : muted,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$username | $rating',
                  style: TextStyle(
                    fontSize: 20,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 20,
              color: time.startsWith('00:') ? danger : white,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: muted, size: 12),
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

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Live':
        color = green;
        break;
      case 'Ready':
        color = gold;
        break;
      case 'Paused':
        color = purple;
        break;
      case 'Completed':
        color = muted;
        break;
      case 'Aborted':
        color = danger;
        break;
      default:
        color = blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
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

  Widget _actionButton(Map<String, dynamic> match) {
    final status = match['status'];

    String label;
    IconData icon;

    switch (status) {
      case 'Live':
        label = 'Monitor';
        icon = Icons.monitor_heart_outlined;
        break;
      case 'Completed':
        label = 'Review';
        icon = Icons.replay_rounded;
        break;
      case 'Paused':
        label = 'Resume';
        icon = Icons.play_arrow_rounded;
        break;
      case 'Aborted':
        label = 'Details';
        icon = Icons.info_outline_rounded;
        break;
      default:
        label = 'Manage';
        icon = Icons.tune_rounded;
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _handleMatchAction(match),
        style: ElevatedButton.styleFrom(
          backgroundColor: blue.withValues(alpha: 0.12),
          foregroundColor: blue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(color: blue.withValues(alpha: 0.17)),
          ),
        ),
        icon: Icon(icon, size: 15),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _mobileAction(Map<String, dynamic> match) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: () => _handleMatchAction(match),
        style: ElevatedButton.styleFrom(
          backgroundColor: blue.withValues(alpha: 0.13),
          foregroundColor: blue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: const Icon(Icons.tune_rounded, size: 17),
        label: const Text(
          'Manage Match',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 65),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_esports_outlined,
              color: blue,
              size: 31,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'No matches found',
            style: TextStyle(
              fontSize: 20,
              color: white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Try changing your search, competition or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: muted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMatchAction(Map<String, dynamic> match) {
    if (match['status'] == 'Paused') {
      setState(() {
        match['status'] = 'Live';
      });

      _showInfo('${match['id']} resumed.');
      return;
    }

    _showMatchDetails(match);
  }

  void _showMatchDetails(Map<String, dynamic> match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _MatchDetailsSheet(
          match: match,
          onPause: () {
            Navigator.pop(context);
            _pauseMatch(match);
          },
          onEnd: () {
            Navigator.pop(context);
            _confirmEndMatch(match);
          },
          onResult: () {
            Navigator.pop(context);
            _confirmSetResult(match);
          },
        );
      },
    );
  }

  void _pauseMatch(Map<String, dynamic> match) {
    if (match['status'] != 'Live') {
      _showInfo('Only live matches can be paused.');
      return;
    }

    setState(() {
      match['status'] = 'Paused';
    });

    _showInfo('${match['id']} has been paused.');
  }

  void _confirmEndMatch(Map<String, dynamic> match) {
    _showInfo(
      'Ending matches requires a verified server-side admin operation. No changes were made.',
    );
  }

  void _confirmSetResult(Map<String, dynamic> match) {
    _showInfo(
      'Setting a match result requires a verified server-side admin operation. No changes were made.',
    );
  }

  void _showMatchTools() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 25),
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Match Controls',
                    style: TextStyle(
                      fontSize: 20,
                      color: white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _toolTile(
                  Icons.pause_circle_outline_rounded,
                  'Pause All Live Matches',
                  'Temporarily pause every active board.',
                  () {
                    Navigator.pop(context);

                    setState(() {
                      for (final match in _matches) {
                        if (match['status'] == 'Live') {
                          match['status'] = 'Paused';
                        }
                      }
                    });

                    _showInfo('All live matches paused.');
                  },
                ),
                _toolTile(
                  Icons.play_circle_outline_rounded,
                  'Resume Paused Matches',
                  'Resume all paused boards.',
                  () {
                    Navigator.pop(context);

                    setState(() {
                      for (final match in _matches) {
                        if (match['status'] == 'Paused') {
                          match['status'] = 'Live';
                        }
                      }
                    });

                    _showInfo('Paused matches resumed.');
                  },
                ),
                _toolTile(
                  Icons.visibility_outlined,
                  'Spectator Controls',
                  'Manage public viewing access.',
                  () {
                    Navigator.pop(context);
                    _showInfo(
                      'Spectator controls will connect to realtime later.',
                    );
                  },
                ),
                _toolTile(
                  Icons.security_rounded,
                  'Emergency Controls',
                  'Administrative match intervention tools.',
                  () {
                    Navigator.pop(context);
                    _showInfo(
                      'Emergency controls require a verified server-side operation.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _toolTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: blue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          color: white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 20, color: muted.withValues(alpha: 0.7)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: muted),
      onTap: onTap,
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

class _MatchDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback onPause;
  final VoidCallback onEnd;
  final VoidCallback onResult;

  const _MatchDetailsSheet({
    required this.match,
    required this.onPause,
    required this.onEnd,
    required this.onResult,
  });

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color danger = Color(0xFFFF5C70);
  static const Color white = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 27),
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      color: blue,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match['id'],
                          style: const TextStyle(
                            fontSize: 20,
                            color: white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${match['competition']} | ${match['round']}',
                          style: TextStyle(
                            fontSize: 20,
                            color: muted.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(match['status']),
                ],
              ),
              const SizedBox(height: 22),
              _playerCard(
                match['white'],
                match['whiteUsername'],
                match['whiteRating'],
                match['whiteTime'],
                true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 20,
                        color: muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              _playerCard(
                match['black'],
                match['blackUsername'],
                match['blackRating'],
                match['blackTime'],
                false,
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.swap_vert_rounded, 'Moves', '${match['moves']}'),
              _detailRow(
                Icons.visibility_outlined,
                'Spectators',
                '${match['spectators']}',
              ),
              _detailRow(
                Icons.timer_outlined,
                'Time Control',
                match['timeControl'],
              ),
              _detailRow(Icons.schedule_rounded, 'Started', match['started']),
              _detailRow(Icons.flag_outlined, 'Result', match['result']),
              const SizedBox(height: 20),
              const Text(
                'Admin Controls',
                style: TextStyle(
                  fontSize: 20,
                  color: white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (match['status'] == 'Live')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPause,
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
                        icon: const Icon(Icons.pause_rounded, size: 18),
                        label: const Text(
                          'Pause',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (match['status'] == 'Live') const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onResult,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text(
                        'Set Result',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onEnd,
                  style: TextButton.styleFrom(
                    foregroundColor: danger,
                    minimumSize: const Size(0, 45),
                  ),
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: const Text(
                    'End Match',
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

  Widget _playerCard(
    String name,
    String username,
    int rating,
    String time,
    bool whiteSide,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: whiteSide
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: whiteSide ? white : muted,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 20,
                    color: muted.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 20,
                  color: time.startsWith('00:') ? danger : white,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$rating rating',
                style: TextStyle(
                  fontSize: 20,
                  color: muted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                color: muted.withValues(alpha: 0.8),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              color: white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'Live'
        ? green
        : status == 'Completed'
        ? muted
        : status == 'Aborted'
        ? danger
        : blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 20,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
