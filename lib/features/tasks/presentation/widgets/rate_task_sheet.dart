import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/star_rating.dart';

Future<void> showRateTaskSheet(BuildContext context, TaskEntity task) {
  final cubit = context.read<TaskActionsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _RateTaskSheet(task: task),
    ),
  );
}

class _RateTaskSheet extends StatefulWidget {
  const _RateTaskSheet({required this.task});

  final TaskEntity task;

  @override
  State<_RateTaskSheet> createState() => _RateTaskSheetState();
}

class _RateTaskSheetState extends State<_RateTaskSheet> {
  late int _quality = widget.task.rating?.quality ?? 0;
  late int _timeliness =
      widget.task.rating?.timeliness ?? widget.task.suggestedTimeliness;
  late final _note = TextEditingController(text: widget.task.rating?.note);
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<TaskActionsCubit>().rate(
      widget.task,
      quality: _quality,
      timeliness: _timeliness,
      note: _note.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final late = widget.task.daysLate ?? 0;
    final deadlineNote = late <= 0
        ? 'Finished on or before the due date.'
        : 'Finished $late day${late == 1 ? '' : 's'} after the due date.';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate this work',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('Completion quality', style: theme.textTheme.titleSmall),
            Text(
              'How complete and well done was the work?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            StarRatingInput(
              value: _quality,
              onChanged: (value) => setState(() => _quality = value),
            ),
            const SizedBox(height: 12),
            Text('Deadline achievement', style: theme.textTheme.titleSmall),
            Text(
              '$deadlineNote Suggested: ${widget.task.suggestedTimeliness}/5.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            StarRatingInput(
              value: _timeliness,
              onChanged: (value) => setState(() => _timeliness = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Feedback (optional)',
                hintText: 'What went well? What could improve?',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_quality == 0 || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.star_rounded),
                label: Text(
                  _quality == 0 ? 'Pick a quality rating' : 'Save rating',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
