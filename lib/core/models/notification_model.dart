class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory NotificationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: map['type'] as String? ?? 'system',
      title: map['title'] as String? ?? 'Notification',
      message: map['message'] as String? ?? '',
      data: map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : <String, dynamic>{},
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ).toLocal(),
      readAt: map['read_at'] == null
          ? null
          : DateTime.parse(
              map['read_at'] as String,
            ).toLocal(),
    );
  }

  String get timeLabel {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}