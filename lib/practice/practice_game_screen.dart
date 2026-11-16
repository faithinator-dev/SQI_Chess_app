import 'dart:async';
import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/archive/game_review_screen.dart';
import '../core/chess/bot_difficulty.dart';
import '../core/chess/bot_player.dart';
import '../core/models/practice_achievement.dart';

enum PlayerSideChoice { white, black, random }

class PracticeGameScreen extends StatefulWidget {
  const PracticeGameScreen({
    super.key,
    required this.level,
    this.playerName,
    this.sideChoice = PlayerSideChoice.white,
  });

  final String level;
  final String? playerName;
  final PlayerSideChoice sideChoice;

  @override
  State<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends State<PracticeGameScreen> {
  static const Color background = Color(0xFFF9F8F6);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color surfaceLight = Color(0xFFEDE9E2);

  static const Color blue = Color(0xFF2D4A3E);

  static const Color green = Color(0xFF557B63);

  static const Color red = Color(0xFFFF5C70);

  static const Color gold = Color(0xFFF5C451);

  static const Color muted = Color(0xFF737A74);
  static const Color primaryText = Color(0xFF1A1A1A);

  late Position _position;
  late ChessboardController _controller;
  late BotPlayer _botPlayer;
  late BotDifficulty _difficulty;

  Move? _lastMove;

  final List<String> _moveHistory = [];
  Set<String> _unlockedAchievements = {};
  int _completedGames = 0;
  int _wins = 0;
  bool _achievementStatsLoaded = false;
  final Set<String> _pendingAchievementUnlocks = {};
  bool _achievementWriteInProgress = false;

  bool _botThinking = false;
  bool _gameOver = false;
  bool _resultShown = false;
  bool _initializing = true;
  late Side _playerSide;
  Side get _computerSide => _opposite(_playerSide);
  Side _opposite(Side side) => side == Side.white ? Side.black : Side.white;

  String _status = 'Your turn';

  @override
  void initState() {
    super.initState();

    _difficulty = _difficultyFromLevel(widget.level);
    _playerSide = switch (widget.sideChoice) {
      PlayerSideChoice.white => Side.white,
      PlayerSideChoice.black => Side.black,
      PlayerSideChoice.random => Random().nextBool() ? Side.white : Side.black,
    };

    _position = Chess.initial;

    _botPlayer = BotPlayer(difficulty: _difficulty);

    _controller = ChessboardController(game: _buildGame());

    _initialize();
    _loadAchievementStats();
  }

  Future<void> _initialize() async {
    await _botPlayer.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _initializing = false;
      _status = _position.turn == _playerSide
          ? 'Your turn'
          : 'Computer is thinking...';
    });

