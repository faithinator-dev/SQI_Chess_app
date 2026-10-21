import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

class GameReviewScreen extends StatefulWidget {
  const GameReviewScreen({
    super.key,
    this.opponentName = 'Opponent',
    this.opponentRating = 0,
    this.result = 'Game review',
    this.matchId = 'Local game',
    this.timeControl = 'Unknown',
    this.date = 'Not available',
    this.moves = const [],
    this.whitePlayerName = 'White',
    this.blackPlayerName = 'Black',
    this.winnerSide,
  });

  final String opponentName;
  final int opponentRating;
  final String result;
  final String matchId;
  final String timeControl;
  final String date;
  final List<String> moves;
  final String whitePlayerName;
  final String blackPlayerName;
  final String? winnerSide;

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  static const Color background = Color(0xFFF9F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFEDE9E2);
  static const Color blue = Color(0xFF2D4A3E);
  static const Color muted = Color(0xFF737A74);
  static const Color green = Color(0xFF557B63);
  // static const Color gold = Color(0xFFF5C451);
  static const Color danger = Color(0xFFFF5C70);

  List<String> get _moves => widget.moves;

  late final List<Position> _positions;
  late final List<Move?> _lastMoves;
  int? _invalidMoveAt;

  int _currentMove = 0;

  @override
  void initState() {
    super.initState();
    _buildReplayPositions();
  }

  void _buildReplayPositions() {
    final positions = <Position>[Chess.initial];
    final lastMoves = <Move?>[null];

    Position position = Chess.initial;
    Move? previousMove;

    for (final san in _moves) {
      Move? move;
      try {
        move = position.parseSan(san);
      } catch (_) {
        move = null;
      }

      if (move == null) {
        _invalidMoveAt = positions.length;
        break;
      }

      position = position.play(move);

      positions.add(position);
      previousMove = move;
      lastMoves.add(previousMove);
    }

    _positions = positions;
    _lastMoves = lastMoves;
  }

  Position get _currentPosition {
    return _positions[_currentMove];
  }

  Move? get _currentLastMove {
    return _lastMoves[_currentMove];
  }

  void _goToMove(int moveNumber) {
    if (moveNumber < 0 || moveNumber >= _positions.length) {
      return;
    }

    setState(() {
      _currentMove = moveNumber;
    });
  }

  void _previousMove() {
    if (_currentMove > 0) {
      _goToMove(_currentMove - 1);
    }
  }

  void _nextMove() {
    if (_currentMove < _positions.length - 1) {
      _goToMove(_currentMove + 1);
    }
  }

  void _firstMove() {
    _goToMove(0);
  }

  void _lastMoveButton() {
    _goToMove(_positions.length - 1);
  }

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
                'Game Review',
                style: TextStyle(
                  fontSize: 20,
                  color: blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Review every move',
                style: TextStyle(
                  fontSize: 20,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _iconButton(
          icon: Icons.share_rounded,
          onTap: () {
            _showMessage('Share coming soon');
          },
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildBoardSection(context)),
              const SizedBox(width: 24),
              SizedBox(width: 390, child: _buildReviewPanel(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          _buildPlayerHeader(),
          const SizedBox(height: 14),
          _buildBoardSection(context),
          const SizedBox(height: 16),
          _buildMoveList(),
          const SizedBox(height: 16),
          _buildGameDetails(),
        ],
      ),
    );
  }

