import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/community_post_model.dart';
import '../../core/repositories/community_repository.dart';
import 'widgets/community_loading_skeleton.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityRepository _repository = CommunityRepository();
  final TextEditingController _postController = TextEditingController();
  RealtimeChannel? _channel;
  List<CommunityPostModel> _posts = [];
  bool _isAdmin = false;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int _generation = 0;

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
    _postController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final startedAt = DateTime.now();
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _repository.getCurrentUserIsAdmin(),
        _repository.getPosts(limit: 50),
      ]);
      await _keepLoadingVisible(startedAt);
      if (!mounted || generation != _generation) return;
      setState(() {
        _isAdmin = results[0] as bool;
        _posts = results[1] as List<CommunityPostModel>;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Community feed load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _keepLoadingVisible(startedAt);
      if (!mounted || generation != _generation) return;
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
      return 'Could not load club updates (${error.code}): ${error.message}';
    }
    return 'Could not load club updates: $error';
  }

  String _commentError(Object error) {
    if (error is PostgrestException) {
      return 'Comment request failed (${error.code}): ${error.message}';
    }
    return 'Comment request failed: $error';
  }

  Future<void> _publishPost() async {
    final content = _postController.text.trim();
    if (_submitting || content.isEmpty || !_isAdmin) return;
    setState(() => _submitting = true);
    try {
      await _repository.createPost(content);
      _postController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Club update published.')));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        _showError(
          'Could not publish the update. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    try {
      await _repository.toggleLike(
        postId: post.id,
        currentlyLiked: post.likedByMe,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        _showError('Your reaction was not saved. Please try again.');
      }
    }
  }

  Future<void> _showComments(CommunityPostModel post) async {
    final controller = TextEditingController();
    var comments = <Map<String, dynamic>>[];
    var loadingComments = true;
    var sendingComment = false;
    String? commentError;
    try {
      comments = await _repository.getComments(post.id);
    } catch (error) {
      commentError = _commentError(error);
    }
    loadingComments = false;
    if (!mounted) {
      controller.dispose();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom) *
                .68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: loadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : commentError != null
                      ? _CommentError(
                          message: commentError!,
                          onRetry: () async {
                            setSheetState(() {
                              loadingComments = true;
                              commentError = null;
                            });
                            try {
                              final refreshed = await _repository.getComments(
                                post.id,
                              );
                              setSheetState(() => comments = refreshed);
                            } catch (error) {
                              setSheetState(
                                () => commentError = _commentError(error),
                              );
                            } finally {
                              setSheetState(() => loadingComments = false);
                            }
                          },
                        )
                      : comments.isEmpty
                      ? const Center(child: Text('No comments yet.'))
                      : ListView.separated(
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final profile = comment['profiles'] is Map
                                ? Map<String, dynamic>.from(
                                    comment['profiles'] as Map,
                                  )
                                : <String, dynamic>{};
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                child: Text(
                                  _initials(
                                    (profile['full_name'] ?? 'Player')
                                        .toString(),
                                  ),
                                ),
                              ),
                              title: Text(
                                (profile['full_name'] ?? 'Player').toString(),
                              ),
                              subtitle: Text(
                                (comment['content'] ?? '').toString(),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send comment',
                      onPressed: sendingComment || commentError != null
                          ? null
                          : () async {
                              if (controller.text.trim().isEmpty) return;
                              setSheetState(() => sendingComment = true);
                              try {
                                await _repository.createComment(
                                  postId: post.id,
                                  content: controller.text,
                                );
                                controller.clear();
                                final refreshed = await _repository.getComments(
                                  post.id,
                                );
                                setSheetState(() => comments = refreshed);
                                await _load();
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_commentError(error)),
                                    ),
                                  );
                                }
                              } finally {
                                setSheetState(() => sendingComment = false);
                              }
                            },
                      icon: sendingComment
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'P';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const background = Color(0xFFF4F8FD);
    const blue = Color(0xFF1A6BB5);
    const textPrimary = Color(0xFF0D1B2E);
    const textMuted = Color(0xFF5E7A99);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SQI CHESS CLUB',
                style: TextStyle(
                  fontSize: 20,
                  color: blue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 20,
                color: textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          IconButton(
            tooltip: 'Refresh community feed',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: textMuted),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: blue,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                'Official updates and news from the SQI chess community.',
                style: theme.textTheme.bodyMedium?.copyWith(color: textMuted),
              ),
              const SizedBox(height: 16),
              if (_isAdmin) _adminComposer(context),
              if (!_isAdmin && !_loading && _error == null)
                _officialFeedNote(context),
              if (_loading && _posts.isEmpty) const CommunityLoadingSkeleton(),
              if (_error != null) _feedError(context),
              if (!_loading && _error == null && _posts.isEmpty)
                _emptyFeed(context),
              for (final post in _posts) _postCard(context, post),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminComposer(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Post a club update',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: const Text('ADMIN'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            TextField(
              controller: _postController,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share an official announcement or club update...',
                border: InputBorder.none,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _publishPost,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_submitting ? 'Publishing...' : 'Publish update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _officialFeedNote(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Official updates from club administrators. Like and comment below.',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _feedError(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _emptyFeed(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 34,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            _isAdmin
                ? 'No club updates yet'
                : 'No updates have been posted yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            _isAdmin
                ? 'Your first post will appear here for every player.'
                : 'Check back soon for news from the club.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _postCard(BuildContext context, CommunityPostModel post) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Text(_initials(post.authorName)),
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
                              post.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.verified, size: 16, color: colors.primary),
                        ],
                      ),
                      Text(
                        'Club admin  ·  ${post.timeLabel}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  const Chip(
                    avatar: Icon(Icons.push_pin_outlined, size: 14),
                    label: Text('Pinned'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SelectableText(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 150,
                    color: colors.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _toggleLike(post),
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: post.likedByMe ? colors.error : null,
                  ),
                  label: Text('${post.likeCount}'),
                ),
                TextButton.icon(
                  onPressed: () => _showComments(post),
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: Text('${post.commentCount} comments'),
                ),
                const Spacer(),
                if (post.isPinned)
                  Icon(
                    Icons.push_pin_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentError extends StatelessWidget {
  const _CommentError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
