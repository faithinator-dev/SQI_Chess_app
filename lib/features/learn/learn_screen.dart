import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/lesson_model.dart';
import '../../core/models/puzzle_model.dart';
import '../../core/services/puzzle_service.dart';
import '../../core/repositories/lesson_repository.dart';

const Color _learnText = Color(0xFF0D1B2E);

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const Color background = Color(0xFFF4F8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE3EEF9);
  static const Color blue = Color(0xFF1A6BB5);
  static const Color green = Color(0xFF2E9E6E);
  static const Color gold = Color(0xFFF5A623);
  static const Color purple = Color(0xFF7B6FF0);
  static const Color orange = Color(0xFFF5A623);
  static const Color muted = Color(0xFF5E7A99);

  final TextEditingController _searchController = TextEditingController();
  final LessonRepository _repository = LessonRepository();
  final SupabaseClient _client = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  bool _loading = true;
  String? _error;
  int _loadGeneration = 0;

  final List<_LearnCategory> _categories = const [
    _LearnCategory(
      title: 'All',
      subtitle: 'Everything',
      icon: Icons.grid_view_rounded,
      accent: blue,
    ),
    _LearnCategory(
      title: 'Basics',
      subtitle: 'Build the foundation',
      icon: Icons.menu_book_rounded,
      accent: blue,
    ),
    _LearnCategory(
      title: 'Openings',
      subtitle: 'Start with a plan',
      icon: Icons.rocket_launch_rounded,
      accent: green,
    ),
    _LearnCategory(
      title: 'Tactics',
      subtitle: 'Spot winning ideas',
      icon: Icons.psychology_rounded,
      accent: orange,
    ),
    _LearnCategory(
      title: 'Strategy',
      subtitle: 'Understand positions',
      icon: Icons.insights_rounded,
      accent: purple,
    ),
    _LearnCategory(
      title: 'Endgames',
      subtitle: 'Convert advantages',
      icon: Icons.flag_rounded,
      accent: gold,
    ),
  ];

  final List<_Lesson> _lessons = <_Lesson>[];

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _authSubscription = _client.auth.onAuthStateChange.listen((_) {
      if (!mounted) return;

      _loadGeneration++;
      setState(() {
        _lessons.clear();
        _loading = true;
        _error = null;
      });
      _loadLessons();
    });
  }

  Future<void> _loadLessons() async {
    final generation = _loadGeneration;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final lessons = await _repository.getLessons();
      final mapped = <_Lesson>[
        ..._builtInPieceLessons,
        ...lessons.map(_mapLesson).whereType<_Lesson>(),
      ];

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _lessons
          ..clear()
          ..addAll(_mergeLessons(mapped));
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _lessons
          ..clear()
          ..addAll(_builtInPieceLessons);
        _loading = false;
        _error = null;
      });
    }
  }

  List<_Lesson> _mergeLessons(List<_Lesson> lessons) {
    final byId = <String, _Lesson>{};
    for (final lesson in lessons) {
      byId.putIfAbsent(lesson.id, () => lesson);
    }
    return byId.values.toList();
  }

  List<_Lesson> get _builtInPieceLessons => [
    _pieceLesson(
      id: 'builtin-piece-pawn',
      title: 'Meet the Pawn',
      subtitle: 'How pawns move, capture, promote, and use en passant.',
      icon: Icons.arrow_upward_rounded,
      steps: const [
        _LessonStep(
          title: 'The pawn moves forward',
          body:
              'A pawn moves one square straight forward into an empty square. White pawns move toward rank 8; Black pawns move toward rank 1. Pawns cannot move backward.',
          tip:
              'On its first move, a pawn may move one or two squares if both squares are clear.',
        ),
        _LessonStep(
          title: 'Pawns capture diagonally',
          body:
              'A pawn captures one enemy piece one square diagonally forward. It does not capture the piece directly in front of it.',
          tip: 'A pawn can move forward only when that square is empty.',
        ),
        _LessonStep(
          title: 'Promotion and en passant',
          body:
              'When a pawn reaches the last rank, it must promote to a queen, rook, bishop, or knight. En passant is a special capture available immediately after an enemy pawn moves two squares past your pawn.',
          tip:
              'Promotion is not limited to a queen. A knight can be the best choice when it gives check or avoids stalemate.',
        ),
      ],
    ),
    _pieceLesson(
      id: 'builtin-piece-rook',
      title: 'Meet the Rook',
      subtitle: 'Move along ranks and files, and learn castling.',
      icon: Icons.crop_square_rounded,
      steps: const [
        _LessonStep(
          title: 'Straight lines only',
          body:
              'A rook can move any number of empty squares horizontally along a rank or vertically along a file. It cannot jump over another piece.',
          tip:
              'Rooks are strongest on open files with no pawns blocking their path.',
        ),
        _LessonStep(
          title: 'Capture by landing',
          body:
              'A rook captures an enemy piece by moving to its square. Friendly pieces block the rook and cannot be captured.',
          tip:
              'Keep your rook active: a rook with open lines can attack across the board.',
        ),
        _LessonStep(
          title: 'Castling with a rook',
          body:
              'Castling moves your king two squares toward a rook, then places that rook beside the king. Neither piece may have moved, the path must be clear, and the king cannot castle out of, through, or into check.',
          tip: 'Castling is the only move where two pieces move at once.',
        ),
      ],
    ),
    _pieceLesson(
      id: 'builtin-piece-knight',
      title: 'Meet the Knight',
      subtitle: 'Learn the L-shaped move and why knights can jump.',
      icon: Icons.north_east_rounded,
      steps: const [
        _LessonStep(
          title: 'The L-shaped move',
          body:
              'A knight moves two squares in one direction, then one square at a right angle. Its destination makes an L shape.',
          tip:
              'A knight on a central square can usually reach more squares than one near a corner.',
        ),
        _LessonStep(
          title: 'Knights jump over pieces',
          body:
              'The knight is the only piece that can jump over pieces in its path. It captures only an enemy piece on its destination square.',
          tip:
              'Because it jumps, a knight can leave a crowded position more easily than a bishop or rook.',
        ),
        _LessonStep(
          title: 'Watch for forks',
          body:
              'A fork is one move that attacks two or more targets. Knights are especially good at forks because their attacks cannot be blocked.',
          tip: 'Look for knight checks that also attack a queen or rook.',
        ),
      ],
    ),
    _pieceLesson(
      id: 'builtin-piece-bishop',
      title: 'Meet the Bishop',
      subtitle: 'Move diagonally and use long open lines.',
      icon: Icons.change_history_rounded,
      steps: const [
        _LessonStep(
          title: 'Diagonals are the bishop’s lines',
          body:
              'A bishop moves any number of empty squares diagonally. It cannot jump over pieces.',
          tip: 'Each bishop stays on the same square color for the whole game.',
        ),
        _LessonStep(
          title: 'Capture along a diagonal',
          body:
              'A bishop captures by moving to an enemy piece on the same diagonal. Friendly pieces block its path.',
          tip: 'A bishop becomes powerful when its diagonal is open.',
        ),
        _LessonStep(
          title: 'Two bishops cover both colors',
          body:
              'One bishop moves only on light squares and the other only on dark squares. Together they can cover both colors and work well across open positions.',
          tip:
              'Before moving a bishop, check what its diagonal will attack after the move.',
        ),
      ],
    ),
    _pieceLesson(
      id: 'builtin-piece-queen',
      title: 'Meet the Queen',
      subtitle: 'Combine rook and bishop movement without jumping.',
      icon: Icons.workspace_premium_rounded,
      steps: const [
        _LessonStep(
          title: 'The queen moves in every straight direction',
          body:
              'A queen can move any number of squares horizontally, vertically, or diagonally. It combines the rook’s and bishop’s movement.',
          tip: 'The queen cannot jump over any piece.',
        ),
        _LessonStep(
          title: 'Capture on the queen’s path',
          body:
              'The queen captures an enemy piece by landing on it along a clear rank, file, or diagonal. It cannot land on a friendly piece.',
          tip:
              'A queen is valuable, so check that it cannot be captured before moving it.',
        ),
        _LessonStep(
          title: 'Bring the queen out carefully',
          body:
              'The queen is powerful but can be chased by smaller pieces. Develop your knights and bishops and protect your king before sending the queen into danger.',
          tip: 'Powerful moves still need a safe square and a clear purpose.',
        ),
      ],
    ),
    _pieceLesson(
      id: 'builtin-piece-king',
      title: 'Meet the King',
      subtitle: 'Keep your king safe and understand check and mate.',
      icon: Icons.king_bed_rounded,
      steps: const [
        _LessonStep(
          title: 'One square at a time',
          body:
              'The king moves one square in any direction: horizontally, vertically, or diagonally. It may not move onto a square attacked by an enemy piece. Try moving the king around the pawn on the board.',
          tip:
              'Kings never capture a protected piece if that would leave them in check.',
        ),
        _LessonStep(
          title: 'Check means the king is attacked',
          body:
              'When the king is under attack, it is in check. You must answer check by moving the king, capturing the attacker, or blocking the attack when possible.',
          tip: 'You may never make a move that leaves your own king in check.',
        ),
        _LessonStep(
          title: 'Checkmate ends the game',
          body:
              'Checkmate means the king is in check and there is no legal way to escape. The king is not captured; the game ends at checkmate.',
          tip:
              'In the endgame, bring your king toward the center to help your other pieces.',
        ),
      ],
    ),
  ];

  _Lesson _pieceLesson({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<_LessonStep> steps,
  }) => _Lesson(
    id: id,
    category: 'Basics',
    level: 'BEGINNER',
    title: title,
    subtitle: subtitle,
    progress: 0,
    lessonNumber: 1,
    totalLessons: steps.length,
    duration: '5 min',
    icon: icon,
    accent: blue,
    lessons: steps,
    isBuiltIn: true,
  );

  _Lesson? _mapLesson(LessonModel lesson) {
    final steps = _readSteps(lesson.content);
    if (steps.isEmpty) return null;

    final progress = (lesson.progress.clamp(0, 100) / 100).toDouble();
    final accent = _accentForCategory(lesson.category);

    return _Lesson(
      id: lesson.id,
      category: lesson.category,
      level: lesson.difficulty.toUpperCase(),
      title: lesson.title,
      subtitle: lesson.description ?? '',
      progress: progress,
      lessonNumber: progress >= 1
          ? steps.length
          : (progress * steps.length).ceil().clamp(1, steps.length),
      totalLessons: steps.length,
      duration: '${lesson.durationMinutes} min',
      icon: _iconForCategory(lesson.category),
      accent: accent,
      lessons: steps,
    );
  }

  List<_LessonStep> _readSteps(Map<String, dynamic> content) {
    final rawSteps = content['steps'];
    if (rawSteps is! List) return const <_LessonStep>[];

    return rawSteps
        .whereType<Map>()
        .map((raw) {
          final step = Map<String, dynamic>.from(raw);
          return _LessonStep(
            title: step['title']?.toString() ?? '',
            body: step['body']?.toString() ?? '',
            tip: step['tip']?.toString() ?? '',
          );
        })
        .where((step) => step.title.isNotEmpty && step.body.isNotEmpty)
        .toList();
  }

  Color _accentForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'openings':
        return green;
      case 'tactics':
        return orange;
      case 'strategy':
        return purple;
      case 'endgames':
        return gold;
      default:
        return blue;
    }
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'openings':
        return Icons.rocket_launch_rounded;
      case 'tactics':
        return Icons.psychology_rounded;
      case 'strategy':
        return Icons.insights_rounded;
      case 'endgames':
        return Icons.flag_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  List<_Lesson> get _filteredLessons {
    final query = _searchQuery.trim().toLowerCase();

    return _lessons.where((lesson) {
      final categoryMatches =
          _selectedCategory == 'All' || lesson.category == _selectedCategory;

      if (!categoryMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return lesson.title.toLowerCase().contains(query) ||
          lesson.subtitle.toLowerCase().contains(query) ||
          lesson.category.toLowerCase().contains(query) ||
          lesson.level.toLowerCase().contains(query);
    }).toList();
  }

  _Lesson get _continueLesson => _lessons.firstWhere(
    (lesson) => lesson.progress < 1,
    orElse: () => _lessons.first,
  );

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        titleSpacing: 18,
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ACADEMY',
                style: TextStyle(
                  fontSize: 20,
                  color: blue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Master the Board',
              style: TextStyle(
                fontSize: 20,
                color: _learnText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showSearch,
            icon: const Icon(Icons.search_rounded, color: muted),
            tooltip: 'Search lessons',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1050;
            final tablet = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                desktop ? 40 : 18,
                desktop ? 16 : 12,
                desktop ? 40 : 18,
                30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressOverview(tablet),
                      const SizedBox(height: 18),
                      _buildPuzzlePracticeCard(context),
                      const SizedBox(height: 25),
                      if (!_loading && _error == null && _lessons.isNotEmpty)
                        _buildContinueCard(context, desktop),
                      if (_loading) _buildLoadingState(),
                      if (_error != null) _buildErrorState(),
                      if (!_loading && _error == null && _lessons.isEmpty)
                        _buildEmptyState(),
                      const SizedBox(height: 28),
                      _buildTopicSection(tablet),
                      const SizedBox(height: 26),
                      _buildLessonsHeader(),
                      const SizedBox(height: 12),
                      _buildLessons(context, desktop),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressOverview(bool tablet) {
    final courseProgress = _lessons.isEmpty
        ? 0.0
        : _lessons.fold<double>(0, (sum, lesson) => sum + lesson.progress) /
              _lessons.length;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          _progressStat(
            icon: Icons.auto_stories_rounded,
            value: '${_lessons.where((lesson) => lesson.progress >= 1).length}',
            label: 'Lessons done',
            accent: blue,
          ),
          _divider(),
          _progressStat(
            icon: Icons.schedule_rounded,
            value:
                '${_lessons.fold<int>(0, (sum, lesson) => sum + ((lesson.durationMinutes * lesson.progress).round()))} min',
            label: 'Learning time',
            accent: green,
          ),
          _divider(),
          _progressStat(
            icon: Icons.local_fire_department_rounded,
            value: '${_categories.length - 1}',
            label: 'Chess topics',
            accent: gold,
          ),
          if (tablet) ...[
            _divider(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COURSE PROGRESS',
                    style: TextStyle(
                      fontSize: 20,
                      color: muted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: courseProgress,
                            minHeight: 5,
                            backgroundColor: surfaceLight,
                            valueColor: AlwaysStoppedAnimation<Color>(green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        '${(courseProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          color: green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Center(child: CircularProgressIndicator(color: blue)),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: muted, size: 34),
          const SizedBox(height: 10),
          const Text(
            'Lessons are unavailable.',
            style: TextStyle(
              fontSize: 20,
              color: _learnText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect to the learning service and try again.',
            style: TextStyle(fontSize: 20, color: muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: _loadLessons, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _progressStat({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: _learnText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 35,
      margin: const EdgeInsets.symmetric(horizontal: 11),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }

  Widget _buildContinueCard(BuildContext context, bool desktop) {
    final lesson = _continueLesson;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => _openLesson(context, lesson),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(desktop ? 22 : 17),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [blue.withValues(alpha: 0.15), surface],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: blue.withValues(alpha: 0.13)),
          ),
          child: desktop
              ? Row(
                  children: [
                    _lessonThumbnail(lesson, width: 205, height: 145),
                    const SizedBox(width: 20),
                    Expanded(child: _continueContent(context, lesson)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lessonThumbnail(
                      lesson,
                      width: double.infinity,
                      height: 155,
                    ),
                    const SizedBox(height: 16),
                    _continueContent(context, lesson),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _continueContent(BuildContext context, _Lesson lesson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _levelBadge(lesson.level, lesson.accent),
            const SizedBox(width: 8),
            const Text(
              'CONTINUE LEARNING',
              style: TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 20,
            color: _learnText,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          lesson.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, color: muted, height: 1.45),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: lesson.progress,
                  minHeight: 6,
                  backgroundColor: surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(lesson.accent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(lesson.progress * 100).round()}%',
              style: TextStyle(
                fontSize: 20,
                color: lesson.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Lesson ${lesson.lessonNumber} of ${lesson.totalLessons} - ${lesson.duration}',
          style: const TextStyle(fontSize: 20, color: muted),
        ),
        const SizedBox(height: 15),
        FilledButton.icon(
          onPressed: () => _openLesson(context, lesson),
          icon: const Icon(Icons.play_arrow_rounded, size: 17),
          label: const Text('Continue lesson'),
          style: FilledButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(165, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _lessonThumbnail(
    _Lesson lesson, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lesson.accent.withValues(alpha: 0.23), surfaceLight],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            bottom: -22,
            child: Text(
              '♞',
              style: TextStyle(
                fontSize: 20,
                color: lesson.accent.withValues(alpha: 0.15),
                height: 0.9,
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 16,
            child: Container(
              width: 41,
              height: 41,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: lesson.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(lesson.icon, color: lesson.accent, size: 20),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 16,
            child: Text(
              lesson.category.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                color: lesson.accent,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Positioned(
            right: 15,
            top: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                lesson.duration,
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

  Widget _buildTopicSection(bool tablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interactive drills',
          style: TextStyle(
            fontSize: 20,
            color: _learnText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose the part of your game you want to improve.',
          style: TextStyle(fontSize: 20, color: muted),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: tablet ? 98 : 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = category.title == _selectedCategory;

              return _topicCard(category, selected);
            },
          ),
        ),
      ],
    );
  }

  Widget _topicCard(_LearnCategory category, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category.title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 160,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? category.accent.withValues(alpha: 0.11) : surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? category.accent.withValues(alpha: 0.29)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: category.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.accent, size: 19),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      color: _learnText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      color: muted,
                      height: 1.0,
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

  Widget _buildLessonsHeader() {
    final count = _filteredLessons.length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCategory == 'All'
                    ? 'Curriculum & courses'
                    : '$_selectedCategory lessons',
                style: const TextStyle(
                  fontSize: 20,
                  color: _learnText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? 'lesson' : 'lessons'} available',
                style: const TextStyle(fontSize: 20, color: muted),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _showLearningPath,
          style: TextButton.styleFrom(
            foregroundColor: blue,
            padding: const EdgeInsets.symmetric(horizontal: 7),
          ),
          child: const Text(
            'View learning path',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzlePracticeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: orange.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.extension_rounded, color: orange),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puzzle practice',
                  style: TextStyle(
                    fontSize: 20,
                    color: _learnText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Practice tactics with interactive positions.',
                  style: TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _PuzzlePracticeScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: 'Open puzzle practice',
          ),
        ],
      ),
    );
  }

  Widget _buildLessons(BuildContext context, bool desktop) {
    if (_filteredLessons.isEmpty) {
      return _buildEmptyState();
    }

    if (desktop) {
      return GridView.builder(
        itemCount: _filteredLessons.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.65,
        ),
        itemBuilder: (context, index) {
          return _lessonCard(context, _filteredLessons[index]);
        },
      );
    }

    return Column(
      children: [
        for (var i = 0; i < _filteredLessons.length; i++) ...[
          _lessonCard(context, _filteredLessons[i]),
          if (i != _filteredLessons.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _lessonCard(BuildContext context, _Lesson lesson) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: () => _openLesson(context, lesson),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _lessonThumbnail(lesson, width: 92, height: 110),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _levelBadge(lesson.level, lesson.accent),
                        const SizedBox(width: 7),
                        if (lesson.progress >= 1)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: green,
                            size: 15,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: _learnText,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        color: muted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: lesson.progress,
                              minHeight: 5,
                              backgroundColor: surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                lesson.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(lesson.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 20,
                            color: lesson.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lesson ${lesson.lessonNumber} of ${lesson.totalLessons} - ${lesson.duration}',
                      style: const TextStyle(fontSize: 20, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelBadge(String level, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 20,
          color: accent,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 45),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: blue, size: 25),
          ),
          const SizedBox(height: 13),
          const Text(
            'No lessons found',
            style: TextStyle(
              fontSize: 20,
              color: _learnText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try another topic or search term.',
            style: TextStyle(fontSize: 20, color: muted),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: const Text(
              'Clear filters',
              style: TextStyle(
                fontSize: 20,
                color: blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LESSON ACTIONS
  // ------------------------------------------------------------

  void _openLesson(BuildContext context, _Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LessonPlayerScreen(lesson: lesson)),
    ).then((updated) {
      if (updated is double && mounted) {
        final index = _lessons.indexWhere((item) => item.id == lesson.id);
        if (index != -1) _lessons[index].progress = updated;
        _loadLessons();
      }
    });
  }

  void _showSearch() {
    _searchController.text = _searchQuery;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Search Learn',
            style: TextStyle(
              fontSize: 20,
              color: _learnText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(fontSize: 20, color: _learnText),
            onChanged: (value) {
              _searchQuery = value;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: muted),
              hintText: 'Search lessons, topics or levels',
              hintStyle: const TextStyle(fontSize: 20, color: muted),
              filled: true,
              fillColor: surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 20, color: muted),
              ),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _searchQuery = _searchController.text.trim();
                });
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: blue),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showLearningPath() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      builder: (context) {
        const stages = [
          ('01', 'Foundation', 'Learn how the board and pieces work.', blue),
          (
            '02',
            'Opening Skills',
            'Build plans instead of memorising moves.',
            green,
          ),
          (
            '03',
            'Tactical Vision',
            'Find forcing moves and calculate.',
            orange,
          ),
          (
            '04',
            'Positional Thinking',
            'Improve your pieces and understand plans.',
            purple,
          ),
          ('05', 'Endgame Technique', 'Convert advantages accurately.', gold),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your learning path',
                  style: TextStyle(
                    fontSize: 20,
                    color: _learnText,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'A simple route from fundamentals to stronger decision-making.',
                  style: TextStyle(fontSize: 20, color: muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < stages.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == stages.length - 1 ? 0 : 9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 39,
                          height: 39,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: stages[i].$4.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            stages[i].$1,
                            style: TextStyle(
                              fontSize: 20,
                              color: stages[i].$4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stages[i].$2,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: _learnText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stages[i].$3,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LessonPlayerScreen extends StatefulWidget {
  const _LessonPlayerScreen({required this.lesson});

  final _Lesson lesson;

  @override
  State<_LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<_LessonPlayerScreen> {
  static const Color background = Color(0xFFF4F8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFE3EEF9);
  static const Color blue = Color(0xFF1A6BB5);
  static const Color green = Color(0xFF2E9E6E);
  static const Color gold = Color(0xFFF5A623);
  static const Color muted = Color(0xFF5E7A99);

  late int _stepIndex;
  late double _progress;
  late Position _demoPosition;
  late ChessboardController _demoBoardController;
  final LessonRepository _repository = LessonRepository();

  static const Map<String, String> _pieceDemoFens = {
    'builtin-piece-pawn': '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
    'builtin-piece-rook': '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
    'builtin-piece-knight': '4k3/8/8/8/8/8/8/1N2K3 w - - 0 1',
    'builtin-piece-bishop': '4k3/8/8/8/8/8/8/2B1K3 w - - 0 1',
    'builtin-piece-queen': '4k3/8/8/8/8/8/8/3QK3 w - - 0 1',
    'builtin-piece-king': '4k3/8/8/8/3p4/8/8/4K3 w - - 0 1',
  };
  _LessonStep get _step => widget.lesson.lessons[_stepIndex];

  @override
  void initState() {
    super.initState();
    _progress = widget.lesson.progress;
    _stepIndex = min(
      widget.lesson.lessons.length - 1,
      max(0, ((widget.lesson.progress * widget.lesson.lessons.length).floor())),
    );
    _demoPosition = _initialDemoPosition;
    _demoBoardController = ChessboardController(game: _demoGame());
  }

  Position get _initialDemoPosition => Chess.fromSetup(
    Setup.parseFen(_pieceDemoFens[widget.lesson.id] ?? Chess.initial.fen),
  );

  GameData _demoGame() => GameData(
    fen: _demoPosition.fen,
    playerSide: PlayerSide.white,
    sideToMove: _demoPosition.turn,
    validMoves: makeLegalMoves(_demoPosition),
    kingSquareInCheck: _demoPosition.isCheck
        ? _demoPosition.board.kingOf(_demoPosition.turn)
        : null,
  );

  void _onDemoMove(Move move, {bool? viaDragAndDrop}) {
    if (!_demoPosition.isLegal(move)) return;
    setState(() {
      _demoPosition = _demoPosition.play(move);
      _demoBoardController.updatePosition(_demoGame());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: _learnText,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.category,
              style: const TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: _learnText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 28 : 16,
                    10,
                    desktop ? 28 : 16,
                    22,
                  ),
                  child: desktop ? _buildDesktopLayout() : _buildMobileLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildLessonVisual()),
        const SizedBox(width: 22),
        Expanded(flex: 5, child: _buildLessonContent()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLessonVisual(),
          const SizedBox(height: 18),
          _buildLessonContent(),
        ],
      ),
    );
  }

  Widget _buildLessonVisual() {
    final isPieceLesson = _pieceDemoFens.containsKey(widget.lesson.id);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPieceLesson)
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Chessboard(
                    controller: _demoBoardController,
                    size: size,
                    orientation: Side.white,
                    onMove: _onDemoMove,
                  ),
                );
              },
            )
          else
            Container(
              height: 330,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.lesson.accent.withValues(alpha: 0.21),
                    surfaceLight,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.12,
                    child: Text(
                      '♞',
                      style: TextStyle(
                        fontSize: 20,
                        color: widget.lesson.accent,
                      ),
                    ),
                  ),
                  Container(
                    width: 86,
                    height: 86,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.lesson.accent.withValues(alpha: 0.11),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.lesson.accent.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Icon(
                      widget.lesson.icon,
                      color: widget.lesson.accent,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(_progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 20,
                  color: green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Step ${_stepIndex + 1} of ${widget.lesson.lessons.length}',
            style: const TextStyle(fontSize: 20, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent() {
    final isLast = _stepIndex == widget.lesson.lessons.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _levelBadge(),
        const SizedBox(height: 11),
        Text(
          _step.title,
          style: const TextStyle(
            fontSize: 20,
            color: _learnText,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _step.body,
          style: const TextStyle(fontSize: 20, color: muted, height: 1.65),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: gold.withValues(alpha: 0.13)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: gold,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEY IDEA',
                      style: TextStyle(
                        fontSize: 20,
                        color: gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step.tip,
                      style: const TextStyle(
                        fontSize: 20,
                        color: muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_stepIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previous,
                  icon: const Icon(Icons.arrow_back_rounded, size: 17),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (_stepIndex > 0) const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isLast ? _completeLesson : _next,
                icon: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(isLast ? 'Complete lesson' : 'Next'),
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _levelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.lesson.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.lesson.level,
        style: TextStyle(
          fontSize: 20,
          color: widget.lesson.accent,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /* void _next() {
    if (_stepIndex < widget.lesson.lessons.length - 1) {
      setState(() {
        _stepIndex++;

        _progress = max<double>(
          _progress,
          ((_stepIndex + 1) / (widget.lesson.lessons.length + 1)).toDouble(),
        );
      });
    }
  } */

  void _next() {
    if (_stepIndex < widget.lesson.lessons.length - 1) {
      setState(() {
        _stepIndex++;
        _resetDemoBoard();

        final newProgress = (_stepIndex + 1) / widget.lesson.lessons.length;

        _progress = maxDouble(_progress, newProgress);
      });
      if (!widget.lesson.isBuiltIn) _saveProgress();
    }
  }

  void _previous() {
    if (_stepIndex > 0) {
      setState(() {
        _stepIndex--;
        _resetDemoBoard();
      });
    }
  }

  void _completeLesson() {
    setState(() {
      _progress = 1;
    });

    if (!widget.lesson.isBuiltIn) _saveProgress(completed: true);
    Navigator.pop(context, 1.0);
  }

  Future<void> _saveProgress({bool completed = false}) async {
    if (widget.lesson.isBuiltIn) {
      widget.lesson.progress = _progress;
      return;
    }
    try {
      await _repository.saveProgress(
        lessonId: widget.lesson.id,
        progress: (_progress * 100).round().clamp(0, 100),
        completed: completed || _progress >= 1,
        lastPosition: _stepIndex,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress could not be saved.')),
      );
    }
  }

  void _resetDemoBoard() {
    _demoPosition = _initialDemoPosition;
    _demoBoardController.updatePosition(_demoGame(), animate: false);
  }

  @override
  void dispose() {
    _demoBoardController.dispose();
    super.dispose();
  }
}

class _PuzzlePracticeScreen extends StatefulWidget {
  const _PuzzlePracticeScreen();

  @override
  State<_PuzzlePracticeScreen> createState() => _PuzzlePracticeScreenState();
}

class _PuzzlePracticeScreenState extends State<_PuzzlePracticeScreen> {
  static const _background = Color(0xFFF4F8FD);
  static const _surface = Color(0xFFFFFFFF);
  static const _green = Color(0xFF1A6BB5);
  static const _muted = Color(0xFF5E7A99);

  late final PuzzleService _service;
  late ChessboardController _boardController;
  String _message = 'Find the best move.';
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _service = PuzzleService(
      const PuzzleModel(
        id: 'learn-starter-capture',
        title: 'Capture the knight',
        category: 'Basics',
        difficulty: 'Beginner',
        fen: '4k3/8/8/8/8/2n5/8/4K3 w - - 0 1',
        solutionUci: ['e1d2'],
        instruction: 'Move your king to capture the undefended knight.',
      ),
    );
    _boardController = ChessboardController(game: _game);
  }

  Position get _position => _service.position;

  GameData get _game => GameData(
    fen: _position.fen,
    playerSide: _complete ? PlayerSide.none : PlayerSide.white,
    sideToMove: _position.turn,
    validMoves: makeLegalMoves(_position),
    kingSquareInCheck: _position.isCheck
        ? _position.board.kingOf(_position.turn)
        : null,
  );

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    final attempt = _service.play(move);
    switch (attempt.result) {
      case PuzzleMoveResult.illegal:
        setState(
          () => _message = 'That move is not legal. Try another square.',
        );
        return;
      case PuzzleMoveResult.incorrect:
        setState(
          () => _message = 'Not the solution. Look for the undefended piece.',
        );
        return;
      case PuzzleMoveResult.correct:
      case PuzzleMoveResult.complete:
        setState(() {
          _complete = attempt.result == PuzzleMoveResult.complete;
          _message = _complete
              ? 'Correct! You found the capture.'
              : 'Correct move!';
          _boardController.updatePosition(_game);
        });
        return;
    }
  }

  void _retry() {
    setState(() {
      _service.retry();
      _complete = false;
      _message = 'Find the best move.';
      _boardController.updatePosition(_game, animate: false);
    });
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: const Color(0xFF1A1A1A),
      title: const Text('Puzzle practice'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BEGINNER · TACTICS',
                      style: TextStyle(
                        fontSize: 20,
                        color: _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Capture the knight',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Move your king to capture the undefended knight.',
                      style: TextStyle(fontSize: 20, color: _muted),
                    ),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Chessboard(
                          controller: _boardController,
                          size: double.infinity,
                          orientation: Side.white,
                          onMove: _onMove,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _message,
                      style: TextStyle(
                        fontSize: 20,
                        color: _complete ? _green : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_complete) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LearnCategory {
  const _LearnCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _Lesson {
  _Lesson({
    required this.id,
    required this.category,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.lessonNumber,
    required this.totalLessons,
    required this.duration,
    required this.icon,
    required this.accent,
    required this.lessons,
    this.isBuiltIn = false,
  });

  final String id;
  final String category;
  final String level;
  final String title;
  final String subtitle;
  double progress;
  final int lessonNumber;
  final int totalLessons;
  final String duration;
  int get durationMinutes => int.tryParse(duration.split(' ').first) ?? 0;
  final IconData icon;
  final Color accent;
  final List<_LessonStep> lessons;
  final bool isBuiltIn;
}

class _LessonStep {
  const _LessonStep({
    required this.title,
    required this.body,
    required this.tip,
  });

  final String title;
  final String body;
  final String tip;
}

int min(int a, int b) => a < b ? a : b;
int max(int a, int b) => a > b ? a : b;
double maxDouble(double a, double b) => a > b ? a : b;