  Widget _buildBoardSection(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final maxBoardSize = width >= 1000
        ? 760.0
        : width >= 700
        ? 620.0
        : width - 32;

    return Column(
      children: [
        if (width >= 1000) _buildPlayerHeader(),
        if (width >= 1000) const SizedBox(height: 14),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: StaticChessboard(
                key: ValueKey(_currentMove),
                size: maxBoardSize,
                orientation: Side.white,
                fen: _currentPosition.fen,
                lastMove: _currentLastMove,
                settings: StaticChessboardSettings(
                  enableCoordinates: true,
                  showLastMove: true,
                  borderRadius: BorderRadius.circular(18),
                  colorScheme: ChessboardColorScheme.brown,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildMoveControls(),
      ],
    );
  }

  Widget _buildPlayerHeader() {
    return Row(
      children: [
        Expanded(
          child: _playerCard(
            name: widget.whitePlayerName,
            rating: 0,
            color: Colors.white,
            score: widget.winnerSide == 'white'
                ? '1'
                : widget.winnerSide == 'draw'
                ? '0.5'
                : '0',
            isWinner: widget.winnerSide == 'white',
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Text(
            'VS',
            style: TextStyle(
              fontSize: 20,
              color: muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _playerCard(
            name: widget.blackPlayerName,
            rating: 0,
            color: const Color(0xFF303A4D),
            score: widget.winnerSide == 'black'
                ? '1'
                : widget.winnerSide == 'draw'
                ? '0.5'
                : '0',
            isWinner: widget.winnerSide == 'black',
          ),
        ),
      ],
    );
  }

  Widget _playerCard({
    required String name,
    required int rating,
    required Color color,
    required String score,
    required bool isWinner,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              Icons.person_rounded,
              color: color == Colors.white
                  ? const Color(0xFFEDE9E2)
                  : Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          color: blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: green,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  rating > 0 ? '$rating rating' : 'Rating unavailable',
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: const TextStyle(
              fontSize: 20,
              color: blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPanel(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildResultCard(),
          const SizedBox(height: 14),
          _buildMoveList(),
          const SizedBox(height: 14),
          _buildGameDetails(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isVictory = widget.result == 'Victory';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isVictory ? green : danger).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVictory ? Icons.emoji_events_rounded : Icons.close_rounded,
              color: isVictory ? green : danger,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result,
                  style: TextStyle(
                    fontSize: 20,
                    color: isVictory ? green : danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _moves.isEmpty
                      ? 'Move history unavailable for this game.'
                      : _invalidMoveAt != null
                      ? 'Replay stops at an invalid recorded move.'
                      : 'Move-by-move replay',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          Text(
            '${_moves.length} moves',
            style: const TextStyle(
              fontSize: 20,
              color: blue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveList() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.format_list_numbered_rounded,
                  color: blue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Move History',
                  style: TextStyle(
                    fontSize: 20,
                    color: blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_moves.length} moves',
                  style: const TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF202B3E), height: 1),
          if (_moves.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 28, 18, 32),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    color: muted,
                    size: 42,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No move history available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This game can still be viewed, but there are no recorded moves to replay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: muted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 330,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: (_moves.length / 2).ceil(),
                itemBuilder: (context, index) {
                  final whiteIndex = index * 2;
                  final blackIndex = whiteIndex + 1;

                  return Row(
                    children: [
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${index + 1}.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _moveTile(
                          moveIndex: whiteIndex,
                          move: _moves[whiteIndex],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: blackIndex < _moves.length
                            ? _moveTile(
                                moveIndex: blackIndex,
                                move: _moves[blackIndex],
                              )
                            : const SizedBox(),
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

  Widget _moveTile({required int moveIndex, required String move}) {
    final selected = _currentMove == moveIndex + 1;

    return GestureDetector(
      onTap: () => _goToMove(moveIndex + 1),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? blue.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
        child: Text(
          move,
          style: TextStyle(
            fontSize: 20,
            color: selected ? Colors.white : const Color(0xFFC5CCDA),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMoveControls() {
    final atBeginning = _currentMove == 0;
    final atEnd = _currentMove == _positions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _controlGroup(
            buttons: [
              _controlButtonData(
                icon: Icons.first_page_rounded,
                enabled: !atBeginning,
                onTap: _firstMove,
              ),
              _controlButtonData(
                icon: Icons.chevron_left_rounded,
                enabled: !atBeginning,
                onTap: _previousMove,
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_currentMove / ${_moves.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'moves',
                  style: TextStyle(fontSize: 20, color: muted),
                ),
              ],
            ),
          ),
          _controlGroup(
            buttons: [
              _controlButtonData(
                icon: Icons.chevron_right_rounded,
                enabled: !atEnd,
                onTap: _nextMove,
              ),
              _controlButtonData(
                icon: Icons.last_page_rounded,
                enabled: !atEnd,
                onTap: _lastMoveButton,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlGroup({required List<Widget> buttons}) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: buttons),
    );
  }

  Widget _controlButtonData({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return _controlButton(icon: icon, enabled: enabled, onTap: onTap);
  }

  Widget _controlButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      color: blue,
      disabledColor: muted.withValues(alpha: 0.45),
      tooltip: enabled ? 'Navigate' : null,
    );
  }

  Widget _buildGameDetails() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Details',
            style: TextStyle(
              fontSize: 20,
              color: blue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(
            icon: Icons.tag_rounded,
            label: 'Match ID',
            value: widget.matchId,
          ),
          _detailRow(
            icon: Icons.timer_outlined,
            label: 'Time Control',
            value: widget.timeControl,
          ),
          _detailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Played',
            value: widget.date,
          ),
          _detailRow(
            icon: Icons.swap_vert_rounded,
            label: 'Moves',
            value: '${_moves.length}',
          ),
          _detailRow(
            icon: Icons.star_outline_rounded,
            label: 'Analysis',
            value: 'Move replay only',
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, color: muted, size: 16),
          const SizedBox(width: 9),
          Text(label, style: const TextStyle(fontSize: 20, color: muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
          child: Icon(icon, color: blue, size: 22),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: surfaceLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
