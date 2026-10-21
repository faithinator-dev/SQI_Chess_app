import 'package:flutter/material.dart';
import 'package:sqi_chess_club/features/matches/matches_screen.dart';
import 'package:sqi_chess_club/features/spectator/chess_spectator_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/community_post_model.dart';
import '../../core/models/lesson_model.dart';
import '../../core/models/notification_model.dart';
import '../../core/models/profile_model.dart';
import '../../core/repositories/community_repository.dart';
import '../../core/repositories/lesson_repository.dart';
import '../../core/repositories/notification_repository.dart';
import '../../core/repositories/profile_repository.dart';

import '../community/community_screen.dart';
import '../competitions/competitions_screen.dart';
import '../learn/learn_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const _HomeTab(),
    MatchesScreen(),
    const LearnScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.background,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _Colors.surface,
          border: const Border(
            top: BorderSide(color: Color(0xFFCCDEF0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: _Colors.blue.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, // Keeps all labels visible
          backgroundColor: _Colors.surface,
          elevation: 0,

          // Selection Styling
          selectedItemColor: _Colors.blue,
          unselectedItemColor: _Colors.textMuted,
          selectedLabelStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Play',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book_rounded),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ProfileRepository _profileRepository = ProfileRepository();

  final NotificationRepository _notificationRepository =
      NotificationRepository();

  final LessonRepository _lessonRepository = LessonRepository();

  final CommunityRepository _communityRepository = CommunityRepository();

  ProfileModel? _profile;

  List<NotificationModel> _notifications = [];
  List<LessonModel> _lessons = [];
  List<CommunityPostModel> _communityPosts = [];

  int _unreadNotificationCount = 0;

  bool _profileLoading = true;
  bool _learningLoading = true;
  bool _communityLoading = true;

  RealtimeChannel? _notificationChannel;
  RealtimeChannel? _communityChannel;

  @override
  void initState() {
    super.initState();

    _loadProfile();
    _loadNotifications();
    _loadLearning();
    _loadCommunity();

    _subscribeToNotifications();
    _subscribeToCommunity();
  }

  @override
  void dispose() {
    final notificationChannel = _notificationChannel;
    final communityChannel = _communityChannel;

    if (notificationChannel != null) {
      _notificationRepository.removeChannel(notificationChannel);
    }

    if (communityChannel != null) {
      _communityRepository.removeChannel(communityChannel);
    }

    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _profileLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final results = await Future.wait([
        _notificationRepository.getCurrentNotifications(),
        _notificationRepository.getUnreadCount(),
      ]);

      if (!mounted) return;

      setState(() {
        _notifications = results[0] as List<NotificationModel>;

        _unreadNotificationCount = results[1] as int;
      });
    } catch (_) {
      // Notifications should never break the dashboard.
    }
  }

  Future<void> _loadLearning() async {
    try {
      final lessons = await _lessonRepository.getLessons();

      if (!mounted) return;

      setState(() {
        _lessons = lessons;
        _learningLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _learningLoading = false;
      });
    }
  }

  Future<void> _loadCommunity() async {
    try {
      final posts = await _communityRepository.getPosts(limit: 5);

      if (!mounted) return;

      setState(() {
        _communityPosts = posts;
        _communityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _communityLoading = false;
      });
    }
  }

  void _subscribeToNotifications() {
    _notificationChannel = _notificationRepository.watchCurrentUser(
      onChanged: _loadNotifications,
    );
  }

  void _subscribeToCommunity() {
    _communityChannel = _communityRepository.watchPosts(
      onChanged: () {
        _loadCommunity();
      },
    );
  }

  String get _playerName {
    final name = _profile?.fullName.trim();

    if (name == null || name.isEmpty) {
      return 'Player';
    }

    return name.split(RegExp(r'\s+')).first;
  }

  String get _playerInitial {
    final name = _profile?.fullName.trim();

    if (name == null || name.isEmpty) {
      return 'P';
    }

    return name.substring(0, 1).toUpperCase();
  }

  LessonModel? get _continueLesson {
    if (_lessons.isEmpty) return null;

    final unfinished = _lessons.where((lesson) => !lesson.completed).toList();

    if (unfinished.isNotEmpty) {
      unfinished.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      return unfinished.first;
    }

    return _lessons.first;
  }

  Future<void> _showNotifications() async {
    await _loadNotifications();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 20,
                                color: _Colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            TextButton(
                              onPressed: () async {
                                await _notificationRepository.markAllAsRead();

                                await _loadNotifications();

                                if (mounted) {
                                  setSheetState(() {});
                                }
                              },
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: _Colors.blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _notifications.isEmpty
                            ? const _EmptyState(
                                icon: Icons.notifications_none_rounded,
                                title: 'No notifications yet',
                                message:
                                    'Updates from SQI Checkmate Arena will appear here.',
                              )
                            : ListView.separated(
                                itemCount: _notifications.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];

                                  return _NotificationTile(
                                    notification: notification,
                                    onTap: () async {
                                      if (!notification.isRead) {
                                        await _notificationRepository
                                            .markAsRead(notification.id);

                                        await _loadNotifications();

                                        if (mounted) {
                                          setSheetState(() {});
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 900 ? 1120.0 : 760.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  SliverToBoxAdapter(child: _buildHero()),
                  // SliverToBoxAdapter(child: _buildQuickActions()),
                  SliverToBoxAdapter(child: _buildLearning()),
                  SliverToBoxAdapter(child: _buildLiveGames()),
                  SliverToBoxAdapter(child: _buildCommunity()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '♟',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'CHECKMATE',
                style: TextStyle(
                  fontSize: 20,
                  color: _Colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),

          const Spacer(),

          _topIconButton(icon: Icons.search_rounded, onTap: _showSearch),
          const SizedBox(width: 8),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _topIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: _showNotifications,
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 4,
                  top: 3,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _Colors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: _Colors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF4A9FE0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _playerInitial,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: 248,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(
          image: AssetImage("assets/images/herobg3.jpg"),
          opacity: 0.7,
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle board-inspired background detail.
          /* Positioned(
            right: -30,
            top: -35,
            bottom: -35,
            width: 225,
            child: CustomPaint(painter: _ChessHeroBoardPainter()),
          ),
 */
          // Content stays above the chessboard visual.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
            child: SizedBox(
              width: 225,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ), // Gives it a clean separation
                          boxShadow: [
                            BoxShadow(
                              color: _Colors.blue.withAlpha(100),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'SQI CHECKMATE ARENA',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: _Colors.bluedeep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Better at Chess.\nTogether.',
                    style: TextStyle(
                      fontSize: 34,
                      fontFamily: 'Roboto',
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Learn. Play. Compete.',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      color: _Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 40,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MatchesScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Colors.bluedeep,
                        foregroundColor: _Colors.foreground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start Playing',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickActionData(
        icon: Icons.grid_view_rounded,
        title: 'Play',
        subtitle: 'Quick matches',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MatchesScreen())),
      ),
      _QuickActionData(
        icon: Icons.menu_book_rounded,
        title: 'Learn',
        subtitle: 'Chess lessons',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LearnScreen())),
      ),
      _QuickActionData(
        icon: Icons.people_rounded,
        title: 'Community',
        subtitle: 'Talk & share',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CommunityScreen())),
      ),
      _QuickActionData(
        icon: Icons.emoji_events_rounded,
        title: 'Tournaments',
        subtitle: 'Compete',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CompetitionsScreen())),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => _QuickAction(data: actions[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildLearning() {
    final lesson = _continueLesson;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Continue Learning',
            actionLabel: 'View all',
            onAction: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LearnScreen()));
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _Colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: _learningLoading
                ? const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : lesson == null
                ? const _EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No lessons yet',
                    message: 'New chess lessons will appear here.',
                  )
                : Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: _Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                color: _Colors.blue,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              lesson.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                color: _Colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${lesson.progress}% complete • ${lesson.durationMinutes} min',
                              style: const TextStyle(
                                fontSize: 20,
                                color: _Colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: lesson.progress / 100,
                                minHeight: 6,
                                backgroundColor: _Colors.surface3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  _Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LearnScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: _Colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveGames() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Live Games'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _Colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('games')
                  .select(
                    'id, white_player_id, black_player_id, status, time_control',
                  )
                  .eq('status', 'active')
                  .order('created_at', ascending: false)
                  .limit(1),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 72,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Finding a live game...',
                            style: TextStyle(
                              fontSize: 20,
                              color: _Colors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final games = snapshot.data ?? [];

                if (games.isEmpty) {
                  return Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          color: _Colors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch live chess',
                              style: TextStyle(
                                fontSize: 20,
                                color: _Colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'No live games are available right now.',
                              style: TextStyle(
                                fontSize: 20,
                                color: _Colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final game = games.first;
                final gameId = game['id']?.toString();

                if (gameId == null || gameId.isEmpty) {
                  return const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: _Colors.textMuted,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live game information is unavailable.',
                          style: TextStyle(
                            fontSize: 20,
                            color: _Colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final timeControl =
                    game['time_control']?.toString() ?? 'Live game';

                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.visibility_rounded,
                        color: _Colors.green,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live game',
                            style: TextStyle(
                              fontSize: 20,
                              color: _Colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Watch this $timeControl game live.',
                            style: const TextStyle(
                              fontSize: 20,
                              color: _Colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ChessSpectatorScreen(gameId: gameId),
                          ),
                        );
                      },
                      child: const Text(
                        'Watch',
                        style: TextStyle(
                          fontSize: 20,
                          color: _Colors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Community',
            actionLabel: 'View all',
            onAction: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_communityLoading)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _Colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_communityPosts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _Colors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const _EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No posts yet',
                message: 'Start the conversation in the SQI community.',
              ),
            )
          else
            ..._communityPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CommunityPreviewCard(post: post),
              ),
            ),
        ],
      ),
    );
  }

  void _showSearch() {
    showSearch(context: context, delegate: _DashboardSearchDelegate());
  }

  Widget _topIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _Colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCCDEF0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _Colors.textSecondary, size: 20),
        ),
      ),
    );
  }
}

