class CommunityPostModel {
  const CommunityPostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.isPinned = false,
    this.authorName = 'SQI Player',
    this.authorUsername = '',
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  final String? imageUrl;
  final bool isPinned;

  final String authorName;
  final String authorUsername;
  final String? authorAvatarUrl;

  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  factory CommunityPostModel.fromMap(Map<String, dynamic> map) {
    return CommunityPostModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      imageUrl: map['image_url'] as String?,
      isPinned: map['is_pinned'] as bool? ?? false,
      authorName: map['author_name'] as String? ?? 'SQI Player',
      authorUsername: map['author_username'] as String? ?? '',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (map['comment_count'] as num?)?.toInt() ?? 0,
      likedByMe: map['liked_by_me'] as bool? ?? false,
    );
  }

  String get timeLabel {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${createdAt.day}/${createdAt.month}';
  }
}
