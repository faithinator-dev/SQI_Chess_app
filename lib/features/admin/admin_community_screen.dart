import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/repositories/community_repository.dart';
import '../community/widgets/community_loading_skeleton.dart';

class AdminCommunityScreen extends StatefulWidget {
  const AdminCommunityScreen({super.key});

  @override
  State<AdminCommunityScreen> createState() => _AdminCommunityScreenState();
}

class _AdminCommunityScreenState extends State<AdminCommunityScreen> {
  final _repository = CommunityRepository();
  final _controller = TextEditingController();
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _posting = false;
  bool _isAdmin = false;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _channel = _repository.watchPosts(onChanged: _load);
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) _repository.removeChannel(channel);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final startedAt = DateTime.now();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getCurrentUserIsAdmin(),
        _repository.getPosts(limit: 50),
      ]);
      await _keepLoadingVisible(startedAt);
      if (!mounted) return;
      final posts = results[1] as List;
      setState(() {
        _isAdmin = results[0] as bool;
        _posts = posts
            .map(
              (post) => <String, dynamic>{
                'id': post.id,
                'content': post.content,
                'created_at': post.createdAt.toIso8601String(),
                'likes': post.likeCount,
                'comments': post.commentCount,
              },
            )
            .toList();
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Admin community feed load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _keepLoadingVisible(startedAt);
      if (!mounted) return;
      setState(() {
        _error = _communityError(error);
        _loading = false;
      });
    }
  }

  Future<void> _keepLoadingVisible(DateTime startedAt) async {
    const minimumDuration = Duration(milliseconds: 900);
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minimumDuration) {
      await Future<void>.delayed(minimumDuration - elapsed);
    }
  }

  String _communityError(Object error) {
    if (error is PostgrestException) {
      return 'Could not load official updates (${error.code}): ${error.message}';
    }
    return 'Could not load official updates: $error';
  }

  Future<void> _publish() async {
    if (!_isAdmin || _posting || _controller.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      await _repository.createPost(_controller.text.trim());
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official update published.')),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        _message(
          'The update could not be published. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community admin',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh updates',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - value)),
              child: child,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                'OFFICIAL CLUB FEED',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Announcements',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Publish updates that appear in the community feed.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (!_loading && !_isAdmin && _error == null)
                Card(
                  color: colors.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: colors.onErrorContainer,
                    ),
                    title: Text(
                      'Administrator access required',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                    subtitle: Text(
                      'Sign in with an authorized administrator account to publish updates.',
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                  ),
                ),
              if (_isAdmin)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _controller,
                          minLines: 3,
                          maxLines: 7,
                          maxLength: 5000,
                          decoration: const InputDecoration(
                            labelText: 'Announcement',
                            hintText: 'Write an update for the club…',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _posting ? null : _publish,
                          icon: _posting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _posting ? 'Publishing…' : 'Publish announcement',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Recent official posts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const CommunityLoadingSkeleton()
              else if (_error != null)
                Card(
                  color: colors.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.cloud_off_outlined,
                      color: colors.onErrorContainer,
                    ),
                    title: Text(
                      _error!,
                      style: TextStyle(color: colors.onErrorContainer),
                    ),
                    trailing: TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ),
                )
              else if (_posts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text(
                      'No official announcements have been published yet.',
                    ),
                  ),
                )
              else
                for (final post in _posts) _postCard(context, post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postCard(BuildContext context, Map<String, dynamic> post) {
    final date = DateTime.tryParse(
      post['created_at']?.toString() ?? '',
    )?.toLocal();
    final dateText = date == null
        ? 'Date unavailable'
        : '${date.day}/${date.month}/${date.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Checkmate administration',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(dateText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(post['content']?.toString() ?? ''),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text('${post['likes'] ?? 0}'),
                const SizedBox(width: 18),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text('${post['comments'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
