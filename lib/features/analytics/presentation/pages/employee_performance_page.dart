import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/pill.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/analytics/domain/performance_summary.dart';
import 'package:transient_team_ws/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/star_rating.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_card.dart';

/// Delivery, quality and history for one employee. Used by admins (pushed
/// from the dashboard or team list) and by employees as their own tab.
class EmployeePerformancePage extends StatefulWidget {
  const EmployeePerformancePage({
    super.key,
    required this.employee,
    this.isSelfView = false,
  });

  final UserEntity employee;
  final bool isSelfView;

  @override
  State<EmployeePerformancePage> createState() =>
      _EmployeePerformancePageState();
}

class _EmployeePerformancePageState extends State<EmployeePerformancePage> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final viewer = context.currentUser;
    final employee = widget.employee;
    final theme = Theme.of(context);
    final palette = context.palette;
    final allTasks = context.select((TaskListBloc bloc) => bloc.state.tasks);
    final tasks = allTasks.where((t) => t.assigneeId == employee.id).toList();
    final summary = PerformanceSummary.fromTasks(tasks, weeks: 8);

    final open = tasks.where((t) => t.status.isOpen).toList()
      ..sort(TaskSort.dueDate.compare);
    final completed = tasks.where((t) => t.isCompleted).toList()
      ..sort(
        (a, b) => (b.completedAt ?? b.updatedAt).compareTo(
          a.completedAt ?? a.updatedAt,
        ),
      );
    final rated = completed.where((t) => t.rating != null).toList()
      ..sort((a, b) => b.rating!.ratedAt.compareTo(a.rating!.ratedAt));
    final visibleList = _showCompleted ? completed : open;
    final flags = context.flags;
    final insights = flags.performanceInsights;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isSelfView ? 'My performance' : employee.displayName,
        ),
        actions: [
          if (widget.isSelfView) const NotificationBell(),
          if (viewer.isAdmin && !widget.isSelfView && flags.createTask)
            IconButton(
              tooltip: 'Assign a task',
              icon: const Icon(Icons.add_task_rounded),
              onPressed: () =>
                  context.push(AppRoutes.newTask(assigneeId: employee.id)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(name: employee.displayName, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          employee.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Pill(
                          label: employee.role.label,
                          color: theme.colorScheme.primary,
                          icon: employee.isAdmin
                              ? Icons.admin_panel_settings_outlined
                              : Icons.badge_outlined,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                  if (insights)
                    Tooltip(
                      message: scoreExplanation,
                      triggerMode: TooltipTriggerMode.tap,
                      child: ScoreRing(score: summary.score, size: 76),
                    ),
                ],
              ),
            ),
          ),
          if (insights) ...[
            const SizedBox(height: 12),
            StatGrid(
              children: [
                StatTile(
                  label: 'Completed',
                  value: '${summary.completed}',
                  caption: 'of ${summary.total} assigned',
                  icon: Icons.task_alt_rounded,
                  color: palette.completed,
                ),
                StatTile(
                  label: 'Deadline achievement',
                  value: percentOrDash(summary.deadlineRate),
                  caption:
                      '${summary.completedOnTime} on time · ${summary.completedLate} late',
                  icon: Icons.timer_outlined,
                  color: palette.meterFill,
                ),
                StatTile(
                  label: 'Average rating',
                  value: ratingOrDash(summary.averageRating),
                  caption: '${summary.ratedCount} rated tasks',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFF5A524),
                ),
                StatTile(
                  label: 'Overdue',
                  value: '${summary.overdue}',
                  caption: '${summary.open} open in total',
                  icon: Icons.warning_amber_rounded,
                  color: palette.critical,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Quality & deadlines',
              child: Column(
                children: [
                  _RatingRow(
                    label: 'Completion quality',
                    value: summary.averageQuality,
                  ),
                  const SizedBox(height: 8),
                  _RatingRow(
                    label: 'Deadline achievement',
                    value: summary.averageTimeliness,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Tasks completed per week',
              child: WeeklyCompletionChart(weeks: summary.weeklyCompleted),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Status breakdown',
              child: StatusBreakdown(summary: summary),
            ),
            if (rated.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Recent ratings',
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    for (final task in rated.take(5))
                      ListTile(
                        title: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          task.rating!.note ??
                              'Rated ${Formatters.shortDate(task.rating!.ratedAt)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StarRating(value: task.rating!.overall, size: 14),
                            Text(
                              task.rating!.overall.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        onTap: () => context.push(AppRoutes.task(task.id)),
                      ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.pending_actions_rounded),
                label: Text('Open (${open.length})'),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.task_alt_rounded),
                label: Text('Completed (${completed.length})'),
              ),
            ],
            selected: {_showCompleted},
            onSelectionChanged: (value) =>
                setState(() => _showCompleted = value.first),
          ),
          const SizedBox(height: 12),
          if (visibleList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _showCompleted ? 'No completed tasks yet.' : 'No open tasks.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final TaskEntity task in visibleList)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(
                  task: task,
                  onTap: () => context.push(AppRoutes.task(task.id)),
                ),
              ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        if (value == null)
          Text(
            'Not rated yet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          StarRating(value: value!),
          const SizedBox(width: 8),
          Text(
            value!.toStringAsFixed(1),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
