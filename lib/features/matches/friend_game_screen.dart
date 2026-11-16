import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../match/chess_match_screen.dart';
import 'matchmaking_repository.dart';

class FriendGameScreen extends StatefulWidget {
  const FriendGameScreen({super.key});

  @override
  State<FriendGameScreen> createState() => _FriendGameScreenState();
}

class _FriendGameScreenState extends State<FriendGameScreen> {
  final MatchmakingRepository _repository = MatchmakingRepository();
  final TextEditingController _gameIdController = TextEditingController();

  String? _createdGameId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _gameIdController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final game = await _repository.createFriendGame();
      if (!mounted) return;
      setState(() {
        _createdGameId = game['id']?.toString();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not create the friend game: $error';
      });
    }
  }

  Future<void> _joinGame() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final game = await _repository.joinFriendGame(_gameIdController.text);
      final gameId = game['id']?.toString();
      if (!mounted || gameId == null || gameId.isEmpty) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChessMatchScreen(gameId: gameId)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not join this game: $error';
      });
    }
  }

  void _openCreatedGame() {
    final gameId = _createdGameId;
    if (gameId == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChessMatchScreen(gameId: gameId)));
  }

  Future<void> _shareGame() async {
    final gameId = _createdGameId;
    if (gameId == null) return;
    await Share.share(
      'Join my SQI Chess game. Copy this Game ID into Play with Friend:\n$gameId',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play with a friend')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create a game, send the Game ID to your friend, then keep the game open while they join.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loading ? null : _createGame,
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Create game'),
          ),
          if (_createdGameId != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Game ID'),
                    const SizedBox(height: 8),
                    SelectableText(
                      _createdGameId!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _shareGame,
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Send ID'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: _openCreatedGame,
                            child: const Text('Open game'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          const Text(
            'Join a friend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _gameIdController,
            decoration: const InputDecoration(
              labelText: 'Game ID',
              hintText: 'Paste the ID your friend sent',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _joinGame,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Join game'),
          ),
          if (_loading) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 18),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ],
      ),
    );
  }
}