class _CommunityPreviewCard extends StatelessWidget {
  const _CommunityPreviewCard({required this.post});

  final CommunityPostModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: _Colors.blue.withValues(alpha: 0.12),
            backgroundImage: post.authorAvatarUrl == null
                ? null
                : NetworkImage(post.authorAvatarUrl!),
            child: post.authorAvatarUrl == null
                ? Text(
                    post.authorName.isEmpty
                        ? 'S'
                        : post.authorName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      color: _Colors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          color: _Colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      post.timeLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        color: _Colors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (post.authorUsername.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '@${post.authorUsername}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: _Colors.textMuted,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: _Colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_outline_rounded,
                      color: _Colors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.likeCount}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: _Colors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: _Colors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: _Colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case 'match_ready':
        return Icons.sports_esports_rounded;
      case 'match_invite':
        return Icons.person_add_alt_1_rounded;
      case 'community_like':
        return Icons.favorite_outline_rounded;
      case 'community_comment':
        return Icons.chat_bubble_outline_rounded;
      case 'lesson':
        return Icons.school_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: notification.isRead ? _Colors.surface2 : _Colors.surface3,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notification.isRead
                ? Colors.white.withValues(alpha: 0.05)
                : _Colors.blue.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, color: _Colors.blue, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 20,
                            color: _Colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: _Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 20,
                      color: _Colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    notification.timeLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      color: _Colors.textMuted,
                      fontWeight: FontWeight.w600,
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
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCDEF0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _Colors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(data.icon, color: _Colors.blue, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: _Colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, color: _Colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              color: _Colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 20,
                color: _Colors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _Colors.textMuted, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: _Colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: _Colors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChessVisual extends StatelessWidget {
  const _HeroChessVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A6BB5).withValues(alpha: 0.18),
            const Color(0xFF4A9FE0).withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF1A6BB5).withValues(alpha: 0.20),
        ),
      ),
      child: const Center(
        child: Text(
          '♞',
          style: TextStyle(fontSize: 20, color: Color(0xFF1A6BB5)),
        ),
      ),
    );
  }
}

