import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../archive/game_review_screen.dart';

class LanChessMatchScreen extends StatefulWidget {
  const LanChessMatchScreen({
    super.key,
    required this.socket,
    required this.isHost,
    this.timeControl = '10+0',
    this.initialTimeSeconds = 600,
    this.incrementSeconds = 0,
    this.opponentName = 'Opponent',
    this.myName = 'You',
  });

  final Socket socket;
  final bool isHost;

  final String timeControl;
  final int initialTimeSeconds;
  final int incrementSeconds;

  final String opponentName;
  final String myName;

  @override
  State<LanChessMatchScreen> createState() => _LanChessMatchScreenState();
}

class _LanChessMatchScreenState extends State<LanChessMatchScreen> {
  static const Color _background = Color(0xFFF9F8F6);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surface2 = Color(0xFFEDE9E2);
  static const Color _blue = Color(0xFF2D4A3E);
  static const Color _green = Color(0xFF557B63);
  static const Color _gold = Color(0xFFF5C451);
  static const Color _danger = Color(0xFFFF5C70);
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF454B46);
  static const Color _muted = Color(0xFF737A74);

  late final Socket _socket;
  StreamSubscription<String>? _socketSubscription;
  Stream<String>? _incomingLines;

  late Position _position;
  late ChessboardController _boardController;

  Timer? _clockTimer;
  Timer? _broadcastTimer;

  Duration _whiteTime = Duration.zero;
  Duration _blackTime = Duration.zero;

  bool _connected = true;
  bool _gameStarted = false;
  bool _gameOver = false;
  bool _sendingMove = false;
  bool _drawOfferPending = false;

  String? _result;
  String? _statusMessage;

  Move? _lastMove;
  int _ply = 0;
  String? _winnerSide;
  final List<String> _moveHistory = [];

  @override
  void initState() {
    super.initState();

    _socket = widget.socket;

    _position = Chess.initial;

    final initialDuration = Duration(seconds: widget.initialTimeSeconds);

    _whiteTime = initialDuration;
    _blackTime = initialDuration;

    _boardController = ChessboardController(game: _buildGame());

    _incomingLines = _socket
        .map(utf8.decode)
        .transform(const LineSplitter())
        .asBroadcastStream();
    _socketSubscription = _incomingLines!.listen(
      _handleMessage,
      onError: (_) => _handleDisconnected(),
      onDone: _handleDisconnected,
      cancelOnError: false,
    );

    if (widget.isHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAuthoritativeGame();
      });
    }
  }

  GameData _buildGame() {
    final canPlay =
        !_gameOver &&
        _gameStarted &&
        _position.turn == (widget.isHost ? Side.white : Side.black);

    return GameData(
      fen: _position.fen,
      playerSide: canPlay
          ? (widget.isHost ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: _position.turn,
      validMoves: makeLegalMoves(_position),
      lastMove: _lastMove,
      kingSquareInCheck: _position.isCheck
          ? _position.board.kingOf(_position.turn)
          : null,
    );
  }

  void _startAuthoritativeGame() {
    if (!mounted || !widget.isHost) return;
    if (_gameStarted) return;

    _gameStarted = true;

    _sendState(type: 'game_start');

    _startHostClock();
    _startHostBroadcastLoop();

    setState(() {
      _statusMessage = 'Your move';
    });
  }

  void _startHostClock() {
    if (!widget.isHost) return;

    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_gameStarted || _gameOver || !mounted) {
        return;
      }

      final decrement = const Duration(milliseconds: 100);

      if (_position.turn == Side.white) {
        _whiteTime -= decrement;

        if (_whiteTime <= Duration.zero) {
          _whiteTime = Duration.zero;
          _finishByTimeout(Side.white);
          return;
        }
      } else {
        _blackTime -= decrement;

        if (_blackTime <= Duration.zero) {
          _blackTime = Duration.zero;
          _finishByTimeout(Side.black);
          return;
        }
      }

      setState(() {});
    });
  }

  void _startHostBroadcastLoop() {
    if (!widget.isHost) return;

    _broadcastTimer?.cancel();

    _broadcastTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_gameStarted && !_gameOver) {
        _sendClockSync();
      }
    });
  }

  void _sendClockSync() {
    _sendMessage({
      'type': 'clock_sync',
      'whiteMs': _whiteTime.inMilliseconds,
      'blackMs': _blackTime.inMilliseconds,
      'turn': _position.turn == Side.white ? 'white' : 'black',
    });
  }

  void _handleMessage(String line) {
    try {
      final decoded = jsonDecode(line);

      if (decoded is! Map) return;

      final message = Map<String, dynamic>.from(decoded);
      final type = message['type']?.toString();

      switch (type) {
        case 'game_start':
          _handleGameStart(message);
          break;

        case 'move_request':
          _handleMoveRequest(message);
          break;

        case 'state':
          _handleRemoteState(message);
          break;

        case 'clock_sync':
          _handleClockSync(message);
          break;

        case 'draw_offer':
          _handleDrawOffer();
          break;

        case 'draw_response':
          _handleDrawResponse(message);
          break;

        case 'resign':
          _handleRemoteResign();
          break;

        case 'result':
          _handleRemoteResult(message);
          break;

        case 'illegal_move':
          _sendingMove = false;

          if (mounted) {
            setState(() {
              _statusMessage =
                  message['message']?.toString() ?? 'Illegal move.';
            });
          }
          break;

        case 'disconnect':
          _handleDisconnected();
          break;

        default:
          break;
      }
    } catch (_) {}
  }

  void _handleGameStart(Map<String, dynamic> message) {
    if (_gameStarted) return;

    _gameStarted = true;

    final whiteMs =
        int.tryParse(message['whiteMs']?.toString() ?? '') ??
        _whiteTime.inMilliseconds;

    final blackMs =
        int.tryParse(message['blackMs']?.toString() ?? '') ??
        _blackTime.inMilliseconds;

    _whiteTime = Duration(milliseconds: whiteMs);
    _blackTime = Duration(milliseconds: blackMs);

    if (mounted) {
      setState(() {
        _statusMessage = widget.isHost ? 'Your move' : 'Waiting for White';
      });
    }

    _updateBoard(animate: false);
  }

  void _handleMoveRequest(Map<String, dynamic> message) {
    if (!widget.isHost) return;
    if (!_gameStarted || _gameOver) return;

    final uci = message['uci']?.toString();

    if (uci == null || uci.isEmpty) {
      _sendIllegalMove();
      return;
    }

    if (_position.turn != Side.black) {
      _sendIllegalMove();
      return;
    }

    final move = Move.parse(uci);

    if (move == null || !_position.isLegal(move)) {
      _sendIllegalMove();
      return;
    }

    _applyAuthoritativeMove(move);
  }

  void _sendIllegalMove() {
    _sendMessage({
      'type': 'illegal_move',
      'message': 'That move is not legal.',
    });
  }

  void _applyAuthoritativeMove(Move move) {
    if (_gameOver) return;

    final sanResult = _position.makeSan(move);
    final nextPosition = sanResult.$1;
    final san = sanResult.$2;

    if (widget.isHost && move != _lastMove && _position.turn == Side.white) {
      _whiteTime += Duration(seconds: widget.incrementSeconds);
    }

    if (widget.isHost && _position.turn == Side.black) {
      _blackTime += Duration(seconds: widget.incrementSeconds);
    }

    _position = nextPosition;
    _lastMove = move;
    _ply++;
    _moveHistory.add(san);

    _sendingMove = false;

    if (widget.isHost) {
      _sendState(type: 'state', san: san, uci: move.uci);
    }

    _updateBoard();

    if (_checkGameOverAfterMove()) {
      return;
    }

    if (mounted) {
      setState(() {
        _statusMessage =
            _position.turn == (widget.isHost ? Side.white : Side.black)
            ? 'Your move'
            : 'Opponent to move';
      });
    }
  }

  bool _checkGameOverAfterMove() {
    if (_position.isCheckmate) {
      final winner = _position.turn == Side.white ? 'black' : 'white';

      _finishGame(
        result: winner == 'white'
            ? 'White wins by checkmate'
            : 'Black wins by checkmate',
        winner: winner,
        reason: 'checkmate',
        broadcast: widget.isHost,
      );

      return true;
    }

    if (_position.isStalemate) {
      _finishGame(
        result: 'Draw by stalemate',
        winner: 'draw',
        reason: 'stalemate',
        broadcast: widget.isHost,
      );

      return true;
    }

    if (_position.isInsufficientMaterial) {
      _finishGame(
        result: 'Draw by insufficient material',
        winner: 'draw',
        reason: 'insufficient_material',
        broadcast: widget.isHost,
      );

      return true;
    }

    return false;
  }

  void _handleRemoteState(Map<String, dynamic> message) {
    if (widget.isHost) return;

    final uci = message['uci']?.toString();

    if (uci == null || uci.isEmpty) return;

    final move = Move.parse(uci);

    if (move == null || !_position.isLegal(move)) {
      return;
    }

    final sanResult = _position.makeSan(move);

    _position = sanResult.$1;
    _lastMove = move;
    _ply++;
    _moveHistory.add(sanResult.$2);
    _sendingMove = false;

    final whiteMs = int.tryParse(message['whiteMs']?.toString() ?? '');

    final blackMs = int.tryParse(message['blackMs']?.toString() ?? '');

    if (whiteMs != null) {
      _whiteTime = Duration(milliseconds: whiteMs);
    }

    if (blackMs != null) {
      _blackTime = Duration(milliseconds: blackMs);
    }

    _updateBoard();

    if (_checkGameOverAfterMove()) {
      return;
    }

    if (mounted) {
      setState(() {
        _statusMessage = _position.turn == Side.black
            ? 'Your move'
            : 'Opponent to move';
      });
    }
  }

  void _handleClockSync(Map<String, dynamic> message) {
    if (widget.isHost) return;

    final whiteMs = int.tryParse(message['whiteMs']?.toString() ?? '');

    final blackMs = int.tryParse(message['blackMs']?.toString() ?? '');

    if (whiteMs != null) {
      _whiteTime = Duration(milliseconds: whiteMs);
    }

    if (blackMs != null) {
      _blackTime = Duration(milliseconds: blackMs);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleDrawOffer() {
    if (_gameOver) return;

    setState(() {
      _drawOfferPending = true;
      _statusMessage = 'Opponent offered a draw';
    });

    _showDrawDialog();
  }

  Future<void> _showDrawDialog() async {
    if (!mounted) return;

    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface2,
          title: const Text('Draw offer', style: TextStyle(color: _primary)),
          content: const Text(
            'Your opponent offered a draw.',
            style: TextStyle(color: _secondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    _drawOfferPending = false;

    if (accept == true) {
      _sendMessage({'type': 'draw_response', 'accepted': true});

      _finishGame(
        result: 'Draw agreed',
        winner: 'draw',
        reason: 'agreement',
        broadcast: widget.isHost,
      );
    } else {
      _sendMessage({'type': 'draw_response', 'accepted': false});

      if (mounted) {
        setState(() {
          _statusMessage = 'Draw declined';
        });
      }
    }
  }

  void _handleDrawResponse(Map<String, dynamic> message) {
    final accepted = message['accepted'] == true;

    if (accepted) {
      _finishGame(
        result: 'Draw agreed',
        winner: 'draw',
        reason: 'agreement',
        broadcast: false,
      );
    } else if (mounted) {
      setState(() {
        _statusMessage = 'Opponent declined the draw';
      });
    }
  }

  void _handleRemoteResign() {
    if (_gameOver) return;

    final winner = widget.isHost ? 'white' : 'black';

    _finishGame(
      result: winner == 'white'
          ? 'White wins by resignation'
          : 'Black wins by resignation',
      winner: winner,
      reason: 'resignation',
      broadcast: false,
    );
  }

  void _handleRemoteResult(Map<String, dynamic> message) {
    if (_gameOver) return;

    _finishGame(
      result: message['result']?.toString() ?? 'Game over',
      winner: message['winner']?.toString() ?? 'draw',
      reason: message['reason']?.toString() ?? 'unknown',
      broadcast: false,
    );
  }

  void _finishByTimeout(Side side) {
    if (_gameOver) return;

    final winner = side == Side.white ? 'black' : 'white';

    _finishGame(
      result: winner == 'white' ? 'White wins on time' : 'Black wins on time',
      winner: winner,
      reason: 'timeout',
      broadcast: widget.isHost,
    );
  }

  void _finishGame({
    required String result,
    required String winner,
    required String reason,
    required bool broadcast,
  }) {
    if (_gameOver) return;

    _gameOver = true;
    _result = result;
    _winnerSide = winner;

    _clockTimer?.cancel();
    _broadcastTimer?.cancel();

    _updateBoard(animate: false);

    if (broadcast && widget.isHost) {
      _sendMessage({
        'type': 'result',
        'result': result,
        'winner': winner,
        'reason': reason,
        'whiteMs': _whiteTime.inMilliseconds,
        'blackMs': _blackTime.inMilliseconds,
      });
    }

    if (mounted) {
      setState(() {
        _statusMessage = result;
      });
    }
  }

  void _handleDisconnected() {
    if (!_connected) return;

    _connected = false;

    _clockTimer?.cancel();
    _broadcastTimer?.cancel();

    if (!_gameOver) {
      _gameOver = true;
      _result = widget.isHost ? 'Opponent disconnected' : 'Host disconnected';
    }

    if (mounted) {
      setState(() {
        _statusMessage = _result;
      });
    }
  }

  void _sendState({required String type, String? san, String? uci}) {
    _sendMessage({
      'type': type,
      'fen': _position.fen,
      'uci': uci,
      'san': san,
      'whiteMs': _whiteTime.inMilliseconds,
      'blackMs': _blackTime.inMilliseconds,
      'turn': _position.turn == Side.white ? 'white' : 'black',
      'ply': _ply,
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (!_connected) return;

    try {
      _socket.write('${jsonEncode(message)}\n');
    } catch (_) {
      _handleDisconnected();
    }
  }

  void _updateBoard({bool animate = true}) {
    if (!mounted) return;

    _boardController.updatePosition(
      _buildGame(),
      animate: animate,
      resetPremove: true,
    );

    setState(() {});
  }

  void _onMove(Move move, {bool? viaDragAndDrop}) {
    if (_gameOver || !_gameStarted) return;

    final mySide = widget.isHost ? Side.white : Side.black;

    if (_position.turn != mySide) {
      return;
    }

    if (!_position.isLegal(move)) {
      return;
    }

    if (widget.isHost) {
      _applyAuthoritativeMove(move);
      return;
    }

    if (_sendingMove) return;

    _sendingMove = true;

    _sendMessage({'type': 'move_request', 'uci': move.uci});

    if (mounted) {
      setState(() {
        _statusMessage = 'Move sent...';
      });
    }
  }

  void _offerDraw() {
    if (_gameOver || !_gameStarted) return;
    if (_drawOfferPending) return;

    _drawOfferPending = true;

    _sendMessage({'type': 'draw_offer'});

    if (mounted) {
      setState(() {
        _statusMessage = 'Draw offer sent';
      });
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      if (_drawOfferPending) {
        setState(() {
          _drawOfferPending = false;
          _statusMessage = 'Draw offer expired';
        });
      }
    });
  }

  Future<void> _resign() async {
    if (_gameOver) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surface2,
          title: const Text('Resign game?', style: TextStyle(color: _primary)),
          content: const Text(
            'Are you sure you want to resign?',
            style: TextStyle(color: _secondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _danger),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Resign'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final winner = widget.isHost ? 'black' : 'white';

    _sendMessage({'type': 'resign'});

    _finishGame(
      result: winner == 'white'
          ? 'White wins by resignation'
          : 'Black wins by resignation',
      winner: winner,
      reason: 'resignation',
      broadcast: widget.isHost,
    );
  }

  String _formatClock(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000;

    final seconds = totalSeconds.ceil();

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes >= 1) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '0:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _clockColor(Duration time) {
    if (time.inSeconds <= 10) {
      return _danger;
    }

    if (time.inSeconds <= 30) {
      return _gold;
    }

    return _primary;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _broadcastTimer?.cancel();
    _socketSubscription?.cancel();

    if (!_gameOver) {
      try {
        _socket.write('${jsonEncode({'type': 'disconnect'})}\n');
      } catch (_) {}
    }

    _socket.destroy();
    _boardController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'LAN Match',
              style: TextStyle(
                color: _primary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                widget.timeControl,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_connected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LAN',
                    style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > 750;

            if (landscape) {
              return _buildLandscape();
            }

            return _buildPortrait();
          },
        ),
      ),
    );
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          _buildPlayerCard(
            name: widget.opponentName,
            side: widget.isHost ? 'BLACK' : 'WHITE',
            time: widget.isHost ? _blackTime : _whiteTime,
            active: _position.turn == (widget.isHost ? Side.black : Side.white),
            flipped: widget.isHost,
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBoard()),
          const SizedBox(height: 10),
          _buildPlayerCard(
            name: widget.myName,
            side: widget.isHost ? 'WHITE' : 'BLACK',
            time: widget.isHost ? _whiteTime : _blackTime,
            active: _position.turn == (widget.isHost ? Side.white : Side.black),
            flipped: !widget.isHost,
          ),
          const SizedBox(height: 12),
          _buildStatusCard(),
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildBoard(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
            child: Column(
              children: [
                _buildPlayerCard(
                  name: widget.opponentName,
                  side: widget.isHost ? 'BLACK' : 'WHITE',
                  time: widget.isHost ? _blackTime : _whiteTime,
                  active:
                      _position.turn ==
                      (widget.isHost ? Side.black : Side.white),
                  flipped: widget.isHost,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildStatusCard()),
                const SizedBox(height: 12),
                _buildPlayerCard(
                  name: widget.myName,
                  side: widget.isHost ? 'WHITE' : 'BLACK',
                  time: widget.isHost ? _whiteTime : _blackTime,
                  active:
                      _position.turn ==
                      (widget.isHost ? Side.white : Side.black),
                  flipped: !widget.isHost,
                ),
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chessboard(
            controller: _boardController,
            size: boardSize,
            settings: const ChessboardSettings(
              colorScheme: ChessboardColorScheme.green,
              enableCoordinates: true,
            ),
            orientation: widget.isHost ? Side.white : Side.black,
            onMove: _onMove,
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required String side,
    required Duration time,
    required bool active,
    required bool flipped,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? _surface2 : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? _blue.withValues(alpha: .30)
              : Colors.white.withValues(alpha: .05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: flipped
                  ? Colors.black.withValues(alpha: .18)
                  : Colors.white.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: flipped ? _secondary : _primary,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  side,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatClock(time),
            style: TextStyle(
              color: active ? _clockColor(time) : _secondary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _gameOver ? _gold : _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _gameOver ? 'GAME OVER' : 'GAME STATUS',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage ??
                (_gameStarted ? 'Game in progress' : 'Starting game...'),
            style: const TextStyle(
              color: _primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 6),
            Text(
              _result!,
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered_rounded,
                color: _blue,
                size: 16,
              ),
              const SizedBox(width: 7),
              const Text(
                'Moves',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: _moveHistory.isEmpty
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No moves yet',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _moveHistory.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 9),
                            child: Center(
                              child: Text(
                                '${index.isEven ? '${index ~/ 2 + 1}. ' : ''}${_moveHistory[index]}',
                                style: TextStyle(
                                  color: index == _moveHistory.length - 1
                                      ? _primary
                                      : _secondary,
                                  fontSize: 14,
                                  fontWeight: index == _moveHistory.length - 1
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_gameOver) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _openReview,
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Review Game'),
              style: FilledButton.styleFrom(backgroundColor: _blue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text('Exit'),
              style: OutlinedButton.styleFrom(foregroundColor: _secondary),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _gameOver ? null : _offerDraw,
            icon: const Icon(Icons.handshake_outlined, size: 18),
            label: const Text('Draw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _secondary,
              side: const BorderSide(color: Colors.white12),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _gameOver ? null : _resign,
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Resign'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _danger,
              side: BorderSide(color: _danger.withValues(alpha: .30)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameReviewScreen(
          result: _result ?? 'Game ended',
          whitePlayerName: widget.isHost ? widget.myName : widget.opponentName,
          blackPlayerName: widget.isHost ? widget.opponentName : widget.myName,
          winnerSide: _winnerSide,
          timeControl: widget.timeControl,
          moves: List<String>.of(_moveHistory),
        ),
      ),
    );
  }
}
