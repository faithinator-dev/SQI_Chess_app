import 'package:flutter/material.dart';

class AdminRecordingsScreen extends StatefulWidget {
  const AdminRecordingsScreen({super.key});

  @override
  State<AdminRecordingsScreen> createState() => _AdminRecordingsScreenState();
}

class _AdminRecordingsScreenState extends State<AdminRecordingsScreen> {
  // ============================================================
  // COLORS
  // ============================================================

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

  // ============================================================
  // STATE
  // ============================================================

  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedCompetition = 'All Competitions';

  final List<String> _filters = ['All', 'Live', 'Completed', 'Archived'];

  final List<String> _competitions = [];

  // ============================================================
  // MOCK RECORDINGS
  // ============================================================

  final List<Map<String, dynamic>> _recordings = [];

  // ============================================================
  // FILTERED RECORDINGS
  // ============================================================

  List<Map<String, dynamic>> get _filteredRecordings {
    return _recordings.where((recording) {
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          recording['id'].toString().toLowerCase().contains(query) ||
          recording['matchId'].toString().toLowerCase().contains(query) ||
          recording['white'].toString().toLowerCase().contains(query) ||
          recording['black'].toString().toLowerCase().contains(query) ||
          recording['competition'].toString().toLowerCase().contains(query);

      final matchesFilter =
          _selectedFilter == 'All' || recording['status'] == _selectedFilter;

      final matchesCompetition =
          _selectedCompetition == 'All Competitions' ||
          recording['competition'] == _selectedCompetition;

      return matchesSearch && matchesFilter && matchesCompetition;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;
    final isTablet = width >= 650 && width < 1000;

    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(isDesktop),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? 32
                : isTablet
                ? 24
                : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop),
                  const SizedBox(height: 24),
                  _buildSummaryGrid(isDesktop, isTablet),
                  const SizedBox(height: 28),
                  _buildStorageCard(isDesktop),
                  const SizedBox(height: 28),
                  _buildToolbar(isDesktop),
                  const SizedBox(height: 20),
                  if (isDesktop)
                    _buildDesktopTable()
                  else
                    _buildMobileRecordings(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: isDesktop ? 32 : 16,
      title: Row(
        children: [
          if (!isDesktop)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: white),
            ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: blue.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.video_library_rounded,
              color: blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Recordings',
            style: TextStyle(
              color: white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              children: [
                _topAction(
                  Icons.download_rounded,
                  'Export',
                  onTap: _exportRecordings,
                ),
                const SizedBox(width: 10),
                _topAction(
                  Icons.settings_rounded,
                  'Settings',
                  onTap: _recordingSettings,
                ),
              ],
            ),
          )
        else
          IconButton(
            onPressed: _recordingSettings,
            icon: const Icon(Icons.settings_rounded, color: muted),
          ),
      ],
    );
  }

