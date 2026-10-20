import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';

class LessonRepository {
  LessonRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<LessonModel>> getAdminLessons() async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to manage lessons.');
    }
    final rows = await _client
        .from('lessons')
        .select()
        .order('sort_order')
        .order('created_at')
        .limit(200);
    return rows
        .map((row) => LessonModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createLesson({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int durationMinutes,
    required List<Map<String, String>> steps,
    required bool publish,
  }) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to create a lesson.');
    }
    final latest = await _client
        .from('lessons')
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    await _client.from('lessons').insert({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'sort_order': ((latest?['sort_order'] as num?)?.toInt() ?? -1) + 1,
      'content': {'steps': steps},
      'is_published': publish,
    });
  }

  Future<void> setLessonPublished(String lessonId, bool published) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Sign in to manage lessons.');
    }
    await _client
        .from('lessons')
        .update({'is_published': published})
        .eq('id', lessonId);
  }

  Future<List<LessonModel>> getLessons() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return [];
    }

    final lessons = await _client
        .from('lessons')
        .select()
        .eq('is_published', true)
        .order('sort_order');

    final progress = await _client
        .from('lesson_progress')
        .select()
        .eq('user_id', user.id);

    final progressMap = <String, Map<String, dynamic>>{};

    for (final item in progress) {
      final row = Map<String, dynamic>.from(item);

      progressMap[row['lesson_id'] as String] = row;
    }

    return lessons.map((item) {
      final lesson = Map<String, dynamic>.from(item);

      final lessonProgress = progressMap[lesson['id'] as String];

      lesson['progress'] = lessonProgress?['progress'] ?? 0;

      lesson['completed'] = lessonProgress?['completed'] ?? false;

      return LessonModel.fromMap(lesson);
    }).toList();
  }

  Future<void> saveProgress({
    required String lessonId,
    required int progress,
    required bool completed,
    int lastPosition = 0,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('You must be signed in.');
    }

    final now = DateTime.now().toUtc();

    // Preserve started_at on conflict and avoid overwriting progress if the
    // authenticated account changes while the initial row is being read.
    final existing = await _client
        .from('lesson_progress')
        .select('started_at,completed_at')
        .eq('user_id', user.id)
        .eq('lesson_id', lessonId)
        .maybeSingle();

    if (_client.auth.currentUser?.id != user.id) {
      throw StateError('Your account changed while saving progress.');
    }

    await _client.from('lesson_progress').upsert({
      'user_id': user.id,
      'lesson_id': lessonId,
      'progress': progress.clamp(0, 100),
      'completed': completed,
      'last_position': lastPosition,
      'started_at': existing?['started_at'] ?? now.toIso8601String(),
      'completed_at': completed
          ? now.toIso8601String()
          : existing?['completed_at'],
      'updated_at': now.toIso8601String(),
    }, onConflict: 'user_id,lesson_id');
  }
}
