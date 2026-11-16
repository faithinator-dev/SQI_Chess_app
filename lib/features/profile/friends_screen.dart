import 'package:flutter/material.dart';

import '../../core/repositories/friends_repository.dart';
import '../match/chess_match_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsRepository _repository = FriendsRepository();
  final TextEditingController _searchController = TextEditingController();
  List<FriendRecord> _relationships = [];
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final relationships = await _repository.getRelationships();
      final invitations = await _repository.getInvitations();
      if (!mounted) {
        return;
      }
      setState(() {
        _relationships = relationships;
        _invitations = invitations;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load friends: $error';
      });
    }
  }

  Future<void> _search() async {
    try {
      final results = await _repository.searchPlayers(_searchController.text);
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = 'Search failed: $error');
    }
  }

  Future<void> _sendRequest(String username) async {
    try {
      await _repository.sendRequest(username);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent.')));
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not send request: $error');
    }
  }

  Future<void> _respond(String requestId, bool accept) async {
    try {
      await _repository.respond(requestId, accept);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not update request: $error');
    }
  }

  Future<void> _challenge(FriendRecord friend) async {
    try {
      final gameId = await _repository.createChallenge(friend.userId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChessMatchScreen(gameId: gameId)),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not create challenge: $error');
      }
    }
  }

  Future<void> _joinInvitation(String gameId) async {
    try {
      final result = await _repository.client.rpc(
        'join_friend_game',
        params: {'p_game_id': gameId},
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ChessMatchScreen(gameId: (result as Map)['id'].toString()),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not join challenge: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _relationships.where((item) => item.status == 'accepted');
    final incoming = _relationships.where(
      (item) => item.status == 'pending' && item.isIncoming,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Connect with friends',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add players by username. Once accepted, challenge them directly without copying a game ID.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search username',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            ..._results.map(
              (player) => ListTile(
                title: Text('@${player['username']}'),
                subtitle: Text(player['full_name']?.toString() ?? 'Player'),
                trailing: OutlinedButton(
                  onPressed: () => _sendRequest(player['username'].toString()),
                  child: const Text('Add'),
                ),
              ),
            ),
            if (_invitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Game invitations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              ..._invitations.map(
                (invitation) => ListTile(
                  leading: const Icon(Icons.sports_esports),
                  title: const Text('A friend challenged you'),
                  trailing: FilledButton(
                    onPressed: () =>
                        _joinInvitation(invitation['id'].toString()),
                    child: const Text('Play'),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Friend requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (incoming.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No pending requests.'),
              )
            else
              ...incoming.map(
                (request) => ListTile(
                  title: Text('@${request.username}'),
                  subtitle: Text(request.fullName),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        onPressed: () => _respond(request.requestId, false),
                        icon: const Icon(Icons.close),
                      ),
                      IconButton(
                        onPressed: () => _respond(request.requestId, true),
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'My friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Add a friend to start playing together.'),
              )
            else
              ...friends.map(
                (friend) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('@${friend.username}'),
                  subtitle: Text(friend.fullName),
                  trailing: FilledButton.icon(
                    onPressed: () => _challenge(friend),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Challenge'),
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
