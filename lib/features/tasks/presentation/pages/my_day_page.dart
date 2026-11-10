import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_card.dart';

String greetingFor(DateTime now) {
  if (now.hour < 12) return AppStrings.goodMorning;
  if (now.hour < 17) return AppStrings.goodAfternoon;
  return AppStrings.goodEvening;
}

/// Employee home: the tasks due on a chosen day, completed with one tap.
class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  static const _daysBefore = 3;
  static const _daysAfter = 10;

  late DateTime _selectedDay = dateOnly(DateTime.now());

  Future<void> _toggle(TaskEntity task) async {
    final actions = context.read<TaskActionsCubit>();
    final previous = task.status;
    final next = task.isCompleted
        ? TaskStatus.inProgress
        : TaskStatus.completed;
    final ok = await actions.changeStatus(task, next);
    if (!ok || !mounted || next != TaskStatus.completed) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Completed “${task.title}”. Your admin was notified.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => actions.changeStatus(
              task.copyWith(status: TaskStatus.completed),
              previous,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final statusUpdates = context.flags.statusUpdate;
    final state = context.watch<TaskListBloc>().state;
    final now = DateTime.now();
    final today = dateOnly(now);
    final isToday = _selectedDay == today;
    final tasks = state.tasks;

    final dueThatDay = tasks.where((t) => isDueOn(t, _selectedDay)).toList()
      ..sort(TaskSort.priority.compare);
    final overdue = isToday
        ? (tasks.where((t) => t.isOverdue(now)).toList()
            ..sort(TaskSort.dueDate.compare))
        : <TaskEntity>[];
    final open = dueThatDay.where((t) => !t.isCompleted).toList();
    final done = dueThatDay.where((t) => t.isCompleted).toList();
    final completedToday = tasks
        .where(
          (t) => t.completedAt != null && dateOnly(t.completedAt!) == today,
        )
        .length;
    final todayTotal =
        tasks.where((t) => isDueOn(t, today)).length +
        tasks.where((t) => t.isOverdue(now)).length;

    Widget taskTile(TaskEntity task) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TaskCard(
        task: task,
        onTap: () => context.push(AppRoutes.task(task.id)),
        onToggleComplete: statusUpdates ? () => _toggle(task) : null,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My day'),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _DayBanner(
                  name: user.firstName,
                  completedToday: completedToday,
                  remainingToday:
                      todayTotal -
                      tasks
                          .where((t) => isDueOn(t, today) && t.isCompleted)
                          .length,
                ),
                const SizedBox(height: 16),
                _DateStrip(
                  start: today.subtract(const Duration(days: _daysBefore)),
                  count: _daysBefore + _daysAfter + 1,
                  selected: _selectedDay,
                  tasks: tasks,
                  onSelected: (day) => setState(() => _selectedDay = day),
                ),
                const SizedBox(height: 16),
                if (overdue.isNotEmpty) ...[
                  _SectionLabel(
                    icon: Icons.warning_amber_rounded,
                    text: 'Overdue · ${overdue.length}',
                    critical: true,
                  ),
                  ...overdue.map(taskTile),
                  const SizedBox(height: 8),
                ],
                _SectionLabel(
                  icon: Icons.today_rounded,
                  text: isToday
                      ? 'Due today · ${open.length}'
                      : '${DateFormat('EEEE, d MMM').format(_selectedDay)} · ${open.length}',
                ),
                if (open.isEmpty && overdue.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      icon: Icons.celebration_rounded,
                      title: dueThatDay.isEmpty
                          ? 'Nothing due ${isToday ? 'today' : 'this day'}'
                          : 'All done for ${isToday ? 'today' : 'this day'}!',
                      message: dueThatDay.isEmpty
                          ? 'Pick another day above or check My tasks.'
                          : 'Great work. Completed tasks are listed below.',
                    ),
                  )
                else
                  ...open.map(taskTile),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionLabel(
                    icon: Icons.task_alt_rounded,
                    text: 'Completed · ${done.length}',
                  ),
                  ...done.map(taskTile),
                ],
              ],
            ),
    );
  }
}

class _DayBanner extends StatelessWidget {
  const _DayBanner({
    required this.name,
    required this.completedToday,
    required this.remainingToday,
  });

  final String name;
  final int completedToday;
  final int remainingToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = completedToday + remainingToday;
    final progress = total == 0 ? 0.0 : completedToday / total;

    return GradientBanner(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${greetingFor(DateTime.now())}, $name',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remainingToday <= 0
                      ? (completedToday == 0
                            ? 'Your day is clear.'
                            : 'Everything for today is done!')
                      : '$remainingToday task${remainingToday == 1 ? '' : 's'} left for today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
                Center(
                  child: Text(
                    '$completedToday/$total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateStrip extends StatefulWidget {
  const _DateStrip({
    required this.start,
    required this.count,
    required this.selected,
    required this.tasks,
    required this.onSelected,
  });

  final DateTime start;
  final int count;
  final DateTime selected;
  final List<TaskEntity> tasks;
  final ValueChanged<DateTime> onSelected;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  // Starts with today near the left edge (two days of history visible).
  final _controller = ScrollController(initialScrollOffset: 62);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = dateOnly(DateTime.now());
    final start = widget.start;

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.count,
        controller: _controller,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = DateTime(start.year, start.month, start.day + index);
          final isSelected = day == widget.selected;
          final openCount = widget.tasks
              .where((t) => isDueOn(t, day) && !t.isCompleted)
              .length;
          final foreground = isSelected ? scheme.onPrimary : scheme.onSurface;

          return Semantics(
            button: true,
            selected: isSelected,
            label:
                '${DateFormat('EEEE d MMMM').format(day)}, $openCount open tasks',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => widget.onSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 54,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: day == today && !isSelected
                        ? scheme.primary
                        : scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(day),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: openCount == 0
                            ? Colors.transparent
                            : (isSelected ? scheme.onPrimary : scheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
    this.critical = false,
  });

  final IconData icon;
  final String text;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = critical
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(
              color: critical ? color : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
