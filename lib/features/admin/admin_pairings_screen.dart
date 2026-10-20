// lib/features/admin/admin_pairings_screen.dart

import 'package:flutter/material.dart';

class AdminPairingsScreen extends StatefulWidget {
  const AdminPairingsScreen({super.key});

  @override
  State<AdminPairingsScreen> createState() => _AdminPairingsScreenState();
}

class _AdminPairingsScreenState extends State<AdminPairingsScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color white = Color(0xFF1A1A1A);
  static const Color purple = Color(0xFF9B7BFF);

  String _selectedCompetition = 'No competitions';
  String _selectedRound = 'Round 1';
  String _filter = 'All';
  String _search = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _competitions = [];

  final List<String> _rounds = [
    'Round 1',
    'Round 2',
    'Round 3',
    'Round 4',
    'Round 5',
    'Round 6',
    'Round 7',
  ];

  final List<Map<String, dynamic>> _pairings = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPairings {
    return _pairings.where((pairing) {
      final statusMatch = _filter == 'All' || pairing['status'] == _filter;

      final query = _search.trim().toLowerCase();

      final searchMatch =
          query.isEmpty ||
          pairing['matchId'].toString().toLowerCase().contains(query) ||
          pairing['white'].toString().toLowerCase().contains(query) ||
          pairing['black'].toString().toLowerCase().contains(query) ||
          pairing['whiteUsername'].toString().toLowerCase().contains(query) ||
          pairing['blackUsername'].toString().toLowerCase().contains(query);

      return statusMatch && searchMatch;
    }).toList();
  }

  int get _total => _pairings.length;

  int get _live =>
      _pairings.where((pairing) => pairing['status'] == 'Live').length;

  int get _ready =>
      _pairings.where((pairing) => pairing['status'] == 'Ready').length;

  int get _waiting =>
      _pairings.where((pairing) => pairing['status'] == 'Waiting').length;

  int get _completed =>
      _pairings.where((pairing) => pairing['status'] == 'Completed').length;

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
                  _buildCompetitionSelector(isDesktop),
                  const SizedBox(height: 18),
                  _buildStats(isDesktop),
                  const SizedBox(height: 24),
                  _buildToolbar(isDesktop),
                  const SizedBox(height: 18),
                  _buildPairingNotice(),
                  const SizedBox(height: 18),
                  if (_filteredPairings.isEmpty)
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
                'Pairings',
                style: TextStyle(
                  color: white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Control matchmaking, boards and manual pairings.',
                style: TextStyle(
                  color: muted.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          _iconButton(Icons.refresh_rounded, () => setState(() {})),
          const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _buildCompetitionSelector(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: isDesktop
          ? Row(
              children: [
                _competitionIcon(),
                const SizedBox(width: 13),
                Expanded(child: _competitionDropdown()),
                const SizedBox(width: 18),
                SizedBox(width: 170, child: _roundDropdown()),
                const SizedBox(width: 12),
                _autoMatchButton(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _competitionIcon(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Competition',
                        style: TextStyle(
                          color: white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _autoMatchButton(),
                  ],
                ),
                const SizedBox(height: 13),
                _competitionDropdown(),
                const SizedBox(height: 10),
                _roundDropdown(),
              ],
            ),
    );
  }

  Widget _competitionIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(Icons.emoji_events_rounded, color: blue, size: 22),
    );
  }

  Widget _competitionDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCompetition,
      dropdownColor: surfaceLight,
      style: const TextStyle(
        color: white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: 'Competition',
        labelStyle: TextStyle(
          color: muted.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      ),
      items: _competitions
          .map(
            (competition) => DropdownMenuItem<String>(
              value: competition,
              child: Text(competition),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedCompetition = value;
        });
      },
    );
  }

  Widget _roundDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRound,
      dropdownColor: surfaceLight,
      style: const TextStyle(
        color: white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: 'Round',
        labelStyle: TextStyle(
          color: muted.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
      ),
      items: _rounds
          .map(
            (round) =>
                DropdownMenuItem<String>(value: round, child: Text(round)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedRound = value;
        });
      },
    );
  }

  Widget _autoMatchButton() {
    return Tooltip(
      message: 'Automatic matchmaking is enabled',
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: green.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
              'Auto Match',
              style: TextStyle(
                color: green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Switch(
              value: true,
              onChanged: (_) {
                _showInfo(
                  'Auto matchmaking toggle will be connected to Supabase later.',
                );
              },
              activeThumbColor: green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(bool isDesktop) {
    final cards = [
      _StatData('Total Pairings', '$_total', Icons.account_tree_rounded, blue),
      _StatData('Live', '$_live', Icons.sensors_rounded, green),
      _StatData('Ready', '$_ready', Icons.play_circle_outline_rounded, gold),
      _StatData('Waiting', '$_waiting', Icons.hourglass_empty_rounded, purple),
      _StatData(
        'Completed',
        '$_completed',
        Icons.check_circle_outline_rounded,
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
                  style: const TextStyle(
                    color: white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.85),
                    fontSize: 14,
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
                const SizedBox(width: 15),
                _filterButtons(),
              ],
            )
          : Column(
              children: [
                _searchField(),
                const SizedBox(height: 13),
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
        style: const TextStyle(color: white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search players or match IDs...',
          hintStyle: TextStyle(
            color: muted.withValues(alpha: 0.7),
            fontSize: 13,
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

  Widget _filterButtons() {
    const filters = ['All', 'Live', 'Ready', 'Waiting', 'Completed'];

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
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
                  color: selected ? blue : muted,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPairingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: blue.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: blue,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '$_selectedCompetition Ã¢â‚¬Â¢ $_selectedRound Ã¢â‚¬â€ '
              'No pairings are available. Pairing generation requires a verified server-side operation.',
              style: TextStyle(
                color: muted.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 15),
            decoration: BoxDecoration(
              color: surfaceLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 70, child: Text('BOARD')),
                SizedBox(width: 270, child: Text('PLAYERS')),
                SizedBox(width: 110, child: Text('STATUS')),
                SizedBox(width: 100, child: Text('RESULT')),
                SizedBox(width: 100, child: Text('CLOCK')),
                SizedBox(width: 95, child: Text('MODE')),
                Expanded(child: Text('ACTION')),
              ],
            ),
          ),
          ..._filteredPairings.map(_desktopRow),
        ],
      ),
    );
  }

  Widget _desktopRow(Map<String, dynamic> pairing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Text(
                  '${pairing['board']}',
                  style: const TextStyle(
                    color: blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 270, child: _playerPair(pairing, compact: true)),
          SizedBox(width: 110, child: _statusBadge(pairing['status'])),
          SizedBox(
            width: 100,
            child: Text(
              pairing['result'],
              style: const TextStyle(
                color: white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              pairing['time'],
              style: TextStyle(
                color: pairing['status'] == 'Live' ? green : muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 95, child: _modeBadge(pairing['mode'])),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _actionButton(pairing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerPair(Map<String, dynamic> pairing, {bool compact = false}) {
    return Row(
      children: [
        Expanded(
          child: _miniPlayer(pairing['white'], pairing['whiteRating'], true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'VS',
            style: TextStyle(
              color: muted.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _miniPlayer(pairing['black'], pairing['blackRating'], false),
        ),
      ],
    );
  }

  Widget _miniPlayer(String name, int rating, bool whiteSide) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: whiteSide
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Icon(
            Icons.person_rounded,
            color: whiteSide ? white : muted,
            size: 14,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$rating',
                style: TextStyle(
                  color: muted.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: _filteredPairings
          .map(
            (pairing) => Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _mobileCard(pairing),
            ),
          )
          .toList(),
    );
  }

  Widget _mobileCard(Map<String, dynamic> pairing) {
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${pairing['board']}',
                    style: const TextStyle(
                      color: blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Board ${pairing['board']}',
                      style: const TextStyle(
                        color: white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pairing['matchId'],
                      style: TextStyle(
                        color: muted.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(pairing['status']),
            ],
          ),
          const SizedBox(height: 18),
          _largePlayer(
            pairing['white'],
            pairing['whiteUsername'],
            pairing['whiteRating'],
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
                      color: muted.withValues(alpha: 0.5),
                      fontSize: 12,
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
          _largePlayer(
            pairing['black'],
            pairing['blackUsername'],
            pairing['blackRating'],
            false,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(Icons.timer_outlined, pairing['time']),
              _infoChip(Icons.flag_outlined, pairing['result']),
              _infoChip(Icons.auto_awesome_rounded, pairing['mode']),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPairingDetails(pairing),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(child: _mobileActionButton(pairing)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _largePlayer(
    String name,
    String username,
    int rating,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: whiteSide
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: whiteSide ? white : muted,
              size: 20,
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
                    color: white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$rating',
            style: const TextStyle(
              color: white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
      case 'Waiting':
        color = purple;
        break;
      case 'Completed':
        color = muted;
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
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBadge(String mode) {
    final isManual = mode == 'Manual';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: (isManual ? purple : blue).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        mode,
        style: TextStyle(
          color: isManual ? purple : blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
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
              color: white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(Map<String, dynamic> pairing) {
    final status = pairing['status'];

    String label;
    IconData icon;

    if (status == 'Live') {
      label = 'Monitor';
      icon = Icons.monitor_heart_outlined;
    } else if (status == 'Waiting') {
      label = 'Pair';
      icon = Icons.link_rounded;
    } else if (status == 'Completed') {
      label = 'Review';
      icon = Icons.replay_rounded;
    } else {
      label = 'Manage';
      icon = Icons.tune_rounded;
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _handlePairingAction(pairing),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _mobileActionButton(Map<String, dynamic> pairing) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: () => _handlePairingAction(pairing),
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
          'Manage',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
              Icons.account_tree_outlined,
              color: blue,
              size: 31,
            ),
          ),
          const SizedBox(height: 17),
          const Text(
            'No pairings found',
            style: TextStyle(
              color: white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(
              color: muted.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePairingAction(Map<String, dynamic> pairing) {
    final status = pairing['status'];

    if (status == 'Waiting') {
      _showManualPairDialog(existingPairing: pairing);
      return;
    }

    _showPairingDetails(pairing);
  }

  void _showPairingDetails(Map<String, dynamic> pairing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _PairingDetailsSheet(
          pairing: pairing,
          onReassign: () {
            Navigator.pop(context);
            _showManualPairDialog(existingPairing: pairing);
          },
          onRemove: () {
            Navigator.pop(context);
            _confirmRemovePairing(pairing);
          },
        );
      },
    );
  }

  void _showManualPairDialog({Map<String, dynamic>? existingPairing}) {
    _showInfo(
      'Pairing management is unavailable until a verified admin operation is configured.',
    );
  }

  void _confirmRemovePairing(Map<String, dynamic> pairing) {
    _showInfo(
      'Pairing removal is unavailable until a verified admin operation is configured.',
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

class _PairingDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> pairing;
  final VoidCallback onReassign;
  final VoidCallback onRemove;

  const _PairingDetailsSheet({
    required this.pairing,
    required this.onReassign,
    required this.onRemove,
  });

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color white = Color(0xFF1A1A1A);
  static const Color danger = Color(0xFFFF5C70);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 26),
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
                      Icons.account_tree_rounded,
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
                          'Board ${pairing['board']}',
                          style: const TextStyle(
                            color: white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pairing['matchId'],
                          style: TextStyle(
                            color: muted.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(pairing['status']),
                ],
              ),
              const SizedBox(height: 23),
              _playerCard(
                pairing['white'],
                pairing['whiteUsername'],
                pairing['whiteRating'],
                true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: muted.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              _playerCard(
                pairing['black'],
                pairing['blackUsername'],
                pairing['blackRating'],
                false,
              ),
              const SizedBox(height: 19),
              _detailRow(Icons.timer_outlined, 'Clock', pairing['time']),
              _detailRow(Icons.flag_outlined, 'Result', pairing['result']),
              _detailRow(
                Icons.auto_awesome_rounded,
                'Pairing Mode',
                pairing['mode'],
              ),
              _detailRow(
                Icons.emoji_events_outlined,
                'Competition',
                'Unavailable',
              ),
              _detailRow(Icons.layers_outlined, 'Round', 'Round 1'),
              const SizedBox(height: 21),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReassign,
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
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text(
                        'Reassign',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                              'Board monitoring requires a connected live-game service.',
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
                      icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                      label: const Text(
                        'Monitor',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: danger,
                    minimumSize: const Size(0, 45),
                  ),
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text(
                    'Remove Pairing',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerCard(String name, String username, int rating, bool whiteSide) {
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
                    color: white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'RATING',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$rating',
                style: const TextStyle(
                  color: white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
                color: muted.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: white,
              fontSize: 14,
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
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
