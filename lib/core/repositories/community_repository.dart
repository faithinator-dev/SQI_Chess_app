import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post_model.dart';

class CommunityPage {
  const CommunityPage({
    required this.id,
    required this.title,
    required this.description,
  });
  final String id;
  final String title;
  final String description;

  factory CommunityPage.fromMap(Map<String, dynamic> map) => CommunityPage(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String? ?? '',
  );
}

class CommunityRepository {
  CommunityRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, String>>> searchPlayers(String query) async {
    final clean = query.trim().replaceFirst(RegExp(r'^@'), '');
    if (_client.auth.currentUser == null || clean.isEmpty) return [];
    final rows = await _client
        .from('profiles')
        .select('username,full_name')
        .ilike('username', '%$clean%')
        .order('username')
        .limit(8);
    return rows
        .map(
          (row) => {
            'username': row['username'] as String,
            'name': row['full_name'] as String? ?? row['username'] as String,
          },
        )
        .toList();
  }

  Future<bool> getCurrentUserIsAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return false;
    }
    final row = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    return row?['role'] == 'admin';
  }

  Future<List<CommunityPage>> getPages() async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to view community pages.');
    }
    final rows = await _client
        .from('community_pages')
        .select('id,title,description')
        .eq('is_published', true)
        .order('created_at');
    return rows
        .map((row) => CommunityPage.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createPage({
    required String title,
    required String description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    if (!await getCurrentUserIsAdmin()) {
      throw StateError('Only administrators can create community pages.');
    }
    await _client.from('community_pages').insert({
      'title': title.trim(),
      'description': description.trim(),
      'created_by': user.id,
    });
  }

  Future<List<CommunityPostModel>> getPosts({
    int limit = 30,
    String? pageId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in to view the community feed.');

    var query = _client
        .from('community_posts')
        .select(
          'id, user_id, content, image_url, is_pinned, created_at, page_id',
        );
    if (pageId != null) query = query.eq('page_id', pageId);
    final posts = await query
        .order('created_at', ascending: false)
        .limit(limit.clamp(1, 100));

    final userIds = posts.map((item) => item['user_id'] as String).toSet();
    if (userIds.isEmpty) return [];

    final profiles = await _client
        .from('profiles')
        .select('id,full_name,username,avatar_url,role')
        .inFilter('id', userIds.toList());
    final profilesById = <String, Map<String, dynamic>>{
      for (final profile in profiles)
        profile['id'] as String: Map<String, dynamic>.from(profile),
    };
    final adminPosts = posts.where((item) {
      final profile = profilesById[item['user_id'] as String];
      return profile?['role'] == 'admin';
    }).toList();
    final postIds = adminPosts.map((item) => item['id'] as String).toList();
    if (postIds.isEmpty) return [];

    final likes = await _client
        .from('community_post_likes')
        .select('post_id,user_id')
        .inFilter('post_id', postIds);
    final comments = await _client
        .from('community_comments')
        .select('post_id')
        .inFilter('post_id', postIds);

    final likeCounts = <String, int>{};
    final likedByMe = <String>{};
    final commentCounts = <String, int>{};
    for (final row in likes) {
      final id = row['post_id'] as String;
      likeCounts[id] = (likeCounts[id] ?? 0) + 1;
      if (row['user_id'] == user.id) likedByMe.add(id);
    }
    for (final row in comments) {
      final id = row['post_id'] as String;
      commentCounts[id] = (commentCounts[id] ?? 0) + 1;
    }

    return adminPosts.map((row) {
      final post = Map<String, dynamic>.from(row);
      final profile =
          profilesById[post['user_id'] as String] ?? <String, dynamic>{};
      return CommunityPostModel.fromMap({
        ...post,
        'author_name': profile['full_name'] ?? 'Player',
        'author_username': profile['username'] ?? '',
        'author_avatar_url': profile['avatar_url'],
        'like_count': likeCounts[post['id']] ?? 0,
        'comment_count': commentCounts[post['id']] ?? 0,
        'liked_by_me': likedByMe.contains(post['id']),
      });
    }).toList();
  }

  Future<void> createPost(String content, {String? pageId}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    if (!await getCurrentUserIsAdmin()) {
      throw StateError('Only club administrators can publish updates.');
    }
    final clean = content.trim();
    if (clean.isEmpty) throw const FormatException('Post cannot be empty.');
    final values = <String, dynamic>{'user_id': user.id, 'content': clean};
    if (pageId != null) {
      values['page_id'] = pageId;
    }
    await _client.from('community_posts').insert(values);
  }

  Future<void> toggleLike({
    required String postId,
    required bool currentlyLiked,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    if (currentlyLiked) {
      await _client
          .from('community_post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id);
    } else {
      await _client
          .from('community_post_likes')
          .upsert(
            {'post_id': postId, 'user_id': user.id},
            onConflict: 'post_id,user_id',
            ignoreDuplicates: true,
          );
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to view comments.');
    }
    final rows = await _client
        .from('community_comments')
        .select('id, post_id, user_id, content, created_at')
        .eq('post_id', postId)
        .order('created_at')
        .limit(100);
    final comments = rows.map((row) => Map<String, dynamic>.from(row)).toList();
    final userIds = comments.map((row) => row['user_id'] as String).toSet();
    if (userIds.isEmpty) return comments;

    final profiles = await _client
        .from('profiles')
        .select('id,full_name,username,avatar_url')
        .inFilter('id', userIds.toList());
    final profilesById = <String, Map<String, dynamic>>{
      for (final profile in profiles)
        profile['id'] as String: Map<String, dynamic>.from(profile),
    };

    return comments
        .map(
          (comment) => {
            ...comment,
            'profiles': profilesById[comment['user_id']],
          },
        )
        .toList();
  }

  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    final clean = content.trim();
    if (clean.isEmpty) throw const FormatException('Comment cannot be empty.');
    await _client.from('community_comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': clean,
    });
  }

  RealtimeChannel watchPosts({required VoidCallback onChanged}) {
    final channel = _client
        .channel('community-posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_pages',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_post_likes',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_comments',
          callback: (_) => onChanged(),
        );
    channel.subscribe();
    return channel;
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
