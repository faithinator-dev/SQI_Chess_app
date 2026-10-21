import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_review_screen.dart';
import 'match_config.dart';

class LocalPvpScreen extends StatefulWidget {
  const LocalPvpScreen({super.key, required this.config});

  final MatchConfig config;

  @override
  State<LocalPvpScreen> createState() => _LocalPvpScreenState();
}

class _LocalPvpScreenState extends State<LocalPvpScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEDE9E2);

  static const Color blue = Color(0xFF2D4A3E);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF454B46);
  static const Color textMuted = Color(0xFF737A74);

  late final ChessboardController _boardController;

  Position _position = Chess.initial;
  Move? _lastMove;

  late int _whiteTimeMs;
  late int _blackTimeMs;

  Timer? _clockTimer;

  final List<String> _moves = [];

  bool _gameOver = false;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();

    final initialMs = widget.config.initialTimeSeconds * 1000;

    _whiteTimeMs = initialMs;
    _blackTimeMs = initialMs;

    _boardController = ChessboardController(game: _buildGame());

    _startClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _boardController.dispose();
    super.dispose();
  }

  GameData _buildGame() {
    final playerSide = _position.turn == Side.white
        ? PlayerSide.white
        : PlayerSide.black;

    return GameData(
      fen: _position.fen,
      playerSide: _gameOver ? PlayerSide.none : playerSide,
      sideToMove: _position.turn,
      validMoves: makeLegalMoves(_position),
      lastMove: _lastMove,
      kingSquareInCheck: _position.isCheck
          ? _position.board.kingOf(_position.turn)
          : null,
    );
  }

  void _updateBoard() {
    _boardController.updatePosition(_buildGame());
  }

  void _startClock() {
    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _gameOver) return;

      if (_position.turn == Side.white) {
        _whiteTimeMs -= 100;

        if (_whiteTimeMs <= 0) {
          _whiteTimeMs = 0;

          _finishGame(
            winner: widget.config.blackPlayerName,
            reason: 'White ran out of time.',
          );
          return;
        }
      } else {
        _blackTimeMs -= 100;

        if (_blackTimeMs <= 0) {
          _blackTimeMs = 0;

          _finishGame(
            winner: widget.config.whitePlayerName,
            reason: 'Black ran out of time.',
          );
          return;
        }
      }

      setState(() {});
    });
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (_gameOver) return;

    if (!_position.isLegal(move)) {
      return;
    }

    final movingSide = _position.turn;

    try {
      final (nextPosition, san) = _position.makeSan(move);

      _position = nextPosition;
      _lastMove = move;
      _moves.add(san);

      if (movingSide == Side.white) {
        _whiteTimeMs += widget.config.incrementSeconds * 1000;
      } else {
        _blackTimeMs += widget.config.incrementSeconds * 1000;
      }

      _updateBoard();

      if (mounted) {
        setState(() {});
      }

      _checkGameEnd();
    } catch (_) {
      // Ignore invalid moves.
    }
  }

  void _checkGameEnd() {
    if (_position.isCheckmate) {
      final winner = _position.turn == Side.white
          ? widget.config.blackPlayerName
          : widget.config.whitePlayerName;

      _finishGame(winner: winner, reason: 'Checkmate.');

      return;
    }

    if (_position.isStalemate) {
      _finishDraw('Stalemate.');
      return;
    }

    if (_position.isInsufficientMaterial) {
      _finishDraw('Insufficient material.');
    }
  }

  void _finishGame({required String winner, required String reason}) {
    if (_gameOver) return;

    _gameOver = true;
    _clockTimer?.cancel();

    _updateBoard();

    if (!mounted) return;

    setState(() {});

    _showResult(
      title: '$winner wins',
      reason: reason,
      winnerSide: winner == widget.config.whitePlayerName ? 'white' : 'black',
    );
  }

  void _finishDraw(String reason) {
    if (_gameOver) return;

    _gameOver = true;
    _clockTimer?.cancel();

    _updateBoard();

    if (!mounted) return;

    setState(() {});

    _showResult(title: 'Draw', reason: reason, winnerSide: 'draw');
  }

  void _showResult({
    required String title,
    required String reason,
    required String winnerSide,
  }) {
    if (_resultShown || !mounted) return;

    _resultShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (_) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: gold.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: gold,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: textMuted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GameReviewScreen(
                                  result: title,
                                  timeControl:
                                      '${widget.config.initialTimeSeconds ~/ 60}+${widget.config.incrementSeconds}',
                                  whitePlayerName:
                                      widget.config.whitePlayerName,
                                  blackPlayerName:
                                      widget.config.blackPlayerName,
                                  winnerSide: winnerSide,
                                  moves: List<String>.of(_moves),
                                ),
                              ),
                            );
                          },
                          child: const Text('Review Game'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _resetGame();
                          },
                          child: const Text('Play Again'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          style: FilledButton.styleFrom(backgroundColor: blue),
                          child: const Text('Exit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _resetGame() {
    final initialMs = widget.config.initialTimeSeconds * 1000;
    _clockTimer?.cancel();
    setState(() {
      _position = Chess.initial;
      _lastMove = null;
      _moves.clear();
      _whiteTimeMs = initialMs;
      _blackTimeMs = initialMs;
      _gameOver = false;
      _resultShown = false;
    });
    _updateBoard();
    _startClock();
  }

  Future<void> _resign() async {
    if (_gameOver) return;

    final shouldResign = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: surface,
          title: const Text(
            'Resign game?',
            style: TextStyle(fontSize: 20, color: textPrimary),
          ),
          content: const Text(
            'Are you sure you want to resign this game?',
            style: TextStyle(fontSize: 20, color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'RESIGN',
                style: TextStyle(fontSize: 20, color: danger),
              ),
            ),
          ],
        );
      },
    );

    if (shouldResign != true || !mounted) return;

    final winner = _position.turn == Side.white
        ? widget.config.blackPlayerName
        : widget.config.whitePlayerName;

    _finishGame(winner: winner, reason: 'Opponent resigned.');
  }

  void _offerDraw() {
    if (_gameOver) return;

    _finishDraw('Draw agreed.');
  }

  String _formatTime(int milliseconds) {
    final totalSeconds = (milliseconds / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildClock({
    required String name,
    required int milliseconds,
    required bool active,
  }) {
    final critical = milliseconds <= 10 * 1000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? blue.withAlpha(25) : surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? blue.withAlpha(90) : Colors.white.withAlpha(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: active ? green : textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              color: textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTime(milliseconds),
            style: TextStyle(
              fontSize: 20,
              color: critical ? danger : textPrimary,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest.shortestSide;

              return Chessboard(
                controller: _boardController,
                settings: const ChessboardSettings(
                  colorScheme: ChessboardColorScheme.green,
                  enableCoordinates: true,
                ),
                orientation: Side.white,
                size: size,
                onMove: _onMove,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHistory() {
    if (_moves.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No moves yet',
          style: TextStyle(fontSize: 20, color: textMuted),
        ),
      );
    }

    final spans = <InlineSpan>[];

    for (var i = 0; i < _moves.length; i++) {
      if (i.isEven) {
        spans.add(
          TextSpan(
            text: '${(i ~/ 2) + 1}. ',
            style: const TextStyle(
              fontSize: 20,
              color: textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: '${_moves[i]} ',
          style: const TextStyle(
            fontSize: 20,
            color: textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20, height: 1.4),
          children: spans,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _gameOver ? null : _offerDraw,
            icon: const Icon(Icons.handshake_rounded, size: 18),
            label: const Text('DRAW'),
            style: OutlinedButton.styleFrom(
              foregroundColor: textSecondary,
              side: BorderSide(color: Colors.white.withAlpha(18)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _gameOver ? null : _resign,
            icon: const Icon(Icons.flag_rounded, size: 18),
            label: const Text('RESIGN'),
            style: FilledButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortrait() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: textSecondary,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'PLAYER VS PLAYER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildClock(
                  name: widget.config.whitePlayerName,
                  milliseconds: _whiteTimeMs,
                  active: _position.turn == Side.white,
                ),
                _buildClock(
                  name: widget.config.blackPlayerName,
                  milliseconds: _blackTimeMs,
                  active: _position.turn == Side.black,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildBoard(),
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(color: Colors.white.withAlpha(8)),
                bottom: BorderSide(color: Colors.white.withAlpha(8)),
              ),
            ),
            child: _buildMoveHistory(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscape() {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBoard(),
            ),
          ),
          SizedBox(
            width: 270,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: textSecondary,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'PLAYER VS PLAYER',
                          style: TextStyle(
                            fontSize: 20,
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildClock(
                    name: widget.config.whitePlayerName,
                    milliseconds: _whiteTimeMs,
                    active: _position.turn == Side.white,
                  ),
                  const SizedBox(height: 8),
                  _buildClock(
                    name: widget.config.blackPlayerName,
                    milliseconds: _blackTimeMs,
                    active: _position.turn == Side.black,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: _buildMoveHistory(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscape();
          }

          return _buildPortrait();
        },
      ),
    );
  }
}
