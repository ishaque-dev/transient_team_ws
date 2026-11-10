import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_activity_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/rate_task_sheet.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/star_rating.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';

class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<TaskActivityCubit>()..watch(taskId),
      child: _TaskDetailsView(taskId: taskId),
    );
  }
}

class _TaskDetailsView extends StatelessWidget {
  const _TaskDetailsView({required this.taskId});

  final String taskId;

  Future<void> _delete(BuildContext context, TaskEntity task) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteTask,
      message: AppStrings.deleteTaskConfirm,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await context.read<TaskActionsCubit>().delete(task);
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final task = context.select(
      (TaskListBloc bloc) => bloc.state.taskById(taskId),
    );
    final user = context.currentUser;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.task)),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: AppStrings.taskNotFound,
        ),
      );
    }

    final flags = context.flags;
    final canUpdate = user.isAdmin || task.assigneeId == user.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.task),
        actions: [
          if (user.isAdmin && flags.editTask)
            IconButton(
              tooltip: AppStrings.editTask,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppRoutes.editTask(task.id)),
            ),
          if (user.isAdmin && flags.deleteTask)
            IconButton(
              tooltip: AppStrings.deleteTask,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, task),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(task.status),
                    PriorityPill(task.priority),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  task.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DueLabel(task),
                const SizedBox(height: 16),
                if (canUpdate && flags.statusUpdate) ...[
                  _StatusSection(task: task),
                  const SizedBox(height: 12),
                ],
                if (task.isCompleted) ...[
                  _RatingSection(
                    task: task,
                    canRate: user.isAdmin && flags.taskRating,
                  ),
                  const SizedBox(height: 12),
                ],
                _DetailsSection(task: task),
                const SizedBox(height: 12),
                SectionCard(
                  title: AppStrings.description,
                  child: Text(
                    task.description.isEmpty
                        ? AppStrings.noDescription
                        : task.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: task.description.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _ActivitySection(),
              ],
            ),
          ),
          if (canUpdate && flags.taskComments) _CommentComposer(task: task),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final actions = context.read<TaskActionsCubit>();
    return SectionCard(
      title: AppStrings.updateStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in TaskStatus.values)
                ChoiceChip(
                  avatar: Icon(status.icon, color: status.color(context)),
                  label: Text(status.label),
                  selected: task.status == status,
                  showCheckmark: false,
                  onSelected: (_) => actions.changeStatus(task, status),
                ),
            ],
          ),
          if (!task.isCompleted) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => actions.changeStatus(task, TaskStatus.completed),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Mark as completed'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.task, required this.canRate});

  final TaskEntity task;
  final bool canRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final rating = task.rating;

    if (rating == null) {
      return SectionCard(
        title: 'Performance rating',
        child: canRate
            ? FilledButton.tonalIcon(
                onPressed: () => showRateTaskSheet(context, task),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Rate this work'),
              )
            : Text(
                'Awaiting a rating from an admin.',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
      );
    }

    Widget row(String label, int value) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          StarRating(value: value.toDouble()),
          const SizedBox(width: 8),
          Text('$value/5', style: theme.textTheme.labelLarge),
        ],
      ),
    );

    return SectionCard(
      title: 'Performance rating',
      trailing: canRate
          ? TextButton(
              onPressed: () => showRateTaskSheet(context, task),
              child: const Text('Edit'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rating.overall.toStringAsFixed(1),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StarRating(value: rating.overall, size: 20),
                  Text(
                    'Overall',
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          row('Completion quality', rating.quality),
          row('Deadline achievement', rating.timeliness),
          if (rating.note != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '“${rating.note}”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Rated by ${rating.ratedByName} · ${Formatters.shortDate(rating.ratedAt)}',
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final assignee = task.assigneeName;
    return SectionCard(
      title: AppStrings.details,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: AppStrings.assignedTo,
            value: assignee ?? AppStrings.unassigned,
            leading: assignee == null
                ? null
                : UserAvatar(name: assignee, size: 28),
          ),
          _DetailRow(
            icon: Icons.event_rounded,
            label: AppStrings.dueDate,
            value: Formatters.longDate(task.dueDate),
          ),
          _DetailRow(
            icon: Icons.edit_calendar_outlined,
            label: AppStrings.createdBy,
            value:
                '${task.createdByName} · ${Formatters.shortDate(task.createdAt)}',
          ),
          _DetailRow(
            icon: Icons.update_rounded,
            label: AppStrings.lastUpdated,
            value: Formatters.dateTime(task.updatedAt),
          ),
          if (task.completedAt != null)
            _DetailRow(
              icon: Icons.task_alt_rounded,
              label: AppStrings.completedOn,
              value: Formatters.dateTime(task.completedAt!),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.leading,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: leading ?? Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(value, style: theme.textTheme.bodyLarge),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskActivityCubit>().state;
    final theme = Theme.of(context);

    Widget body;
    if (state.isLoading) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (state.items.isEmpty) {
      body = Text(
        state.errorMessage ?? AppStrings.noActivity,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      body = Column(
        children: [for (final item in state.items) _ActivityTile(item: item)],
      );
    }
    return SectionCard(title: AppStrings.activity, child: body);
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final TaskActivityEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = Formatters.timeAgo(item.createdAt);

    if (item.type == TaskActivityType.comment) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(name: item.authorName, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: item.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: '  $time',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(item.message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final (IconData icon, Color color) = switch (item.type) {
      TaskActivityType.created => (
        Icons.add_circle_outline_rounded,
        scheme.primary,
      ),
      TaskActivityType.assigned => (
        Icons.person_add_alt_rounded,
        scheme.tertiary,
      ),
      TaskActivityType.statusChanged => (
        item.toStatus?.icon ?? Icons.sync_rounded,
        item.toStatus?.color(context) ?? scheme.primary,
      ),
      TaskActivityType.rated => (Icons.star_rounded, const Color(0xFFF5A524)),
      _ => (Icons.edit_note_rounded, scheme.onSurfaceVariant),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: item.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' ${item.message}'),
                    TextSpan(
                      text: '  ·  $time',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({required this.task});

  final TaskEntity task;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await context.read<TaskActionsCubit>().comment(
      widget.task,
      text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: AppStrings.addComment,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send',
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