    if (widget.sideChoice == PlayerSideChoice.random) _unlock('first_random');
    if (_playerSide == Side.black) _unlock('first_black');
    if (_position.turn == _computerSide) _startBotTurn();
  }

  BotDifficulty _difficultyFromLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return BotDifficulty.beginner;

      case 'advanced':
        return BotDifficulty.advanced;

      case 'expert':
        return BotDifficulty.expert;

      case 'creator':
        return BotDifficulty.creator;

      case 'intermediate':
      default:
        return BotDifficulty.intermediate;
    }
  }

  Future<void> _loadAchievementStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _unlockedAchievements =
          (prefs.getStringList('practice_achievements_v1') ?? []).toSet();
      _completedGames = prefs.getInt('practice_completed_games_v1') ?? 0;
      _wins = prefs.getInt('practice_wins_v1') ?? 0;
      _achievementStatsLoaded = true;
    });
    final pending = _pendingAchievementUnlocks.toList();
    _pendingAchievementUnlocks.clear();
    for (final id in pending) {
      await _unlock(id);
    }
  }

  Future<void> _unlock(String id) async {
    if (!_achievementStatsLoaded) {
      _pendingAchievementUnlocks.add(id);
      return;
    }
    if (_unlockedAchievements.contains(id)) return;
    if (_achievementWriteInProgress) {
      _pendingAchievementUnlocks.add(id);
      return;
    }
    final achievement = practiceAchievements.firstWhere(
      (item) => item.id == id,
    );
    _unlockedAchievements.add(id);
    _achievementWriteInProgress = true;
    var persisted = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      persisted = await prefs.setStringList(
        'practice_achievements_v1',
        _unlockedAchievements.toList(),
      );
    } catch (error) {
      _unlockedAchievements.remove(id);
      _pendingAchievementUnlocks.add(id);
      debugPrint('Achievement could not be saved: $error');
      return;
    } finally {
      _achievementWriteInProgress = false;
    }
    if (!persisted) {
      _unlockedAchievements.remove(id);
      _pendingAchievementUnlocks.add(id);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF172F67),
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 27)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${achievement.emoji} Achievement unlocked!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${achievement.title} — ${achievement.description}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    if (_pendingAchievementUnlocks.isNotEmpty) {
      final next = _pendingAchievementUnlocks.first;
      _pendingAchievementUnlocks.remove(next);
      await _unlock(next);
    }
  }

  void _checkMoveCountAchievements() {
    final playerMoves = _moveHistory
        .asMap()
        .entries
        .where(
          (entry) =>
              (entry.key.isEven ? Side.white : Side.black) == _playerSide,
        )
        .length;
    if (playerMoves >= 10) _unlock('ten_moves');
    if (playerMoves >= 20) _unlock('twenty_moves');
    if (playerMoves >= 50) _unlock('fifty_moves');
  }

  Future<void> _recordFinishedGame({
    required bool won,
    required bool checkmate,
  }) async {
    if (!_achievementStatsLoaded) {
      await _loadAchievementStats();
    }
    _completedGames++;
    if (won) _wins++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('practice_completed_games_v1', _completedGames);
    await prefs.setInt('practice_wins_v1', _wins);
    _unlock('first_game');
    if (won) {
      _unlock('first_win');
      if (_wins >= 3) _unlock('three_wins');
      if (_wins >= 5) _unlock('five_wins');
      if (_playerSide == Side.black) _unlock('win_as_black');
      if (checkmate) _unlock('checkmate');
      if (_difficulty == BotDifficulty.creator ||
          widget.level.toLowerCase() == 'creator') {
        _unlock('creator_win');
      }
    }
    if (_completedGames >= 5) _unlock('five_games');
    if (_completedGames >= 10) _unlock('ten_games');
  }

  GameData _buildGame() {
    return GameData(
      fen: _position.fen,
      playerSide: _playerSide == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: _position.turn,
      lastMove: _lastMove,
      validMoves: makeLegalMoves(_position),
    );
  }

  // ------------------------------------------------------------
  // PLAYER MOVE
  // ------------------------------------------------------------

  void _onPlayerMove(Move move, {bool? viaDragAndDrop}) {
    if (_initializing || _botThinking || _gameOver) {
      return;
    }

    // Only the selected player side is controlled by the player.
    if (_position.turn != _playerSide) {
      return;
    }

    if (!_position.isLegal(move)) {
      return;
    }

    final sanResult = _position.makeSan(move);

    final san = sanResult.$2;

    setState(() {
      _position = _position.play(move);
      _lastMove = move;
      _moveHistory.add(san);
      _status = 'Computer is thinking...';
    });

    _controller.updatePosition(_buildGame());
    if (_moveHistory.length == 1) _unlock('first_move');
    _checkMoveCountAchievements();

    if (_checkGameOver()) {
      return;
    }

    // The player has just moved.
    if (_position.turn == _computerSide) {
      _startBotTurn();
    }
  }

  // ------------------------------------------------------------
  // BOT TURN
  // ------------------------------------------------------------

  Future<void> _startBotTurn() async {
    if (!mounted ||
        _gameOver ||
        _botThinking ||
        _position.turn != _computerSide) {
      return;
    }

    setState(() {
      _botThinking = true;
      _status = '${_difficulty.title} computer is thinking...';
    });

    // Human-friendly thinking delay.
    // The bot should not instantly snap out a move.
    final delay = _thinkingDelay();

    await Future<void>.delayed(delay);

    if (!mounted || _gameOver || _position.turn != _computerSide) {
      return;
    }

    final fen = _position.fen;

    final uci = await _botPlayer.findBestMove(fen);

    if (!mounted || _gameOver || _position.turn != _computerSide) {
      return;
    }

    if (uci == null) {
      setState(() {
        _botThinking = false;
        _status = 'Computer could not find a move.';
      });
      return;
    }

    final move = Move.parse(uci);

    if (move == null || !_position.isLegal(move)) {
      setState(() {
        _botThinking = false;
        _status = 'Computer returned an invalid move.';
      });
      return;
    }

    final sanResult = _position.makeSan(move);

    final san = sanResult.$2;

    setState(() {
      _position = _position.play(move);
      _lastMove = move;
      _moveHistory.add(san);
      _botThinking = false;
      _status = 'Your turn';
    });

    _controller.updatePosition(_buildGame());

    if (_position.isCheck) _unlock('checkmate');

    _checkGameOver();
  }

  Duration _thinkingDelay() {
    switch (_difficulty) {
      case BotDifficulty.beginner:
        return const Duration(milliseconds: 700);

      case BotDifficulty.intermediate:
        return const Duration(milliseconds: 1100);

      case BotDifficulty.advanced:
        return const Duration(milliseconds: 1400);

      case BotDifficulty.expert:
        return const Duration(milliseconds: 1800);
      case BotDifficulty.creator:
        return const Duration(milliseconds: 1200);
    }
  }

  // ------------------------------------------------------------
  // GAME END
  // ------------------------------------------------------------

  bool _checkGameOver() {
    if (!_position.isGameOver) {
      return false;
    }

    _gameOver = true;
    _botThinking = false;
    final playerWon = _position.isCheckmate && _position.turn == _computerSide;
    _recordFinishedGame(won: playerWon, checkmate: _position.isCheckmate);
    if (playerWon && _position.isCheckmate) _unlock('checkmate');

    if (_position.isCheckmate) {
      if (_position.turn == _computerSide) {
        _status = 'Checkmate — You win!';
      } else {
        _status = 'Checkmate — Computer wins!';
      }
    } else if (_position.isStalemate) {
      _status = 'Draw — Stalemate';
    } else {
      _status = 'Game over — Draw';
    }

    setState(() {});

    if (!_resultShown) {
      _resultShown = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showGameOverDialog(),
      );
    }

    return true;
  }

  Future<void> _showGameOverDialog() async {
    if (!mounted) {
      return;
    }

    final title = _position.isCheckmate
        ? (_position.turn == _computerSide ? 'Victory' : 'Defeat')
        : 'Draw';

    final message = _status;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              color: primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 20, color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (_) => GameReviewScreen(
                      result: title,
                      whitePlayerName: _playerSide == Side.white
                          ? (widget.playerName ?? 'You')
                          : 'Computer',
                      blackPlayerName: _playerSide == Side.black
                          ? (widget.playerName ?? 'You')
                          : 'Computer',
                      winnerSide: title == 'Victory'
                          ? (_playerSide == Side.white ? 'white' : 'black')
                          : title == 'Defeat'
                          ? (_computerSide == Side.white ? 'white' : 'black')
                          : 'draw',
                      moves: List<String>.of(_moveHistory),
                    ),
                  ),
                );
              },
              child: const Text(
                'Review Game',
                style: TextStyle(fontSize: 20, color: blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text(
                'Play Again',
                style: TextStyle(
                  fontSize: 20,
                  color: blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Exit',
                style: TextStyle(fontSize: 20, color: muted),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  void _resetGame() {
    _botPlayer.stop();

    setState(() {
      _position = Chess.initial;
      _lastMove = null;
      _moveHistory.clear();
      _botThinking = false;
      _gameOver = false;
      _resultShown = false;
      _status = 'Your turn';
    });

    _controller.updatePosition(
      _buildGame(),
      animate: false,
      resetPremove: true,
    );
    if (_playerSide == Side.black) _startBotTurn();
  }

  // ------------------------------------------------------------
  // RESIGN
  // ------------------------------------------------------------

  void _resign() {
    if (_gameOver || _botThinking) {
      return;
    }

    setState(() {
      _gameOver = true;
      _status = 'You resigned — Computer wins';
    });
    _recordFinishedGame(won: false, checkmate: false);

    if (!_resultShown) {
      _resultShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) => _showResignDialog());
    }
  }

  Future<void> _confirmExit() async {
    if (_gameOver) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exit game?'),
        content: const Text(
          'Your practice game is still in progress. Continue playing or exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continue game'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (exit == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _showResignDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Game Resigned',
            style: TextStyle(
              fontSize: 20,
              color: primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'The computer wins this practice game.',
            style: TextStyle(fontSize: 20, color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(this.context).push(
                  MaterialPageRoute(
                    builder: (_) => GameReviewScreen(
                      result: 'Victory',
                      whitePlayerName: _playerSide == Side.white
                          ? (widget.playerName ?? 'You')
                          : 'Computer',
                      blackPlayerName: _playerSide == Side.black
                          ? (widget.playerName ?? 'You')
                          : 'Computer',
                      winnerSide: _computerSide.name,
                      moves: List<String>.of(_moveHistory),
                    ),
                  ),
                );
              },
              child: const Text(
                'Review Game',
                style: TextStyle(fontSize: 20, color: blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text(
                'Play Again',
                style: TextStyle(fontSize: 20, color: blue),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Exit',
                style: TextStyle(fontSize: 20, color: muted),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          foregroundColor: primaryText,
          titleSpacing: 18,
          title: Row(
            children: [
              const Text(
                'Practice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _difficulty.title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reset game',
              onPressed: _botThinking ? null : _resetGame,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1050;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 10,
                  vertical: isDesktop ? 20 : 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: isDesktop
                        ? _buildDesktopLayout()
                        : _buildMobileLayout(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildBoardPanel()),
        const SizedBox(width: 24),
        Expanded(flex: 4, child: _buildInfoPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPlayerRow(
          name: _difficulty.title == "Creator" ? 'Faith Tolu' : 'SQI Computer',
          subtitle: '${_difficulty.title} • ${_difficulty.elo}',
          avatar: 'BOT',
          active: _botThinking,
          indicatorColor: _botThinking ? gold : muted,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Chessboard(
                      controller: _controller,
                      size: boardSize,
                      settings: const ChessboardSettings(
                        colorScheme: ChessboardColorScheme.green,
                        enableCoordinates: true,
                        enablePremoves: false,
                      ),
                      orientation: _playerSide,
                      onMove: _onPlayerMove,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildPlayerRow(
          name: widget.playerName ?? 'You',
          subtitle: 'You • ${_playerSide.name.toUpperCase()}',
          avatar: 'F',
          active: !_botThinking && !_gameOver && !_initializing,
          indicatorColor: !_botThinking && !_gameOver ? green : muted,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  color: _botThinking
                      ? gold
                      : _gameOver
                      ? red
                      : primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_moveHistory.length} plies',
              style: const TextStyle(fontSize: 20, color: muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_gameOver || _botThinking) ? null : _resign,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('RESIGN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: red.withValues(alpha: 0.12),
              foregroundColor: red,
              disabledBackgroundColor: surfaceLight,
              disabledForegroundColor: muted,
              minimumSize: const Size.fromHeight(44),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BOARD PANEL
  // ------------------------------------------------------------

  Widget _buildBoardPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildOpponentCard(),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = min(constraints.maxWidth, 700.0);

              return Center(
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: Chessboard(
                    controller: _controller,
                    size: boardSize,
                    settings: const ChessboardSettings(
                      colorScheme: ChessboardColorScheme.green,
                      enableCoordinates: true,
                      enablePremoves: false,
                    ),
                    orientation: _playerSide,
                    onMove: _onPlayerMove,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildPlayerCard(),
        ],
      ),
    );
  }

  Widget _buildOpponentCard() {
    return _buildPlayerRow(
      name: _difficulty.title == "Creator" ? 'Faith Tolu' : "SQI Computer",
      subtitle: '${_difficulty.title} • ${_difficulty.elo}',
      avatar: 'BOT',
      active: _botThinking,
      indicatorColor: _botThinking ? gold : muted,
    );
  }

  Widget _buildPlayerCard() {
    return _buildPlayerRow(
      name: widget.playerName ?? 'Faith Toluwanimi',
      subtitle: 'You • ${_playerSide.name.toUpperCase()}',
      avatar: 'F',
      active: !_botThinking && !_gameOver && !_initializing,
      indicatorColor: !_botThinking && !_gameOver ? green : muted,
    );
  }

  Widget _buildPlayerRow({
    required String name,
    required String subtitle,
    required String avatar,
    required bool active,
    required Color indicatorColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              avatar,
              style: const TextStyle(
                fontSize: 20,
                color: blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: active ? indicatorColor : muted,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO PANEL
  // ------------------------------------------------------------

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusCard(),
        const SizedBox(height: 16),
        _buildMovesCard(),
        const SizedBox(height: 16),
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildStatusCard() {
    final isThinking = _botThinking;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GAME STATUS',
            style: TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _status,
            style: TextStyle(
              fontSize: 20,
              color: isThinking
                  ? gold
                  : _gameOver
                  ? red
                  : primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('LEVEL', _difficulty.title),
              const SizedBox(width: 12),
              _miniStat('MOVES', '${_moveHistory.length}'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: blue, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _difficulty.description,
                    style: const TextStyle(
                      fontSize: 20,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                color: muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                color: primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovesCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
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
              const Text(
                'Move History',
                style: TextStyle(
                  fontSize: 20,
                  color: primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_moveHistory.length} plies',
                style: const TextStyle(fontSize: 20, color: muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _moveHistory.isEmpty
                ? const Center(
                    child: Text(
                      'Your first move starts the game.',
                      style: TextStyle(fontSize: 20, color: muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: _moveHistory.length,
                    itemBuilder: (context, index) {
                      final moveNumber = (index ~/ 2) + 1;

                      final isWhite = index.isEven;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: index == _moveHistory.length - 1
                              ? blue.withValues(alpha: 0.10)
                              : surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                isWhite ? '$moveNumber.' : '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _moveHistory[index],
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              isWhite ? 'White' : 'Black',
                              style: const TextStyle(
                                fontSize: 20,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_gameOver || _botThinking) ? null : _resign,
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Resign'),
              style: ElevatedButton.styleFrom(
                backgroundColor: red.withValues(alpha: 0.12),
                foregroundColor: red,
                disabledBackgroundColor: surfaceLight,
                disabledForegroundColor: muted,
                minimumSize: const Size(double.infinity, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: blue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The computer evaluates the position and searches candidate moves instead of following a fixed move script.',
                  style: TextStyle(fontSize: 20, color: muted, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _botPlayer.stop();
    _controller.dispose();
    super.dispose();
  }
}
