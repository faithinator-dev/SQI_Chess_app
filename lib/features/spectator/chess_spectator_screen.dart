import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChessSpectatorScreen extends StatefulWidget {
  const ChessSpectatorScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<ChessSpectatorScreen> createState() => _ChessSpectatorScreenState();
}

class _ChessSpectatorScreenState extends State<ChessSpectatorScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFEDE9E2);
  static const Color surface3 = Color(0xFFE8F0EC);

  static const Color blue = Color(0xFF2D4A3E);
  static const Color green = Color(0xFF557B63);
  static const Color gold = Color(0xFFF5C451);

  static const Color primary = Color(0xFF1A1A1A);
  static const Color secondary = Color(0xFF454B46);
  static const Color muted = Color(0xFF737A74);

  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _gameChannel;
  RealtimeChannel? _movesChannel;

  Timer? _clockTimer;

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _game;

  Position _position = Chess.initial;

  List<_SpectatorMove> _moves = <_SpectatorMove>[];

  int _whiteTimeMs = 0;
  int _blackTimeMs = 0;

  String _currentTurn = 'white';

  final int _spectatorCount = 0;

  @override
  void initState() {
    super.initState();
    _loadGame();
    _subscribeToGame();
    _subscribeToMoves();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();

    final gameChannel = _gameChannel;
    final movesChannel = _movesChannel;

    if (gameChannel != null) {
      _supabase.removeChannel(gameChannel);
    }

    if (movesChannel != null) {
      _supabase.removeChannel(movesChannel);
    }

    super.dispose();
  }

  Future<void> _loadGame() async {
    try {
      final game = await _supabase
          .from('games')
          .select()
          .eq('id', widget.gameId)
          .single();

      if (!mounted) return;

      setState(() {
        _game = Map<String, dynamic>.from(game);
        _applyGameState(_game!);
        _loading = false;
      });

      await _loadMoves();
      _startClock();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadMoves() async {
    try {
      final rows = await _supabase
          .from('game_moves')
          .select()
          .eq('game_id', widget.gameId)
          .order('ply', ascending: true);

      final loadedMoves = rows
          .map((row) => _SpectatorMove.fromMap(Map<String, dynamic>.from(row)))
          .toList();

      if (!mounted) return;

      setState(() {
        _moves = loadedMoves;
      });
    } catch (_) {
      // Keep the spectator board usable even if move history fails.
    }
  }

  void _applyGameState(Map<String, dynamic> game) {
    final fen = game['current_fen']?.toString();

    if (fen != null && fen.trim().isNotEmpty) {
      try {
        _position = Chess.fromSetup(Setup.parseFen(fen));
      } catch (_) {
        _position = Chess.initial;
      }
    }

    _whiteTimeMs = _readInt(game['white_time_ms']);
    _blackTimeMs = _readInt(game['black_time_ms']);

    final turn = game['current_turn']?.toString();

    if (turn == 'white' || turn == 'black') {
      _currentTurn = turn!;
    }
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  void _subscribeToGame() {
    _gameChannel = _supabase
        .channel('spectator-game:${widget.gameId}')
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
            final newRecord = payload.newRecord;

            if (!mounted || newRecord.isEmpty) return;

            setState(() {
              _game = Map<String, dynamic>.from(newRecord);
              _applyGameState(_game!);
            });
          },
        );

    _gameChannel!.subscribe();
  }

  void _subscribeToMoves() {
    _movesChannel = _supabase
        .channel('spectator-moves:${widget.gameId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'game_moves',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'game_id',
            value: widget.gameId,
          ),
          callback: (_) {
            _loadMoves();
          },
        );

    _movesChannel!.subscribe();
  }

  void _startClock() {
    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;

      if (_currentTurn == 'white' && _whiteTimeMs > 0) {
        setState(() {
          _whiteTimeMs = (_whiteTimeMs - 100).clamp(0, 1 << 60);
        });
      }

      if (_currentTurn == 'black' && _blackTimeMs > 0) {
        setState(() {
          _blackTimeMs = (_blackTimeMs - 100).clamp(0, 1 << 60);
        });
      }
    });
  }

  String get _whiteName {
    final playerId = _game?['white_player_id'];

    if (playerId == null) {
      return 'White';
    }

    return 'White';
  }

  String get _blackName {
    final playerId = _game?['black_player_id'];

    if (playerId == null) {
      return 'Black';
    }

    return 'Black';
  }

  String get _gameStatus {
    return (_game?['status'] ?? 'active').toString();
  }

  String get _timeControl {
    return (_game?['time_control'] ?? '—').toString();
  }

  String _formatClock(int milliseconds) {
    final totalSeconds = milliseconds <= 0 ? 0 : milliseconds ~/ 1000;

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  List<_MovePair> get _movePairs {
    final pairs = <_MovePair>[];

    for (var i = 0; i < _moves.length; i += 2) {
      final white = _moves[i];

      final black = i + 1 < _moves.length ? _moves[i + 1] : null;

      pairs.add(
        _MovePair(number: (i ~/ 2) + 1, white: white.san, black: black?.san),
      );
    }

    return pairs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: blue))
            : _error != null
            ? _buildError()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;

                  if (isLandscape) {
                    return _buildLandscape(constraints);
                  }

                  return _buildPortrait(constraints);
                },
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_off_rounded, color: muted, size: 42),
              const SizedBox(height: 16),
              const Text(
                'Unable to load game',
                style: TextStyle(
                  color: primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });

                  _loadGame();
                },
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(BoxConstraints constraints) {
    return Column(
      children: [
        _buildTopBar(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildOpponent(
            name: _blackName,
            clock: _formatClock(_blackTimeMs),
            isWhite: false,
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildBoard(),
          ),
        ),

        _buildMoveHistory(),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _buildOpponent(
            name: _whiteName,
            clock: _formatClock(_whiteTimeMs),
            isWhite: true,
          ),
        ),

        _buildSpectatorBar(),
      ],
    );
  }

  Widget _buildLandscape(BoxConstraints constraints) {
    return Column(
      children: [
        _buildTopBar(),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                  child: _buildBoard(),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
                  child: Column(
                    children: [
                      _buildOpponent(
                        name: _blackName,
                        clock: _formatClock(_blackTimeMs),
                        isWhite: false,
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildHistoryPanel()),
                      const SizedBox(height: 8),
                      _buildOpponent(
                        name: _whiteName,
                        clock: _formatClock(_whiteTimeMs),
                        isWhite: true,
                      ),
                      const SizedBox(height: 8),
                      _buildSpectatorBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: primary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.visibility_rounded, color: blue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'SPECTATOR',
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: Row(
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
                  Text(
                    _timeControl,
                    style: const TextStyle(
                      color: secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Widget _buildOpponent({
    required String name,
    required String clock,
    required bool isWhite,
  }) {
    final isActive = _currentTurn == (isWhite ? 'white' : 'black');

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? blue.withAlpha(100) : Colors.white.withAlpha(10),
          width: isActive ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isWhite ? Colors.white : surface3,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 18,
              color: isWhite ? background : primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isActive)
                  const Text(
                    'THINKING',
                    style: TextStyle(
                      color: green,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            clock,
            style: TextStyle(
              color: isActive ? primary : secondary,
              fontSize: 21,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest.shortestSide;

              return StaticChessboard(
                size: size,
                orientation: Side.white,
                fen: _position.fen,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHistory() {
    return SizedBox(height: 48, child: _buildHistoryPanel(horizontal: true));
  }

  Widget _buildHistoryPanel({bool horizontal = false}) {
    return Container(
      margin: horizontal
          ? const EdgeInsets.symmetric(horizontal: 12)
          : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: _moves.isEmpty
          ? const Center(
              child: Text(
                'No moves yet',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _movePairs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final pair = _movePairs[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: surface2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${pair.number}.',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        pair.white,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pair.black ?? '—',
                        style: const TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSpectatorBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, color: muted, size: 18),
          const SizedBox(width: 8),
          Text(
            '$_spectatorCount watching',
            style: const TextStyle(
              color: secondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _gameStatus == 'active'
                  ? green.withAlpha(18)
                  : gold.withAlpha(18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              _gameStatus.toUpperCase(),
              style: TextStyle(
                color: _gameStatus == 'active' ? green : gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectatorMove {
  const _SpectatorMove({required this.ply, required this.san});

  final int ply;
  final String san;

  factory _SpectatorMove.fromMap(Map<String, dynamic> map) {
    return _SpectatorMove(
      ply: (map['ply'] as num?)?.toInt() ?? 0,
      san: (map['san'] ?? '').toString(),
    );
  }
}

class _MovePair {
  const _MovePair({
    required this.number,
    required this.white,
    required this.black,
  });

  final int number;
  final String white;
  final String? black;
}
