import 'package:flutter/material.dart';

import 'game_review_screen.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);

  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _games = [
    {
      'opponent': 'Daniel Ade',
      'rating': 1301,
      'result': 'Victory',
      'ratingChange': '+18',
      'time': '10+5',
      'date': 'Sep 28, 2026',
      'timePlayed': '4:32 PM',
      'matchId': '#SQA-28491',
      'moves': 34,
    },
    {
      'opponent': 'Michael T',
      'rating': 1290,
      'result': 'Defeat',
      'ratingChange': '-11',
      'time': '10+5',
      'date': 'Sep 27, 2026',
      'timePlayed': '6:18 PM',
      'matchId': '#SQA-28372',
      'moves': 41,
    },
    {
      'opponent': 'Samuel K',
      'rating': 1272,
      'result': 'Victory',
      'ratingChange': '+16',
      'time': '10+5',
      'date': 'Sep 26, 2026',
      'timePlayed': '3:45 PM',
      'matchId': '#SQA-28211',
      'moves': 29,
    },
    {
      'opponent': 'Emmanuel A',
      'rating': 1318,
      'result': 'Draw',
      'ratingChange': '+2',
      'time': '15+10',
      'date': 'Sep 25, 2026',
      'timePlayed': '5:09 PM',
      'matchId': '#SQA-28094',
      'moves': 52,
    },
    {
      'opponent': 'David O',
      'rating': 1258,
      'result': 'Victory',
      'ratingChange': '+19',
      'time': '10+5',
      'date': 'Sep 24, 2026',
      'timePlayed': '7:22 PM',
      'matchId': '#SQA-27981',
      'moves': 37,
    },
    {
      'opponent': 'Joshua B',
      'rating': 1334,
      'result': 'Defeat',
      'ratingChange': '-14',
      'time': '10+5',
      'date': 'Sep 23, 2026',
      'timePlayed': '4:51 PM',
      'matchId': '#SQA-27842',
      'moves': 44,
    },
    {
      'opponent': 'Peter C',
      'rating': 1281,
      'result': 'Victory',
      'ratingChange': '+17',
      'time': '5+3',
      'date': 'Sep 22, 2026',
      'timePlayed': '2:16 PM',
      'matchId': '#SQA-27691',
      'moves': 31,
    },
    {
      'opponent': 'Tobi F',
      'rating': 1298,
      'result': 'Draw',
      'ratingChange': '+1',
      'time': '10+5',
      'date': 'Sep 21, 2026',
      'timePlayed': '6:42 PM',
      'matchId': '#SQA-27533',
      'moves': 46,
    },
  ];

  List<Map<String, dynamic>> get _filteredGames {
    return _games.where((game) {
      final resultMatches =
          _selectedFilter == 'All' || game['result'] == _selectedFilter;

      final opponent = game['opponent'].toString().toLowerCase();
      final matchId = game['matchId'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      final searchMatches =
          query.isEmpty || opponent.contains(query) || matchId.contains(query);

      return resultMatches && searchMatches;
    }).toList();
  }

  int get _wins => _games.where((game) => game['result'] == 'Victory').length;

  int get _losses => _games.where((game) => game['result'] == 'Defeat').length;

  int get _draws => _games.where((game) => game['result'] == 'Draw').length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;

    return Scaffold(
      backgroundColor: background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(context)
            : _buildMobileLayout(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: background,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match History',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your competitive journey',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _iconButton(icon: Icons.filter_list_rounded, onTap: _showFilterSheet),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1250),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            children: [
              _buildStats(),
              const SizedBox(height: 20),
              _buildSearchAndFilters(),
              const SizedBox(height: 16),
              Expanded(child: _buildGamesList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
      child: Column(
        children: [
          _buildStats(),
          const SizedBox(height: 18),
          _buildSearchAndFilters(),
          const SizedBox(height: 16),
          _buildGamesList(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Games',
                      value: '${_games.length}',
                      icon: Icons.sports_esports_rounded,
                      iconColor: blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      label: 'Wins',
                      value: '$_wins',
                      icon: Icons.emoji_events_rounded,
                      iconColor: green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      label: 'Losses',
                      value: '$_losses',
                      icon: Icons.trending_down_rounded,
                      iconColor: danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      label: 'Draws',
                      value: '$_draws',
                      icon: Icons.handshake_rounded,
                      iconColor: gold,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'Games',
                value: '${_games.length}',
                icon: Icons.sports_esports_rounded,
                iconColor: blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Wins',
                value: '$_wins',
                icon: Icons.emoji_events_rounded,
                iconColor: green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Losses',
                value: '$_losses',
                icon: Icons.trending_down_rounded,
                iconColor: danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Draws',
                value: '$_draws',
                icon: Icons.handshake_rounded,
                iconColor: gold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: surfaceLight),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13),
            cursorColor: blue,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, color: muted, size: 20),
              hintText: 'Search opponent or match ID...',
              hintStyle: TextStyle(color: muted, fontSize: 12),
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip('All'),
              const SizedBox(width: 8),
              _filterChip('Victory'),
              const SizedBox(width: 8),
              _filterChip('Defeat'),
              const SizedBox(width: 8),
              _filterChip('Draw'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String filter) {
    final selected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? blue : surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? blue : surfaceLight),
        ),
        child: Text(
          filter == 'Victory'
              ? 'Wins'
              : filter == 'Defeat'
              ? 'Losses'
              : filter,
          style: TextStyle(
            color: selected ? Colors.white : muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildGamesList() {
    final games = _filteredGames;

    if (games.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _gameCard(games[index]);
      },
    );
  }

  Widget _gameCard(Map<String, dynamic> game) {
    final result = game['result'] as String;
    final isVictory = result == 'Victory';
    final isDraw = result == 'Draw';

    final resultColor = isVictory
        ? green
        : isDraw
        ? gold
        : danger;

    final resultIcon = isVictory
        ? Icons.emoji_events_rounded
        : isDraw
        ? Icons.handshake_rounded
        : Icons.close_rounded;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openReview(game),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: surfaceLight),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;

              if (compact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _resultIcon(resultIcon, resultColor),
                        const SizedBox(width: 12),
                        Expanded(child: _opponentInfo(game)),
                        _ratingChange(game['ratingChange'], resultColor),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _compactGameMeta(game),
                  ],
                );
              }

              return Row(
                children: [
                  _resultIcon(resultIcon, resultColor),
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: _opponentInfo(game)),
                  Expanded(
                    child: _gameMeta(
                      icon: Icons.timer_outlined,
                      value: game['time'],
                      label: 'Time',
                    ),
                  ),
                  Expanded(
                    child: _gameMeta(
                      icon: Icons.swap_vert_rounded,
                      value: '${game['moves']}',
                      label: 'Moves',
                    ),
                  ),
                  Expanded(
                    child: _gameMeta(
                      icon: Icons.calendar_today_outlined,
                      value: game['date'],
                      label: game['timePlayed'],
                    ),
                  ),
                  _ratingChange(game['ratingChange'], resultColor),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: muted,
                    size: 20,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _resultIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _opponentInfo(Map<String, dynamic> game) {
    final result = game['result'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                game['opponent'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${game['rating']}',
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              result,
              style: TextStyle(
                color: result == 'Victory'
                    ? green
                    : result == 'Draw'
                    ? gold
                    : danger,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              game['matchId'],
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gameMeta({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: muted, size: 15),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _compactGameMeta(Map<String, dynamic> game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Expanded(child: _mobileMeta(Icons.timer_outlined, game['time'])),
          Expanded(
            child: _mobileMeta(
              Icons.swap_vert_rounded,
              '${game['moves']} moves',
            ),
          ),
          Expanded(
            child: _mobileMeta(Icons.calendar_today_outlined, game['date']),
          ),
          const Icon(Icons.chevron_right_rounded, color: muted, size: 18),
        ],
      ),
    );
  }

  Widget _mobileMeta(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: muted, size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ratingChange(dynamic change, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        change.toString(),
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: surfaceLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: blue, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'No games found',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another filter or search term.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openReview(Map<String, dynamic> game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameReviewScreen(
          opponentName: game['opponent'],
          opponentRating: game['rating'],
          result: game['result'],
          matchId: game['matchId'],
          timeControl: game['time'],
          date: '${game['date']} • ${game['timePlayed']}',
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter Games',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...['All', 'Victory', 'Defeat', 'Draw'].map((filter) {
                  final selected = _selectedFilter == filter;

                  return ListTile(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      Navigator.pop(context);
                    },
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      filter == 'Victory'
                          ? Icons.emoji_events_rounded
                          : filter == 'Defeat'
                          ? Icons.close_rounded
                          : filter == 'Draw'
                          ? Icons.handshake_rounded
                          : Icons.grid_view_rounded,
                      color: selected ? blue : muted,
                    ),
                    title: Text(
                      filter == 'Victory'
                          ? 'Wins'
                          : filter == 'Defeat'
                          ? 'Losses'
                          : filter,
                      style: TextStyle(
                        color: selected ? blue : muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: blue,
                            size: 20,
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: blue, size: 19),
        ),
      ),
    );
  }
}
