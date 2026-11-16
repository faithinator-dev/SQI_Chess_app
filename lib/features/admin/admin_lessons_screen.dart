import 'package:flutter/material.dart';

import '../../core/models/lesson_model.dart';
import '../../core/repositories/lesson_repository.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
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

  Future<void> _createLesson() => _editLesson();

  Future<void> _editExistingLesson(LessonModel lesson) => _editLesson(lesson);

  Future<void> _editLesson([LessonModel? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final existingSteps =
        (existing?.content['steps'] as List?)
            ?.whereType<Map>()
            .map((step) => Map<String, dynamic>.from(step))
            .toList() ??
        [];
    final steps = existingSteps.isEmpty ? [<String, dynamic>{}] : existingSteps;
    final stepTitles = steps
        .map((s) => TextEditingController(text: s['title']?.toString() ?? ''))
        .toList();
    final stepBodies = steps
        .map((s) => TextEditingController(text: s['body']?.toString() ?? ''))
        .toList();
    final stepTips = steps
        .map((s) => TextEditingController(text: s['tip']?.toString() ?? ''))
        .toList();
    final stepFens = steps
        .map((s) => TextEditingController(text: s['fen']?.toString() ?? ''))
        .toList();
    final stepMoves = steps
        .map(
          (s) => TextEditingController(
            text:
                (s['moves'] is List
                    ? (s['moves'] as List).join(' ')
                    : s['moves']?.toString()) ??
                '',
          ),
        )
        .toList();
    var category = existing?.category ?? 'Basics';
    var difficulty = existing?.difficulty ?? 'Beginner';
    var publish = existing?.isPublished ?? true;
    var duration = existing?.durationMinutes ?? 10;
    var dialogSaving = false;
    void disposeStepControllers() {
      for (final controller in [
        ...stepTitles,
        ...stepBodies,
        ...stepTips,
        ...stepFens,
        ...stepMoves,
      ]) {
        controller.dispose();
      }
    }

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add lesson' : 'Edit lesson'),
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
                          dropdownColor: Theme.of(context).colorScheme.surface,
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
                          dropdownColor: Theme.of(context).colorScheme.surface,
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
                    dropdownColor: Theme.of(context).colorScheme.surface,
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
                  for (var i = 0; i < steps.length; i++) ...[
                    const Divider(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Step ${i + 1}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (steps.length > 1)
                          IconButton(
                            onPressed: () => setDialogState(() {
                              steps.removeAt(i);
                              stepTitles.removeAt(i).dispose();
                              stepBodies.removeAt(i).dispose();
                              stepTips.removeAt(i).dispose();
                              stepFens.removeAt(i).dispose();
                              stepMoves.removeAt(i).dispose();
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    _field(stepTitles[i], 'Step title'),
                    _field(stepBodies[i], 'Teaching text', maxLines: 4),
                    _field(stepTips[i], 'Teaching tip (optional)', maxLines: 2),
                    _field(stepFens[i], 'Starting position FEN (optional)'),
                    _field(
                      stepMoves[i],
                      'Student moves in UCI, e.g. e2e4 e7e5',
                      maxLines: 2,
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: steps.length >= 30
                          ? null
                          : () => setDialogState(() {
                              steps.add({});
                              stepTitles.add(TextEditingController());
                              stepBodies.add(TextEditingController());
                              stepTips.add(TextEditingController());
                              stepFens.add(TextEditingController());
                              stepMoves.add(TextEditingController());
                            }),
                      icon: const Icon(Icons.add),
                      label: const Text('Add another step'),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: publish,
                    onChanged: (v) => setDialogState(() => publish = v),
                    title: const Text('Publish now'),
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
                      setDialogState(() => dialogSaving = true);
                      setState(() => _saving = true);
                      try {
                        final lessonSteps = List.generate(
                          steps.length,
                          (i) => {
                            'title': stepTitles[i].text.trim(),
                            'body': stepBodies[i].text.trim(),
                            'tip': stepTips[i].text.trim(),
                            if (stepFens[i].text.trim().isNotEmpty)
                              'fen': stepFens[i].text.trim(),
                            if (stepMoves[i].text.trim().isNotEmpty)
                              'moves': stepMoves[i].text.trim(),
                          },
                        );
                        if (existing == null) {
                          await _repository.createLesson(
                            title: title.text,
                            description: description.text,
                            category: category,
                            difficulty: difficulty,
                            durationMinutes: duration,
                            steps: lessonSteps,
                            publish: publish,
                          );
                        } else {
                          await _repository.updateLesson(
                            id: existing.id,
                            title: title.text,
                            description: description.text,
                            category: category,
                            difficulty: difficulty,
                            durationMinutes: duration,
                            steps: lessonSteps,
                            publish: publish,
                          );
                        }
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
    disposeStepControllers();
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
      style: TextStyle(
        fontSize: 20,
        color: Theme.of(context).colorScheme.onSurface,
      ),
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
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      backgroundColor: Theme.of(context).colorScheme.primary,
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
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
        ? Center(
            child: Text(
              'No lessons yet. Add the first lesson.',
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _lessons.length,
            itemBuilder: (context, index) {
              final lesson = _lessons[index];
              return Card(
                child: ListTile(
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${lesson.category} | ${lesson.difficulty} | ${(lesson.content['steps'] as List?)?.length ?? 0} steps${lesson.description == null ? '' : ' | ${lesson.description}'}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Switch.adaptive(
                        value: lesson.isPublished,
                        onChanged: (v) => _togglePublished(lesson, v),
                      ),
                      IconButton(
                        tooltip: 'Edit lesson',
                        onPressed: _saving
                            ? null
                            : () => _editExistingLesson(lesson),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
