import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/star_rating.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.showAssignee = false,
  });

  final TaskEntity task;
  final VoidCallback? onTap;

  /// When set, a round check button completes / reopens the task in one tap.
  final VoidCallback? onToggleComplete;
  final bool showAssignee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = task.isCompleted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onToggleComplete != null) ...[
                    _CompleteButton(done: done, onPressed: onToggleComplete!),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            color: done ? scheme.onSurfaceVariant : null,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(task.status, dense: true),
                            PriorityPill(task.priority, dense: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Flexible(child: DueLabel(task)),
                            const Spacer(),
                            if (task.rating != null) ...[
                              StarRating(value: task.rating!.overall, size: 14),
                              const SizedBox(width: 8),
                            ],
                            if (showAssignee) _Assignee(task: task),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: task.priority.color(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Assignee extends StatelessWidget {
  const _Assignee({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final name = task.assigneeName;
    final theme = Theme.of(context);
    if (name == null) {
      return Text(
        AppStrings.unassigned,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: name, size: 22),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            name.split(' ').first,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.done, required this.onPressed});

  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = TaskStatus.completed.color(context);
    final outline = Theme.of(context).colorScheme.outline;
    return Semantics(
      button: true,
      label: done ? 'Reopen task' : 'Mark as completed',
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : Colors.transparent,
            border: Border.all(color: done ? color : outline, width: 2),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
