import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../archive/game_review_screen.dart';
import '../../core/models/chess_game_model.dart';
import '../../core/repositories/chess_game_repository.dart';

class ChessMatchScreen extends StatefulWidget {
  const ChessMatchScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ChessMatchScreen> createState() => _ChessMatchScreenState();
}

class _ChessMatchScreenState extends State<ChessMatchScreen>
    with WidgetsBindingObserver {
  static const _background = Color(0xFFF9F8F6);
  static const _surface = Color(0xFFFFFFFF);
  static const _surface3 = Color(0xFFE8F0EC);
  static const _blue = Color(0xFF2D4A3E);
  static const _green = Color(0xFF557B63);
  static const _danger = Color(0xFFFF5C70);
  static const _primary = Color(0xFF1A1A1A);
  static const _secondary = Color(0xFF454B46);
  static const _muted = Color(0xFF737A74);

  final SupabaseClient _client = Supabase.instance.client;
  late final ChessGameRepository _gameRepository;

  ChessboardController? _boardController;
  Position _position = Chess.initial;

  Move? _lastMove;

  RealtimeChannel? _gameChannel;
  Timer? _clockTimer;

  String? _whitePlayerId;
  String? _blackPlayerId;

  String _opponentName = 'Opponent';
  int _opponentRating = 1000;

  int _whiteTimeMs = 0;
  int _blackTimeMs = 0;
  int _initialTimeSeconds = 600;
  int _incrementSeconds = 5;

  String? _currentTurn;
  String? _status;
  String? _result;
  int _stateVersion = -1;

  bool _loading = true;
  bool _submittingMove = false;
  bool _resigning = false;
  bool _drawSubmitting = false;
  bool _timeoutSubmitting = false;
  bool _resultDialogShown = false;
  bool _boardFlipped = false;
  String? _pendingDrawOfferId;
  String? _drawOfferDialogShownFor;

  final List<_PlayedMove> _moves = [];

  String get _myUserId => _client.auth.currentUser?.id ?? '';

  bool get _isWhite => _whitePlayerId == _myUserId;

  bool get _isBlack => _blackPlayerId == _myUserId;

  bool get _isSpectator => !_isWhite && !_isBlack;

  Side get _mySide {
    if (_isBlack) {
      return Side.black;
    }

    return Side.white;
  }

  bool get _isFinished =>
      _status == 'completed' ||
      _status == 'abandoned' ||
      _status == 'cancelled';

  bool get _myTurn =>
      !_isFinished &&
      ((_currentTurn == 'white' && _isWhite) ||
          (_currentTurn == 'black' && _isBlack));

  bool get _gameHasStarted => _status == 'active' || _currentTurn != null;

  String get _reviewResultLabel {
    if (_result == 'draw') {
      return 'Draw';
    }

    final won =
        (_result == 'white' && _isWhite) || (_result == 'black' && _isBlack);

    return won ? 'Victory' : 'Defeat';
  }

  @override
  void initState() {
    super.initState();

    _gameRepository = ChessGameRepository(client: _client);
    WidgetsBinding.instance.addObserver(this);

    _loadGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _clockTimer?.cancel();

    final channel = _gameChannel;
    _gameChannel = null;

    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }

    _boardController?.dispose();
    _boardController = null;

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshGame());
    }
  }

  Future<void> _loadGame() async {
    try {
      final game = await _client
          .from('games')
          .select()
          .eq('id', widget.gameId)
          .single();

      if (!mounted) {
        return;
      }

      await _applyGame(Map<String, dynamic>.from(game), loadMoves: true);

      if (!mounted) {
        return;
      }

      await _loadOpponent();

      if (!mounted) {
        return;
      }

      _subscribeToGame();
      unawaited(_loadPendingDrawOffer());

      setState(() {
        _loading = false;
      });

      _syncBoard(animate: false, resetPremove: true);

      if (_isFinished) {
        _showResultDialog();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showError('Unable to load game: $error');
    }
  }

  Future<void> _refreshGame() async {
    try {
      final game = await _client
          .from('games')
          .select()
          .eq('id', widget.gameId)
          .single();

      if (!mounted) {
        return;
      }

      final gameMap = Map<String, dynamic>.from(game);
      final incomingStateVersion =
          (gameMap['state_version'] as num?)?.toInt() ?? _stateVersion;

      if (incomingStateVersion < _stateVersion) {
        return;
      }

      await _applyGame(gameMap, loadMoves: true);

      if (!mounted) {
        return;
      }

      _syncBoard(animate: false, resetPremove: true);

      if (_isFinished) {
        _showResultDialog();
      }
    } catch (_) {
      // Realtime remains the primary update mechanism.
    }
  }

  Future<void> _loadOpponent() async {
    final opponentId = _isWhite ? _blackPlayerId : _whitePlayerId;

    if (opponentId == null || opponentId.isEmpty) {
      return;
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('display_name,username,chess_rating')
          .eq('id', opponentId)
          .maybeSingle();

      if (profile == null || !mounted) {
        return;
      }

      final name =
          (profile['display_name'] ?? profile['username'] ?? 'Opponent')
              .toString();

      final rating = (profile['chess_rating'] as num?)?.toInt() ?? 1000;

      setState(() {
        _opponentName = name;
        _opponentRating = rating;
      });
    } catch (_) {
      // Keep safe fallback values.
    }
  }

  Future<void> _applyGame(
    Map<String, dynamic> game, {
    bool loadMoves = false,
  }) async {
    _whitePlayerId = game['white_player_id'] as String?;
    _blackPlayerId = game['black_player_id'] as String?;

    _initialTimeSeconds =
        (game['initial_time_seconds'] as num?)?.toInt() ?? 600;
    _incrementSeconds = (game['increment_seconds'] as num?)?.toInt() ?? 5;

    _whiteTimeMs =
        (game['white_time_ms'] as num?)?.toInt() ?? _initialTimeSeconds * 1000;

    _blackTimeMs =
        (game['black_time_ms'] as num?)?.toInt() ?? _initialTimeSeconds * 1000;

    _currentTurn = game['current_turn'] as String?;
    _status = game['status'] as String?;
    _result = game['result'] as String?;
    _stateVersion = (game['state_version'] as num?)?.toInt() ?? _stateVersion;

    final fen = game['current_fen'] as String?;

    if (fen != null && fen.isNotEmpty) {
      try {
        _position = Chess.fromSetup(Setup.parseFen(fen));
      } catch (_) {
        _position = Chess.initial;
      }
    } else {
      _position = Chess.initial;
    }

    if (loadMoves) {
      await _loadMoveHistory();
    }

    _startClock();
  }

  Future<void> _applyModel(ChessGameModel game) {
    return _applyGame({
      'white_player_id': game.whitePlayerId,
      'black_player_id': game.blackPlayerId,
      'initial_time_seconds': game.initialTimeSeconds,
      'increment_seconds': game.incrementSeconds,
      'white_time_ms': game.whiteTimeMs,
      'black_time_ms': game.blackTimeMs,
      'current_turn': game.currentTurn,
      'status': game.status,
      'result': game.result,
      'current_fen': game.currentFen,
      'state_version': game.stateVersion,
    }, loadMoves: true);
  }

  Future<void> _loadMoveHistory() async {
    try {
      final rows = await _client
          .from('game_moves')
          .select('move_number,color,san,uci,fen_after,remaining_time_ms')
          .eq('game_id', widget.gameId)
          .order('ply', ascending: true);

      final loadedMoves = <_PlayedMove>[];

      for (final row in rows) {
        loadedMoves.add(
          _PlayedMove(
            moveNumber: (row['move_number'] as num).toInt(),
            color: row['color'].toString(),
            san: row['san'].toString(),
            uci: row['uci']?.toString(),
            fenAfter: row['fen_after']?.toString(),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _moves
          ..clear()
          ..addAll(loadedMoves);
      });

      if (_moves.isNotEmpty) {
        final lastUci = _moves.last.uci;

        if (lastUci != null && lastUci.isNotEmpty) {
          try {
            _lastMove = _parseUciMove(lastUci);
          } catch (_) {
            _lastMove = null;
          }
        }
      }
    } catch (_) {
      // Move history should never prevent the game board from loading.
    }
  }

  Move _parseUciMove(String uci) {
    if (uci.length < 4) {
      throw const FormatException('Invalid UCI move.');
    }

    final from = Square.fromName(uci.substring(0, 2));
    final to = Square.fromName(uci.substring(2, 4));

    return NormalMove(from: from, to: to);
  }

  GameData _buildBoardGame() {
    final playerSide = _isSpectator
        ? PlayerSide.none
        : _mySide == Side.white
        ? PlayerSide.white
        : PlayerSide.black;

    return GameData(
      fen: _position.fen,
      playerSide: playerSide,
      sideToMove: _position.turn,
      validMoves: makeLegalMoves(_position),
      lastMove: _lastMove,
      kingSquareInCheck: _position.isCheck
          ? _position.board.kingOf(_position.turn)
          : null,
    );
  }

  void _syncBoard({bool animate = true, bool resetPremove = false}) {
    if (!mounted) {
      return;
    }

    final game = _buildBoardGame();

    final controller = _boardController;

    if (controller == null) {
      _boardController = ChessboardController(game: game);
      return;
    }

    controller.updatePosition(
      game,
      animate: animate,
      resetPremove: resetPremove,
    );
  }

  void _subscribeToGame() {
    final oldChannel = _gameChannel;

    if (oldChannel != null) {
      unawaited(_client.removeChannel(oldChannel));
    }

    _gameChannel = _client
        .channel('game:${widget.gameId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'games',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.gameId,
          ),
          callback: (payload) {
            final record = payload.newRecord;

            if (record.isEmpty || !mounted) {
              return;
            }

            unawaited(
              _handleRemoteGameUpdate(Map<String, dynamic>.from(record)),
            );
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_draw_offers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'game_id',
            value: widget.gameId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty && mounted) {
              unawaited(
                _handleDrawOffer(
                  GameDrawOffer.fromMap(Map<String, dynamic>.from(record)),
                ),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'game_draw_offers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'game_id',
            value: widget.gameId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isNotEmpty && mounted) {
              unawaited(_loadPendingDrawOffer());
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadPendingDrawOffer() async {
    try {
      final offer = await _gameRepository.getPendingDrawOffer(widget.gameId);
      if (offer != null) {
        await _handleDrawOffer(offer);
      } else if (mounted) {
        setState(() {
          _pendingDrawOfferId = null;
        });
      }
    } catch (_) {
      // Offer visibility is supplementary; the game state remains authoritative.
    }
  }

  Future<void> _handleDrawOffer(GameDrawOffer offer) async {
    if (!mounted ||
        offer.status != 'pending' ||
        offer.stateVersion != _stateVersion) {
      return;
    }

    setState(() {
      _pendingDrawOfferId = offer.id;
    });

    if (offer.offeredTo != _myUserId ||
        _drawOfferDialogShownFor == offer.id ||
        _isFinished) {
      return;
    }

    _drawOfferDialogShownFor = offer.id;
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Draw offered',
          style: TextStyle(
            fontSize: 20,
            color: _primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Your opponent offered a draw.',
          style: TextStyle(fontSize: 20, color: _secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    try {
      final game = await _gameRepository.respondToDrawOffer(
        offerId: offer.id,
        accept: accept == true,
      );

      if (accept == true) {
        await _applyModel(game);
        _syncBoard(animate: false, resetPremove: true);
        _showResultDialog();
      } else {
        setState(() {
          _pendingDrawOfferId = null;
        });
      }
    } catch (error) {
      _showError('Draw response failed: $error');
      unawaited(_refreshGame());
    }
  }

  Future<void> _handleRemoteGameUpdate(Map<String, dynamic> game) async {
    if (!mounted) {
      return;
    }

    final incomingStateVersion =
        (game['state_version'] as num?)?.toInt() ?? _stateVersion;

    if (incomingStateVersion <= _stateVersion) {
      return;
    }

    final incomingFen = game['current_fen'] as String?;
    final previousFen = _position.fen;

    final incomingWhitePlayerId = game['white_player_id'] as String?;
    final incomingBlackPlayerId = game['black_player_id'] as String?;

    final positionChanged =
        incomingFen != null &&
        incomingFen.isNotEmpty &&
        incomingFen != previousFen;

    await _applyGame(game, loadMoves: positionChanged);

    if (!mounted) {
      return;
    }

    if (positionChanged) {
      try {
        _position = Chess.fromSetup(Setup.parseFen(incomingFen));
      } catch (_) {
        return;
      }

      _syncBoard(animate: true, resetPremove: true);
    } else {
      _syncBoard(animate: false, resetPremove: false);
    }

    if (incomingWhitePlayerId != _whitePlayerId ||
        incomingBlackPlayerId != _blackPlayerId) {
      unawaited(_loadOpponent());
    }

    setState(() {});

    if (_isFinished) {
      _showResultDialog();
    }
  }

  void _startClock() {
    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _isFinished || _currentTurn == null) {
        return;
      }

      final isWhiteTurn = _currentTurn == 'white';

      setState(() {
        if (isWhiteTurn) {
          _whiteTimeMs = math.max(0, _whiteTimeMs - 100);
        } else {
          _blackTimeMs = math.max(0, _blackTimeMs - 100);
        }
      });

      if ((_isWhite && _whiteTimeMs == 0) || (_isBlack && _blackTimeMs == 0)) {
        if (!_timeoutSubmitting) {
          _timeoutSubmitting = true;
          unawaited(_submitTimeout());
        }
      }
    });
  }

  Future<void> _submitTimeout() async {
    try {
      final game = await _gameRepository.expireGameOnTimeout(widget.gameId);
      if (!mounted) {
        return;
      }

      await _applyModel(game);
      _syncBoard(animate: false, resetPremove: true);
      _showResultDialog();
    } catch (_) {
      // A concurrent move or refreshed game state may have resolved the clock.
      await _refreshGame();
    } finally {
      _timeoutSubmitting = false;
    }
  }

  Future<void> _onMove(Move move, {bool? viaDragAndDrop}) async {
    if (_submittingMove ||
        _isFinished ||
        !_myTurn ||
        _isSpectator ||
        _boardController == null) {
      return;
    }

    if (!_position.isLegal(move)) {
      return;
    }

    setState(() {
      _submittingMove = true;
    });

    try {
      await _gameRepository.submitMove(gameId: widget.gameId, move: move);

      if (!mounted) {
        return;
      }

      // The committed game row and move are authoritative. Realtime normally
      // delivers them; refresh also covers delayed or unavailable events.
      await _refreshGame();
    } catch (error) {
      if (!mounted) {
        return;
      }

      await _refreshGame();
      if (mounted) {
        _showError(_friendlyMoveError(error));
        _syncBoard(animate: false, resetPremove: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingMove = false;
        });
      }
    }
  }

  Future<void> _resign() async {
    if (_resigning || _isFinished || !_myTurn) {
      return;
    }

    final shouldResign = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Resign game?',
            style: TextStyle(
              fontSize: 20,
              color: _primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to resign this game?',
            style: TextStyle(fontSize: 20, color: _secondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(backgroundColor: _danger),
              child: const Text('Resign'),
            ),
          ],
        );
      },
    );

    if (shouldResign != true || !mounted) {
      return;
    }

    setState(() {
      _resigning = true;
    });

    try {
      final game = await _gameRepository.resignGame(widget.gameId);

      if (!mounted) {
        return;
      }

      await _applyGame({
        'white_player_id': game.whitePlayerId,
        'black_player_id': game.blackPlayerId,
        'initial_time_seconds': game.initialTimeSeconds,
        'increment_seconds': game.incrementSeconds,
        'white_time_ms': game.whiteTimeMs,
        'black_time_ms': game.blackTimeMs,
        'current_turn': game.currentTurn,
        'status': game.status,
        'result': game.result,
        'current_fen': game.currentFen,
        'state_version': game.stateVersion,
      });

      _showResultDialog();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Could not resign: $error');
    } finally {
      if (mounted) {
        setState(() {
          _resigning = false;
        });
      }
    }
  }

  Future<void> _offerDraw() async {
    if (_drawSubmitting ||
        _isFinished ||
        _isSpectator ||
        _pendingDrawOfferId != null) {
      return;
    }

    setState(() {
      _drawSubmitting = true;
    });

    try {
      final offer = await _gameRepository.offerDraw(widget.gameId);
      if (mounted) {
        setState(() {
          _pendingDrawOfferId = offer.id;
        });
        _showInfo('Draw offer sent.');
      }
    } catch (error) {
      if (mounted) {
        _showError('Could not offer a draw: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _drawSubmitting = false;
        });
      }
    }
  }

  void _showResultDialog() {
    if (_resultDialogShown || !mounted) {
      return;
    }

    _resultDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _surface,
          title: Text(
            _reviewResultLabel,
            style: const TextStyle(fontSize: 20, color: _primary),
          ),
          content: const Text(
            'Game complete. Review your recorded moves or exit.',
            style: TextStyle(fontSize: 20, color: _secondary),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameReviewScreen(
                      matchId: widget.gameId,
                      timeControl:
                          '${_initialTimeSeconds ~/ 60}+$_incrementSeconds',
                      result: _reviewResultLabel,
                      opponentName: _opponentName,
                      whitePlayerName: _isWhite ? 'You' : _opponentName,
                      blackPlayerName: _isBlack ? 'You' : _opponentName,
                      winnerSide: _result,
                      moves: _moves.map((move) => move.san).toList(),
                    ),
                  ),
                );
              },
              child: const Text('Review Game'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Exit'),
            ),
          ],
        ),
      );
    });
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface3,
        content: Text(
          message,
          style: const TextStyle(fontSize: 20, color: _primary),
        ),
      ),
    );
  }

  String _friendlyMoveError(Object error) {
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['error'] != null) {
        return switch (details['error'].toString()) {
          'ILLEGAL_MOVE' => 'That move is not legal.',
          'NOT_YOUR_TURN' => 'It is no longer your turn.',
          'STALE_GAME_STATE' => 'The game changed. The board was refreshed.',
          'GAME_NOT_ACTIVE' => 'This game has already finished.',
          'TIMEOUT' => 'Your clock expired before the move was accepted.',
          _ => 'Move could not be submitted.',
        };
      }
    }

    return 'Move could not be submitted. Please try again.';
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surface3,
        content: Text(
          message,
          style: const TextStyle(fontSize: 20, color: _secondary),
        ),
      ),
    );
  }

  String _formatClock(int milliseconds) {
    final totalSeconds = math.max(0, milliseconds ~/ 1000);

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    final controller = _boardController;

    if (controller == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Text(
            'Unable to initialize chess board.',
            style: TextStyle(fontSize: 20, color: _primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            final availableWidth = constraints.maxWidth - 24;

            final availableHeight =
                constraints.maxHeight - (isLandscape ? 170 : 310);

            final boardSize = math
                .min(availableWidth, availableHeight)
                .clamp(220.0, 760.0)
                .toDouble();

            if (isLandscape) {
              return _buildLandscape(context, boardSize);
            }

            return _buildPortrait(context, boardSize);
          },
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context, double boardSize) {
    return Column(
      children: [
        _buildTopBar(),
        _buildGameMeta(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildPlayerBar(
            name: _opponentName,
            rating: _opponentRating,
            clock: _isWhite
                ? _formatClock(_blackTimeMs)
                : _formatClock(_whiteTimeMs),
            isActive: !_myTurn && !_isFinished,
            isOpponent: true,
          ),
        ),

        const SizedBox(height: 6),

        Expanded(child: Center(child: _buildBoard(boardSize))),

        _buildMoveHistory(),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildPlayerBar(
            name: 'You',
            rating: 0,
            clock: _isWhite
                ? _formatClock(_whiteTimeMs)
                : _formatClock(_blackTimeMs),
            isActive: _myTurn && !_isFinished,
            isOpponent: false,
          ),
        ),

        const SizedBox(height: 6),

        _buildActionBar(),
      ],
    );
  }

  Widget _buildLandscape(BuildContext context, double boardSize) {
    return Column(
      children: [
        _buildTopBar(),
        _buildGameMeta(),

        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPlayerBar(
                        name: _opponentName,
                        rating: _opponentRating,
                        clock: _isWhite
                            ? _formatClock(_blackTimeMs)
                            : _formatClock(_whiteTimeMs),
                        isActive: !_myTurn && !_isFinished,
                        isOpponent: true,
                      ),
                      const SizedBox(height: 12),
                      _buildPlayerBar(
                        name: 'You',
                        rating: 0,
                        clock: _isWhite
                            ? _formatClock(_whiteTimeMs)
                            : _formatClock(_blackTimeMs),
                        isActive: _myTurn && !_isFinished,
                        isOpponent: false,
                      ),
                    ],
                  ),
                ),
              ),

              _buildBoard(boardSize),

              Expanded(child: _buildLandscapeActions()),
            ],
          ),
        ),

        _buildMoveHistory(),
      ],
    );
  }

  Widget _buildBoard(double size) {
    final controller = _boardController;

    if (controller == null) {
      return SizedBox(width: size, height: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Chessboard(
        controller: controller,
        size: size,
        settings: const ChessboardSettings(
          colorScheme: ChessboardColorScheme.green,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          enableCoordinates: true,
        ),
        orientation: _boardFlipped
            ? (_mySide == Side.white ? Side.black : Side.white)
            : _mySide,
        onMove: _onMove,
      ),
    );
  }

  Widget _buildMoveHistory() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Row(
        children: [
          const Text(
            'MOVES',
            style: TextStyle(
              fontSize: 20,
              color: _muted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _moves.isEmpty
                ? const Text(
                    'No moves yet',
                    style: TextStyle(fontSize: 20, color: _muted),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (int i = 0; i < _moves.length; i++) ...[
                          _buildSingleMove(_moves[i]),
                          if (i != _moves.length - 1) const SizedBox(width: 18),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMove(_PlayedMove move) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${move.moveNumber}${move.color == 'white' ? '.' : '...'}',
          style: const TextStyle(
            fontSize: 20,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          move.san,
          style: TextStyle(
            fontSize: 20,
            color: move.color == 'white' ? _primary : _secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          ),

          const SizedBox(width: 4),

          const Expanded(
            child: Text(
              'Active Game Session',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                color: _primary,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (_gameHasStarted && !_isFinished)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: _green),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 20,
                      color: _green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

          if (_submittingMove) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameMeta() {
    final minutes = _initialTimeSeconds ~/ 60;
    final label = minutes <= 3
        ? 'Bullet'
        : minutes <= 5
        ? 'Blitz'
        : minutes <= 15
        ? 'Rapid'
        : 'Classical';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: _green),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${label.toUpperCase()}  ·  $minutes+$_incrementSeconds',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                color: _blue,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _surface3,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: _blue),
                const SizedBox(width: 5),
                Text(
                  'Turn ${_moves.isEmpty ? 1 : _moves.last.moveNumber + (_moves.last.color == 'black' ? 1 : 0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerBar({
    required String name,
    required int rating,
    required String clock,
    required bool isActive,
    required bool isOpponent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? _surface3 : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _blue.withAlpha(120) : Colors.white.withAlpha(12),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isOpponent ? _surface3 : _blue.withAlpha(30),
            child: Text(
              name.trim().isEmpty
                  ? '?'
                  : name.trim().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: _blue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (rating > 0)
                  Text(
                    '$rating rating',
                    style: const TextStyle(fontSize: 20, color: _muted),
                  ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? _blue : const Color(0xFF0C1424),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              clock,
              style: TextStyle(
                fontSize: 20,
                color: isActive ? Colors.white : _primary,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.handshake_outlined,
              label: 'Draw',
              onPressed: _isFinished || _drawSubmitting ? null : _offerDraw,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _actionButton(
              icon: Icons.flag_outlined,
              label: 'Resign',
              danger: true,
              onPressed: _resigning || _isFinished || !_myTurn ? null : _resign,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _actionButton(
              icon: Icons.flip_rounded,
              label: 'Flip',
              onPressed: () => setState(() => _boardFlipped = !_boardFlipped),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionButton(
            icon: Icons.flag_outlined,
            label: 'Resign',
            danger: true,
            onPressed: _resigning || _isFinished || !_myTurn ? null : _resign,
          ),

          const SizedBox(height: 10),

          _actionButton(
            icon: Icons.handshake_outlined,
            label: 'Draw',
            onPressed: _isFinished || _drawSubmitting ? null : _offerDraw,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool danger = false,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger ? _danger : _secondary,
          side: BorderSide(
            color: danger ? _danger.withAlpha(100) : Colors.white.withAlpha(20),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PlayedMove {
  const _PlayedMove({
    required this.moveNumber,
    required this.color,
    required this.san,
    this.uci,
    this.fenAfter,
  });

  final int moveNumber;
  final String color;
  final String san;
  final String? uci;
  final String? fenAfter;
}
