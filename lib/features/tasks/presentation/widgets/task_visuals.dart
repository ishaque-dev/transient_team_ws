import 'package:flutter/material.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/pill.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

extension TaskStatusVisuals on TaskStatus {
  Color color(BuildContext context) {
    final palette = context.palette;
    return switch (this) {
      TaskStatus.todo => palette.todo,
      TaskStatus.inProgress => palette.inProgress,
      TaskStatus.onHold => palette.onHold,
      TaskStatus.completed => palette.completed,
    };
  }

  IconData get icon => switch (this) {
    TaskStatus.todo => Icons.radio_button_unchecked_rounded,
    TaskStatus.inProgress => Icons.timelapse_rounded,
    TaskStatus.onHold => Icons.pause_circle_outline_rounded,
    TaskStatus.completed => Icons.check_circle_rounded,
  };
}

extension TaskPriorityVisuals on TaskPriority {
  Color color(BuildContext context) {
    final palette = context.palette;
    return switch (this) {
      TaskPriority.low => palette.priorityLow,
      TaskPriority.medium => palette.priorityMedium,
      TaskPriority.high => palette.priorityHigh,
      TaskPriority.urgent => palette.priorityUrgent,
    };
  }

  IconData get icon => switch (this) {
    TaskPriority.low => Icons.keyboard_arrow_down_rounded,
    TaskPriority.medium => Icons.drag_handle_rounded,
    TaskPriority.high => Icons.keyboard_arrow_up_rounded,
    TaskPriority.urgent => Icons.keyboard_double_arrow_up_rounded,
  };
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.dense = false});

  final TaskStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => Pill(
    label: status.label,
    icon: status.icon,
    color: status.color(context),
    dense: dense,
  );
}

class PriorityPill extends StatelessWidget {
  const PriorityPill(this.priority, {super.key, this.dense = false});

  final TaskPriority priority;
  final bool dense;

  @override
  Widget build(BuildContext context) => Pill(
    label: priority.label,
    icon: priority.icon,
    color: priority.color(context),
    dense: dense,
  );
}

/// "Due in 2 days" / "Overdue by 1 day" / "Done on time".
class DueLabel extends StatelessWidget {
  const DueLabel(this.task, {super.key});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final overdue = task.isOverdue(DateTime.now());

    final (IconData icon, String text, Color iconColor) = switch (task) {
      _ when task.isCompleted => (
        (task.completedOnTime ?? true)
            ? Icons.verified_rounded
            : Icons.history_rounded,
        (task.completedOnTime ?? true)
            ? 'Done on time'
            : 'Done ${task.daysLate}d late',
        (task.completedOnTime ?? true)
            ? palette.completed
            : palette.priorityHigh,
      ),
      _ when overdue => (
        Icons.warning_amber_rounded,
        Formatters.dueLabel(task.dueDate),
        palette.critical,
      ),
      _ => (
        Icons.event_rounded,
        Formatters.dueLabel(task.dueDate),
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: overdue
                ? palette.critical
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