  Widget _topAction(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Recordings',
                style: TextStyle(
                  color: white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Review, manage and archive recorded chess games.',
                style: TextStyle(
                  color: muted.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: _exportRecordings,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export Recordings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryGrid(bool isDesktop, bool isTablet) {
    final cards = [
      {
        'title': 'Total Recordings',
        'value': '—',
        'subtitle': 'Backend data unavailable',
        'icon': Icons.video_library_rounded,
        'color': blue,
      },
      {
        'title': 'Live Recording',
        'value': '—',
        'subtitle': 'Backend data unavailable',
        'icon': Icons.fiber_manual_record_rounded,
        'color': danger,
      },
      {
        'title': 'Completed',
        'value': '—',
        'subtitle': 'Backend data unavailable',
        'icon': Icons.check_circle_rounded,
        'color': green,
      },
      {
        'title': 'Storage Used',
        'value': '—',
        'subtitle': 'Storage usage unavailable',
        'icon': Icons.cloud_rounded,
        'color': purple,
      },
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((card) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _summaryCard(card),
            ),
          );
        }).toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 2.25 : 1.45,
      ),
      itemBuilder: (_, index) {
        return _summaryCard(cards[index]);
      },
    );
  }

  Widget _summaryCard(Map<String, dynamic> card) {
    final color = card['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card['icon'] as IconData, color: color, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                color: muted.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            card['title'],
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            card['value'],
            style: const TextStyle(
              color: white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card['subtitle'],
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STORAGE
  // ============================================================

  Widget _buildStorageCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: isDesktop
          ? Row(
              children: [
                _storageIcon(),
                const SizedBox(width: 16),
                Expanded(child: _storageInfo()),
                const SizedBox(width: 24),
                SizedBox(width: 260, child: _storageProgress()),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    _storageIcon(),
                    const SizedBox(width: 14),
                    Expanded(child: _storageInfo()),
                  ],
                ),
                const SizedBox(height: 18),
                _storageProgress(),
              ],
            ),
    );
  }

  Widget _storageIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.cloud_done_rounded, color: purple, size: 23),
    );
  }

  Widget _storageInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recording Storage',
          style: TextStyle(
            color: white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your recorded games are securely stored and available for review.',
          style: TextStyle(color: muted.withValues(alpha: 0.85), fontSize: 12),
        ),
      ],
    );
  }

  Widget _storageProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            const Text(
              '—',
              style: TextStyle(
                color: white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Text(
              'Usage unavailable',
              style: TextStyle(color: muted, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: 0.336,
            minHeight: 7,
            backgroundColor: surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(purple),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '33.6% used',
          style: TextStyle(
            color: purple,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _buildToolbar(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _searchField()),
          const SizedBox(width: 12),
          _competitionDropdown(),
          const SizedBox(width: 12),
          _filterDropdown(),
        ],
      );
    }

    return Column(
      children: [
        _searchField(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _competitionDropdown()),
            const SizedBox(width: 10),
            Expanded(child: _filterDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search recordings, players or match ID...',
          hintStyle: TextStyle(
            color: muted.withValues(alpha: 0.65),
            fontSize: 12,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded, color: muted, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _competitionDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCompetition,
          dropdownColor: surfaceLight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: muted),
          style: const TextStyle(
            color: white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: _competitions.map((competition) {
            return DropdownMenuItem(
              value: competition,
              child: Text(competition, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedCompetition = value;
            });
          },
        ),
      ),
    );
  }

  Widget _filterDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          dropdownColor: surfaceLight,
          icon: const Icon(Icons.filter_list_rounded, color: muted, size: 19),
          style: const TextStyle(
            color: white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: _filters.map((filter) {
            return DropdownMenuItem(value: filter, child: Text(filter));
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    final recordings = _filteredRecordings;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          _tableHeader(),
          if (recordings.isEmpty)
            _emptyState()
          else
            ...recordings.map((recording) => _recordingTableRow(recording)),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: surfaceLight.withValues(alpha: 0.45),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'RECORDING',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'PLAYERS',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'COMPETITION',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'MOVES',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'SIZE',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'ACTION',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordingTableRow(Map<String, dynamic> recording) {
    final statusColor = _statusColor(recording['status']);

    return InkWell(
      onTap: () => _showRecordingDetails(recording),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _recordingIcon(recording),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording['id'],
                          style: const TextStyle(
                            color: white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recording['matchId'],
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 3, child: _playersCell(recording)),
            Expanded(
              flex: 2,
              child: Text(
                recording['competition'],
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: _statusBadge(recording['status'], statusColor),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${recording['moves']}',
                style: const TextStyle(
                  color: white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                recording['size'],
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
            SizedBox(
              width: 60,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: muted,
                  size: 19,
                ),
                color: surfaceLight,
                onSelected: (value) {
                  _handleRecordingAction(value, recording);
                },
                itemBuilder: (_) => [
                  _menuItem('view', Icons.visibility_rounded, 'View'),
                  _menuItem('download', Icons.download_rounded, 'Download'),
                  _menuItem('archive', Icons.archive_rounded, 'Archive'),
                  _menuItem('delete', Icons.delete_outline_rounded, 'Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileRecordings() {
    final recordings = _filteredRecordings;

    if (recordings.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: recordings.map((recording) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _mobileRecordingCard(recording),
        );
      }).toList(),
    );
  }

  Widget _mobileRecordingCard(Map<String, dynamic> recording) {
    final statusColor = _statusColor(recording['status']);

    return InkWell(
      onTap: () => _showRecordingDetails(recording),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.055)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _recordingIcon(recording),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording['id'],
                        style: const TextStyle(
                          color: white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recording['matchId'],
                        style: const TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _statusBadge(recording['status'], statusColor),
              ],
            ),
            const SizedBox(height: 16),
            _mobilePlayerRow(recording),
            const SizedBox(height: 15),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniInfo(
                  Icons.swap_horiz_rounded,
                  '${recording['moves']} moves',
                ),
                const SizedBox(width: 16),
                _miniInfo(Icons.timer_outlined, recording['duration']),
                const SizedBox(width: 16),
                _miniInfo(
                  Icons.visibility_outlined,
                  '${recording['spectators']}',
                ),
                const Spacer(),
                Text(
                  recording['size'],
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobilePlayerRow(Map<String, dynamic> recording) {
    return Row(
      children: [
        Expanded(
          child: _playerCompact(
            recording['white'],
            recording['whiteRating'],
            true,
          ),
        ),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceLight,
            shape: BoxShape.circle,
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _playerCompact(
            recording['black'],
            recording['blackRating'],
            false,
          ),
        ),
      ],
    );
  }

  Widget _playerCompact(String name, int rating, bool whitePlayer) {
    return Row(
      children: [
        if (!whitePlayer) const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: whitePlayer ? Colors.white : const Color(0xFF252E40),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: whitePlayer
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            color: whitePlayer ? background : muted,
            size: 17,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: whitePlayer
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$rating',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: muted, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // COMMON CELLS
  // ============================================================

  Widget _recordingIcon(Map<String, dynamic> recording) {
    final isLive = recording['status'] == 'Live';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isLive
            ? danger.withValues(alpha: 0.12)
            : blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        isLive
            ? Icons.fiber_manual_record_rounded
            : Icons.play_circle_outline_rounded,
        color: isLive ? danger : blue,
        size: 19,
      ),
    );
  }

  Widget _playersCell(Map<String, dynamic> recording) {
    return Row(
      children: [
        _avatar(recording['white'], true),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recording['white'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${recording['whiteRating']}  Ã¢â‚¬Â¢  White',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'vs',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recording['black'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${recording['blackRating']}  Ã¢â‚¬Â¢  Black',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(String name, bool isWhite) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : const Color(0xFF252E40),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: isWhite ? background : white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'Live')
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Live':
        return danger;
      case 'Completed':
        return green;
      case 'Archived':
        return muted;
      default:
        return blue;
    }
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: muted,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No recordings found',
            style: TextStyle(
              color: white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try changing your search or filters.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: muted, size: 17),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: white, fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showRecordingDetails(Map<String, dynamic> recording) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: SafeArea(
            child: SingleChildScrollView(
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
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _recordingIcon(recording),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording['id'],
                              style: const TextStyle(
                                color: white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recording['matchId'],
                              style: const TextStyle(
                                color: muted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(
                        recording['status'],
                        _statusColor(recording['status']),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _detailPlayers(recording),
                  const SizedBox(height: 22),
                  _detailGrid(recording),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _detailAction(
                          icon: Icons.play_arrow_rounded,
                          label: 'Review Game',
                          color: blue,
                          onTap: () {
                            Navigator.pop(context);
                            _showSnackBar('Game review opened.');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _detailAction(
                          icon: Icons.download_rounded,
                          label: 'Download',
                          color: green,
                          onTap: () {
                            Navigator.pop(context);
                            _downloadRecording(recording);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _detailAction(
                          icon: Icons.archive_rounded,
                          label: 'Archive',
                          color: gold,
                          onTap: () {
                            Navigator.pop(context);
                            _archiveRecording(recording);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _detailAction(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: danger,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete(recording);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailPlayers(Map<String, dynamic> recording) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _detailPlayer(
              recording['white'],
              recording['whiteRating'],
              true,
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'VS',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: _detailPlayer(
              recording['black'],
              recording['blackRating'],
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPlayer(String name, int rating, bool isWhite) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isWhite ? Colors.white : const Color(0xFF252E40),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.person_rounded,
            color: isWhite ? background : muted,
            size: 24,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$rating Ã¢â‚¬Â¢ ${isWhite ? 'White' : 'Black'}',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _detailGrid(Map<String, dynamic> recording) {
    final details = [
      ['Competition', recording['competition']],
      ['Board', recording['board']],
      ['Result', recording['result']],
      ['Moves', '${recording['moves']}'],
      ['Duration', recording['duration']],
      ['Spectators', '${recording['spectators']}'],
      ['Date', recording['date']],
      ['Time', recording['time']],
      ['Format', recording['format']],
      ['File Size', recording['size']],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 20,
        childAspectRatio: 3.4,
      ),
      itemBuilder: (_, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details[index][0],
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              details[index][1],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _handleRecordingAction(String action, Map<String, dynamic> recording) {
    switch (action) {
      case 'view':
        _showRecordingDetails(recording);
        break;

      case 'download':
        _downloadRecording(recording);
        break;

      case 'archive':
        _archiveRecording(recording);
        break;

      case 'delete':
        _confirmDelete(recording);
        break;
    }
  }

  void _downloadRecording(Map<String, dynamic> recording) {
    _showSnackBar('Preparing ${recording['id']} for download...');
  }

  void _archiveRecording(Map<String, dynamic> recording) {
    _showSnackBar('${recording['id']} archived.');
  }

  void _confirmDelete(Map<String, dynamic> recording) {
    _showSnackBar(
      'Recording deletion is unavailable until a verified admin operation is configured.',
    );
  }

  void _exportRecordings() {
    _showSnackBar('Exporting ${_filteredRecordings.length} recordings...');
  }

  void _recordingSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.all(22),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recording Settings',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _settingTile(
                  Icons.videocam_rounded,
                  'Auto-record matches',
                  'Record every competitive match automatically.',
                  true,
                ),
                _settingTile(
                  Icons.cloud_upload_rounded,
                  'Cloud backup',
                  'Automatically back up completed games.',
                  true,
                ),
                _settingTile(
                  Icons.public_rounded,
                  'Public recordings',
                  'Allow spectators to review completed games.',
                  true,
                ),
                _settingTile(
                  Icons.archive_rounded,
                  'Auto-archive',
                  'Archive recordings after 30 days.',
                  false,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _settingTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: blue, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: const TextStyle(color: muted, fontSize: 14),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: (_) {},
        activeThumbColor: blue,
        activeTrackColor: blue.withValues(alpha: 0.35),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: surfaceLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
