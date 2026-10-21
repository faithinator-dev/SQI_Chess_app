import 'package:flutter/material.dart';

import 'spectator_chess_board.dart';

class SpectatorReplayScreen extends StatefulWidget {
  final Map<String, dynamic> game;

  const SpectatorReplayScreen({super.key, required this.game});

  @override
  State<SpectatorReplayScreen> createState() => _SpectatorReplayScreenState();
}

class _SpectatorReplayScreenState extends State<SpectatorReplayScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);

  int _currentMove = 0;

  final List<String> _moves = [
    'e4',
    'e5',
    'Nf3',
    'Nc6',
    'Bc4',
    'Nf6',
    'O-O',
    'Be7',
    'Re1',
    'd6',
    'c3',
    'O-O',
  ];

  final List<String> _positions = [
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',

    'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',

    'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',

    'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',

    'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',

    'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3',

    'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',

    'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 5 4',

    'r1bqk2r/ppppbppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQ1RK1 w kq - 6 5',

    'r1bqk2r/ppppbppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQR1K1 b kq - 7 5',

    'r1bqk2r/ppp1bppp/2np1n2/4p3/2B1P3/2P2N2/PP1P1PPP/RNBQR1K1 w kq - 0 6',

    'r1bq1rk1/ppp1bppp/2np1n2/4p3/2B1P3/2P2N2/PP1P1PPP/RNBQR1K1 w - - 0 7',
  ];

  String get _currentFen {
    if (_currentMove < 0 || _currentMove >= _positions.length) {
      return _positions.first;
    }

    return _positions[_currentMove];
  }

  String get _moveLabel {
    if (_currentMove == 0) {
      return 'Starting Position';
    }

    final moveIndex = _currentMove - 1;

    if (moveIndex >= 0 && moveIndex < _moves.length) {
      final moveNumber = (moveIndex ~/ 2) + 1;
      final side = moveIndex.isEven ? 'White' : 'Black';

      return '$moveNumber. $side — ${_moves[moveIndex]}';
    }

    return 'Move $_currentMove';
  }

  void _firstMove() {
    setState(() {
      _currentMove = 0;
    });
  }

  void _previousMove() {
    if (_currentMove <= 0) return;

    setState(() {
      _currentMove--;
    });
  }

  void _nextMove() {
    if (_currentMove >= _positions.length - 1) {
      return;
    }

    setState(() {
      _currentMove++;
    });
  }

  void _lastMove() {
    setState(() {
      _currentMove = _positions.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final whitePlayer = widget.game['white']?.toString() ?? 'Faith Toluwanimi';

    final blackPlayer = widget.game['black']?.toString() ?? 'Daniel Ade';

    final matchId = widget.game['id']?.toString() ?? '#SQA-28491';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Game Review',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1000;

            return SingleChildScrollView(
              padding: EdgeInsets.all(desktop ? 28 : 16),
              child: desktop
                  ? _desktopLayout(whitePlayer, blackPlayer, matchId)
                  : _mobileLayout(whitePlayer, blackPlayer, matchId),
            );
          },
        ),
      ),
    );
  }

  Widget _desktopLayout(
    String whitePlayer,
    String blackPlayer,
    String matchId,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1350),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: _boardPanel(whitePlayer, blackPlayer)),
            const SizedBox(width: 24),
            Expanded(flex: 3, child: _movePanel(matchId)),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(String whitePlayer, String blackPlayer, String matchId) {
    return Column(
      children: [
        _boardPanel(whitePlayer, blackPlayer),
        const SizedBox(height: 20),
        _movePanel(matchId),
      ],
    );
  }

  Widget _boardPanel(String whitePlayer, String blackPlayer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _player(blackPlayer, 'BLACK', 'K'),
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SpectatorChessBoard(
                fen: _currentFen,
                showCoordinates: true,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _player(whitePlayer, 'WHITE', 'K'),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: blue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _moveLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$_currentMove / ${_positions.length - 1}',
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _player(String name, String side, String piece) {
    final isWhite = side == 'WHITE';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(piece, style: const TextStyle(fontSize: 15)),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                side,
                style: TextStyle(
                  fontSize: 20,
                  color: isWhite ? blue : muted,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _movePanel(String matchId) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GAME REVIEW',
            style: TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            matchId,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _progressBar(),
          const SizedBox(height: 18),
          _moveList(),
          const SizedBox(height: 18),
          _controls(),
        ],
      ),
    );
  }

  Widget _progressBar() {
    final total = _positions.length - 1;

    final progress = total == 0 ? 0.0 : _currentMove / total;

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontSize: 20, color: muted),
            ),
            const Spacer(),
            Text(
              '${(_currentMove / 2).ceil()} / ${(_moves.length / 2).ceil()} moves',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: const AlwaysStoppedAnimation<Color>(blue),
          ),
        ),
      ],
    );
  }

  Widget _moveList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: (_moves.length / 2).ceil(),
        itemBuilder: (context, index) {
          final whiteIndex = index * 2;
          final blackIndex = whiteIndex + 1;

          final whiteMove = _moves[whiteIndex];

          final blackMove = blackIndex < _moves.length
              ? _moves[blackIndex]
              : '—';

          final isWhiteSelected = _currentMove == whiteIndex + 1;

          final isBlackSelected = _currentMove == blackIndex + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${index + 1}.',
                    style: const TextStyle(fontSize: 20, color: muted),
                  ),
                ),
                Expanded(
                  child: _moveButton(
                    whiteMove,
                    isWhiteSelected,
                    whiteIndex + 1,
                  ),
                ),
                Expanded(
                  child: _moveButton(
                    blackMove,
                    isBlackSelected,
                    blackIndex + 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _moveButton(String move, bool selected, int position) {
    return GestureDetector(
      onTap: () {
        if (position < _positions.length) {
          setState(() {
            _currentMove = position;
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          move,
          style: TextStyle(
            fontSize: 20,
            color: selected ? Colors.white : muted,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Row(
      children: [
        _controlButton(Icons.first_page_rounded, _firstMove),
        const SizedBox(width: 8),
        _controlButton(Icons.chevron_left_rounded, _previousMove),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _nextMove,
            icon: const Icon(Icons.play_arrow_rounded, size: 19),
            label: const Text('Next Move'),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _controlButton(Icons.chevron_right_rounded, _nextMove),
        const SizedBox(width: 8),
        _controlButton(Icons.last_page_rounded, _lastMove),
      ],
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 42,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