class _DashboardSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search SQI Checkmate';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: _Colors.surface,
        foregroundColor: _Colors.textPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(fontSize: 20, color: _Colors.textMuted),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const _EmptyState(
      icon: Icons.search_rounded,
      title: 'Search is coming together',
      message:
          'Player, competition and community search will be connected here.',
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const _EmptyState(
      icon: Icons.search_rounded,
      title: 'Search SQI Checkmate',
      message: 'Search players, games, competitions and community posts.',
    );
  }
}

class _ChessHeroBoardPainter extends CustomPainter {
  const _ChessHeroBoardPainter();

  static const _dark = Color(0xFF304838);
  static const _light = Color(0xFFE1D7C2);
  static const _ivory = Color(0xFFF9F5EA);
  static const _shadow = Color(0x260F2117);

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = size.width * 0.90;
    final square = boardWidth / 8;
    final left = size.width * 0.14;
    final top = size.height * 0.25;

    canvas.save();

    // Quiet vignette behind the board.
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x28FFFFFF), Color(0x00FFFFFF)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.65, size.height * 0.5),
              radius: size.width * 0.7,
            ),
          );

    canvas.drawRect(Offset.zero & size, glow);

    // Board shadow.
    final boardRect = Rect.fromLTWH(left, top, boardWidth, boardWidth);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        boardRect.shift(const Offset(3, 7)),
        const Radius.circular(5),
      ),
      Paint()..color = _shadow,
    );

    // Wooden board frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(4), const Radius.circular(5)),
      Paint()..color = const Color(0xFF826B4C),
    );

    // Checkerboard squares.
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final isDark = (row + col).isEven;

        canvas.drawRect(
          Rect.fromLTWH(
            left + col * square,
            top + row * square,
            square,
            square,
          ),
          Paint()..color = isDark ? _dark : _light,
        );
      }
    }

    // Selected squares add a restrained game-board detail.
    final selected = Paint()..color = const Color(0x554F805B);

    canvas.drawRect(
      Rect.fromLTWH(left + 5 * square, top + 2 * square, square, square),
      selected,
    );

    // A few pieces on the near side of the board.
    _drawPiece(
      canvas,
      Offset(left + 4.5 * square, top + 5.5 * square),
      square * 0.77,
      false,
      'queen',
    );

    _drawPiece(
      canvas,
      Offset(left + 6.5 * square, top + 4.5 * square),
      square * 0.70,
      true,
      'king',
    );

    _drawPiece(
      canvas,
      Offset(left + 3.5 * square, top + 6.5 * square),
      square * 0.58,
      false,
      'pawn',
    );

    _drawPiece(
      canvas,
      Offset(left + 5.5 * square, top + 6.5 * square),
      square * 0.58,
      false,
      'pawn',
    );

    canvas.restore();
  }

  void _drawPiece(
    Canvas canvas,
    Offset center,
    double s,
    bool darkPiece,
    String type,
  ) {
    final color = darkPiece ? const Color(0xFF1D2921) : _ivory;

    final outline = Paint()
      ..color = darkPiece ? const Color(0xFF111A14) : const Color(0xFFB8AA90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Natural-looking contact shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(1, s * 0.34),
        width: s * 0.8,
        height: s * 0.2,
      ),
      Paint()..color = _shadow,
    );

    final base = Path()
      ..moveTo(center.dx - s * 0.34, center.dy + s * 0.32)
      ..quadraticBezierTo(
        center.dx - s * 0.38,
        center.dy + s * 0.25,
        center.dx - s * 0.25,
        center.dy + s * 0.22,
      )
      ..lineTo(center.dx + s * 0.25, center.dy + s * 0.22)
      ..quadraticBezierTo(
        center.dx + s * 0.38,
        center.dy + s * 0.25,
        center.dx + s * 0.34,
        center.dy + s * 0.32,
      )
      ..close();

    canvas.drawPath(base, fill);
    canvas.drawPath(base, outline);

    final body = Path();

    if (type == 'pawn') {
      body
        ..moveTo(center.dx - s * 0.22, center.dy + s * 0.20)
        ..lineTo(center.dx - s * 0.12, center.dy - s * 0.05)
        ..quadraticBezierTo(
          center.dx,
          center.dy - s * 0.12,
          center.dx + s * 0.12,
          center.dy - s * 0.05,
        )
        ..lineTo(center.dx + s * 0.22, center.dy + s * 0.20)
        ..close();

      canvas.drawPath(body, fill);
      canvas.drawPath(body, outline);

      canvas.drawCircle(center.translate(0, -s * 0.20), s * 0.115, fill);
      canvas.drawCircle(center.translate(0, -s * 0.20), s * 0.115, outline);
    } else if (type == 'queen') {
      body
        ..moveTo(center.dx - s * 0.25, center.dy + s * 0.20)
        ..lineTo(center.dx - s * 0.18, center.dy - s * 0.08)
        ..lineTo(center.dx - s * 0.25, center.dy - s * 0.23)
        ..lineTo(center.dx - s * 0.08, center.dy - s * 0.14)
        ..lineTo(center.dx, center.dy - s * 0.31)
        ..lineTo(center.dx + s * 0.08, center.dy - s * 0.14)
        ..lineTo(center.dx + s * 0.25, center.dy - s * 0.23)
        ..lineTo(center.dx + s * 0.18, center.dy - s * 0.08)
        ..lineTo(center.dx + s * 0.25, center.dy + s * 0.20)
        ..close();

      canvas.drawPath(body, fill);
      canvas.drawPath(body, outline);

      for (final dx in [-0.25, 0.0, 0.25]) {
        canvas.drawCircle(
          Offset(center.dx + dx * s, center.dy - s * (dx == 0 ? 0.31 : 0.23)),
          s * 0.045,
          fill,
        );
      }
    } else {
      body
        ..moveTo(center.dx - s * 0.25, center.dy + s * 0.20)
        ..lineTo(center.dx - s * 0.18, center.dy - s * 0.17)
        ..lineTo(center.dx - s * 0.07, center.dy - s * 0.25)
        ..lineTo(center.dx - s * 0.07, center.dy - s * 0.35)
        ..lineTo(center.dx + s * 0.07, center.dy - s * 0.35)
        ..lineTo(center.dx + s * 0.07, center.dy - s * 0.25)
        ..lineTo(center.dx + s * 0.18, center.dy - s * 0.17)
        ..lineTo(center.dx + s * 0.25, center.dy + s * 0.20)
        ..close();

      canvas.drawPath(body, fill);
      canvas.drawPath(body, outline);

      canvas.drawLine(
        Offset(center.dx, center.dy - s * 0.35),
        Offset(center.dx, center.dy - s * 0.22),
        outline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChessHeroBoardPainter oldDelegate) {
    return false;
  }
}

class _Colors {
  // Sky / Steel-Blue palette
  static const background = Color(0xFFAABBD2);
  static const foreground = Colors.white;
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFE3EEF9);
  static const surface3 = Color(0xFFD0E5F7);

  static const blue = Color(0xFF1A6BB5); // brand primary
  static const bluedeep = Color(0xFF1B4463); // hover / accent
  static const green = Color(0xFF2E9E6E); // success / live
  static const danger = Color(0xFFFF5C70);

  static const textPrimary = Color(0xFF0D1B2E);
  static const textSecondary = Color(0xFF2E4A66);
  static const textMuted = Color(0xFF5E7A99);
  static const profile = Colors.blue;
}
