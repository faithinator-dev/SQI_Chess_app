class LessonModel {
  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.sortOrder,
    required this.isPublished,
    this.thumbnailUrl,
    this.content = const {},
    this.progress = 0,
    this.completed = false,
  });

  final String id;
  final String title;
  final String? description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final int sortOrder;
  final bool isPublished;
  final String? thumbnailUrl;
  final Map<String, dynamic> content;

  final int progress;
  final bool completed;

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'Basics',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 10,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isPublished: map['is_published'] as bool? ?? false,
      thumbnailUrl: map['thumbnail_url'] as String?,
      content: map['content'] is Map
          ? Map<String, dynamic>.from(map['content'] as Map)
          : const {},
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? false,
    );
  }

  LessonModel copyWith({int? progress, bool? completed}) {
    return LessonModel(
      id: id,
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      durationMinutes: durationMinutes,
      sortOrder: sortOrder,
      isPublished: isPublished,
      thumbnailUrl: thumbnailUrl,
      content: content,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
    );
  }
}
