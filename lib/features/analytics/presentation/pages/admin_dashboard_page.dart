import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/analytics/domain/performance_summary.dart';
import 'package:transient_team_ws/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/my_day_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/star_rating.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

/// Owner / admin home: team-wide delivery, quality and workload.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.onOpenTasks,
    required this.onOpenTeam,
  });

  final ValueChanged<TaskQuickFilter> onOpenTasks;
  final VoidCallback onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final taskState = context.watch<TaskListBloc>().state;
    final team = context.watch<TeamCubit>().state;
    final notifications = context.watch<NotificationsCubit>().state.items;
    final theme = Theme.of(context);
    final palette = context.palette;
    final now = DateTime.now();

    final insights = context.flags.performanceInsights;
    final tasks = taskState.tasks;
    final summary = PerformanceSummary.fromTasks(tasks, weeks: 8, now: now);
    final ranking = EmployeePerformance.rank(
      members: team.members,
      tasks: tasks,
      now: now,
    );
    final pending = team.inactiveEmployees.length;
    final toRate = tasks.where((t) => t.isCompleted && t.rating == null).length;
    final completedThisWeek = summary.weeklyCompleted.last.count;
    final attention =
        tasks
            .where(
              (t) =>
                  t.status.isOpen && calendarDaysBetween(now, t.dueDate) <= 2,
            )
            .toList()
          ..sort(TaskSort.dueDate.compare);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: taskState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                GradientBanner(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${greetingFor(now)}, ${user.firstName}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${summary.open} open tasks across '
                              '${team.employees.length} employees · '
                              '$completedThisWeek done this week',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (insights) ...[
                        const SizedBox(width: 12),
                        ScoreRing(score: summary.score, onDark: true),
                      ],
                    ],
                  ),
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.how_to_reg_rounded,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      title: Text(
                        '$pending ${pending == 1 ? 'person is' : 'people are'} waiting for approval',
                        style: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      onTap: onOpenTeam,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                StatGrid(
                  children: [
                    StatTile(
                      label: 'Open tasks',
                      value: '${summary.open}',
                      caption: '${summary.inProgress} in progress',
                      icon: Icons.pending_actions_rounded,
                      color: palette.todo,
                      onTap: () => onOpenTasks(TaskQuickFilter.open),
                    ),
                    StatTile(
                      label: 'Overdue',
                      value: '${summary.overdue}',
                      caption: '${summary.dueSoon} due in 3 days',
                      icon: Icons.warning_amber_rounded,
                      color: palette.critical,
                      onTap: () => onOpenTasks(TaskQuickFilter.overdue),
                    ),
                    StatTile(
                      label: 'Completed',
                      value: '${summary.completed}',
                      caption: '$completedThisWeek this week',
                      icon: Icons.task_alt_rounded,
                      color: palette.completed,
                      onTap: () => onOpenTasks(TaskQuickFilter.completed),
                    ),
                    StatTile(
                      label: 'Deadline achievement',
                      value: percentOrDash(summary.deadlineRate),
                      caption: 'finished on time',
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
                      label: 'Waiting for rating',
                      value: '$toRate',
                      caption: 'completed, not rated',
                      icon: Icons.rate_review_outlined,
                      color: palette.onHold,
                      onTap: () => onOpenTasks(TaskQuickFilter.toRate),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Status breakdown',
                  child: StatusBreakdown(summary: summary),
                ),
                if (insights) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Tasks completed per week',
                    child: WeeklyCompletionChart(
                      weeks: summary.weeklyCompleted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Employee performance',
                    trailing: const Tooltip(
                      message: scoreExplanation,
                      triggerMode: TooltipTriggerMode.tap,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.info_outline_rounded, size: 20),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ranking.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Add employees from the Team tab to see their performance.',
                            ),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < ranking.length; i++)
                                _LeaderboardRow(rank: i + 1, entry: ranking[i]),
                            ],
                          ),
                  ),
                ],
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Needs attention',
                  padding: const EdgeInsets.only(bottom: 8),
                  child: attention.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'Nothing overdue or due in the next 2 days.',
                          ),
                        )
                      : Column(
                          children: [
                            for (final task in attention.take(6))
                              _AttentionRow(task: task),
                          ],
                        ),
                ),
                if (notifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Recent updates',
                    trailing: TextButton(
                      onPressed: () => context.push(AppRoutes.notifications),
                      child: const Text('View all'),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        for (final n in notifications.take(5))
                          ListTile(
                            dense: true,
                            leading: UserAvatar(name: n.actorName, size: 32),
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: n.actorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: ' ${n.message}'),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(Formatters.timeAgo(n.createdAt)),
                            onTap: n.isAboutTask
                                ? () => context.push(AppRoutes.task(n.taskId))
                                : onOpenTeam,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});

  final int rank;
  final EmployeePerformance entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = entry.summary;
    return ListTile(
      onTap: () => context.push(AppRoutes.employee(entry.employee.id)),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(name: entry.employee.displayName),
          if (rank <= 3 && s.score != null)
            Positioned(
              right: -4,
              top: -4,
              child: CircleAvatar(
                radius: 9,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        entry.employee.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${s.completed}/${s.total} done'),
            Text('${percentOrDash(s.deadlineRate)} on time'),
            if (s.overdue > 0)
              Text(
                '${s.overdue} overdue',
                style: TextStyle(color: context.palette.critical),
              ),
            if (s.averageRating != null)
              StarRating(value: s.averageRating!, size: 13),
          ],
        ),
      ),
      subtitleTextStyle: theme.textTheme.labelMedium?.copyWith(color: muted),
      trailing: _ScoreBadge(score: s.score),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: palette.meterFill.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score?.toString() ?? '–',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'score',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(task.priority.icon, color: task.priority.color(context)),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Row(
        children: [
          Flexible(child: DueLabel(task)),
          Text('  ·  ${task.assigneeName ?? 'Unassigned'}'),
        ],
      ),
      trailing: StatusPill(task.status, dense: true),
      onTap: () => context.push(AppRoutes.task(task.id)),
    );
  }
}
