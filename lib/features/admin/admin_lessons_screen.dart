import 'package:flutter/material.dart';

import '../../core/models/lesson_model.dart';
import '../../core/repositories/lesson_repository.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  static const _background = Color(0xFFF9F8F6);
  static const _surface = Color(0xFFFFFFFF);
  static const _muted = Color(0xFF737A74);
  static const _blue = Color(0xFF2D4A3E);

  final _repository = LessonRepository();
  List<LessonModel> _lessons = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lessons = await _repository.getAdminLessons();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createLesson() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final stepTitle = TextEditingController();
    final stepBody = TextEditingController();
    final stepTip = TextEditingController();
    var category = 'Basics';
    var difficulty = 'Beginner';
    var publish = true;
    var duration = 10;
    var dialogSaving = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _surface,
          title: const Text(
            'Add lesson',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(title, 'Lesson title'),
                  _field(description, 'Short description', maxLines: 2),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          dropdownColor: _surface,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items:
                              const [
                                    'Basics',
                                    'Openings',
                                    'Tactics',
                                    'Strategy',
                                    'Endgames',
                                  ]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              setDialogState(() => category = v ?? category),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: difficulty,
                          dropdownColor: _surface,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                          ),
                          items:
                              const [
                                    'Beginner',
                                    'Intermediate',
                                    'Advanced',
                                    'Expert',
                                  ]
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setDialogState(
                            () => difficulty = v ?? difficulty,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: duration,
                    dropdownColor: _surface,
                    decoration: const InputDecoration(
                      labelText: 'Estimated minutes',
                    ),
                    items: [5, 10, 15, 20, 30, 45]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v minutes'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => duration = v ?? duration),
                  ),
                  const SizedBox(height: 12),
                  _field(stepTitle, 'First step title'),
                  _field(stepBody, 'Lesson text', maxLines: 4),
                  _field(stepTip, 'Optional tip', maxLines: 2),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: publish,
                    onChanged: (v) => setDialogState(() => publish = v),
                    title: const Text(
                      'Publish now',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: dialogSaving
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty ||
                          stepTitle.text.trim().isEmpty ||
                          stepBody.text.trim().isEmpty) {
                        _showMessage(
                          'Enter a lesson title, first step title, and lesson text.',
                        );
                        return;
                      }
                      setDialogState(() => dialogSaving = true);
                      setState(() => _saving = true);
                      try {
                        await _repository.createLesson(
                          title: title.text,
                          description: description.text,
                          category: category,
                          difficulty: difficulty,
                          durationMinutes: duration,
                          steps: [
                            {
                              'title': stepTitle.text.trim(),
                              'body': stepBody.text.trim(),
                              'tip': stepTip.text.trim(),
                            },
                          ],
                          publish: publish,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (mounted) {
                          _showMessage('Lesson could not be saved: $error');
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => dialogSaving = false);
                        }
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: Text(dialogSaving ? 'Saving…' : 'Save lesson'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    stepTitle.dispose();
    stepBody.dispose();
    stepTip.dispose();
    if (created == true && mounted) await _load();
  }

  Future<void> _togglePublished(LessonModel lesson, bool value) async {
    try {
      await _repository.setLessonPublished(lesson.id, value);
      await _load();
    } catch (error) {
      if (mounted) _showMessage('Publish state could not be changed: $error');
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 20, color: Colors.white),
      decoration: InputDecoration(labelText: label),
    ),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: Colors.white,
      title: const Text('Lessons'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _saving ? null : _createLesson,
      backgroundColor: _blue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add lesson'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lessons could not be loaded. Apply the admin lesson policy migration and check administrator access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: _muted),
                  ),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        : _lessons.isEmpty
        ? const Center(
            child: Text(
              'No lessons yet. Add the first lesson.',
              style: TextStyle(fontSize: 20, color: _muted),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return Card(
                color: _surface,
                child: ListTile(
                  title: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${lesson.category} | ${lesson.difficulty}${lesson.description == null ? '' : ' | ${lesson.description}'}',
                    style: const TextStyle(fontSize: 20, color: _muted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson.isPublished ? 'Published' : 'Draft',
                        style: const TextStyle(fontSize: 20, color: _muted),
                      ),
                      Switch.adaptive(
                        value: lesson.isPublished,
                        onChanged: (v) => _togglePublished(lesson, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
