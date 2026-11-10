import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_card.dart';
import 'package:transient_team_ws/features/tasks/presentation/widgets/task_visuals.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

/// Searchable, filterable task list. Admins see every task; employees see
/// their own.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setCriteria(TaskFilterCriteria criteria) =>
      context.read<TaskListBloc>().add(TaskListCriteriaChanged(criteria));

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final isAdmin = user.isAdmin;
    final flags = context.flags;
    final criteria = context.select((TaskListBloc bloc) => bloc.state.criteria);

    final quickFilters = [
      for (final filter in TaskQuickFilter.values)
        if (filter != TaskQuickFilter.toRate || isAdmin) filter,
    ];

    return BlocListener<TaskListBloc, TaskListState>(
      // Filters set from elsewhere (e.g. a dashboard tile) reset the search.
      listenWhen: (previous, current) =>
          previous.criteria.query != current.criteria.query,
      listener: (context, state) {
        if (state.criteria.query.isEmpty && _searchController.text.isNotEmpty) {
          setState(_searchController.clear);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? AppStrings.tasks : AppStrings.myTasks),
          actions: [
            PopupMenuButton<TaskSort>(
              tooltip: AppStrings.sortBy,
              icon: const Icon(Icons.swap_vert_rounded),
              initialValue: criteria.sort,
              onSelected: (sort) => _setCriteria(criteria.copyWith(sort: sort)),
              itemBuilder: (_) => [
                for (final sort in TaskSort.values)
                  CheckedPopupMenuItem(
                    value: sort,
                    checked: sort == criteria.sort,
                    child: Text(sort.label),
                  ),
              ],
            ),
            const NotificationBell(),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: isAdmin && flags.createTask
            ? FloatingActionButton.extended(
                heroTag: 'new-task',
                onPressed: () => context.push(AppRoutes.newTask()),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text(AppStrings.newTask),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: AppStrings.searchTasks,
                elevation: const WidgetStatePropertyAll(0),
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        context.read<TaskListBloc>().add(
                          const TaskListQueryChanged(''),
                        );
                        setState(() {});
                      },
                    ),
                ],
                onChanged: (query) {
                  setState(() {});
                  context.read<TaskListBloc>().add(TaskListQueryChanged(query));
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final filter in quickFilters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: criteria.quickFilter == filter,
                        onSelected: (_) => _setCriteria(
                          criteria.copyWith(quickFilter: filter),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  _PriorityFilter(criteria: criteria, onChanged: _setCriteria),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    _AssigneeFilter(
                      criteria: criteria,
                      onChanged: _setCriteria,
                    ),
                  ],
                  const Spacer(),
                  if (criteria.hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _setCriteria(TaskFilterCriteria(sort: criteria.sort));
                      },
                      child: const Text(AppStrings.clearFilters),
                    ),
                ],
              ),
            ),
            const Expanded(child: _TaskList()),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;
    final statusUpdates = context.flags.statusUpdate;
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == TaskListStatus.failure && state.tasks.isEmpty) {
          return ErrorView(
            message: state.errorMessage ?? AppStrings.failedToLoadTasks,
            onRetry: () => context.read<TaskListBloc>().add(
              const TaskListSubscriptionRequested(),
            ),
          );
        }
        final tasks = state.visibleTasks;
        if (tasks.isEmpty) {
          if (state.tasks.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_rounded,
              title: user.isAdmin ? 'No tasks yet' : AppStrings.allCaughtUp,
              message: user.isAdmin
                  ? AppStrings.noTasksYetAdmin
                  : AppStrings.noTasksYetMember,
            );
          }
          return const EmptyState(
            icon: Icons.filter_alt_off_rounded,
            title: AppStrings.noMatches,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: tasks.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            final task = tasks[index - 1];
            final canToggle =
                statusUpdates && (user.isAdmin || task.assigneeId == user.id);
            return TaskCard(
              task: task,
              showAssignee: user.isAdmin,
              onTap: () => context.push(AppRoutes.task(task.id)),
              onToggleComplete: canToggle
                  ? () => context.read<TaskActionsCubit>().changeStatus(
                      task,
                      task.isCompleted
                          ? TaskStatus.inProgress
                          : TaskStatus.completed,
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _PriorityFilter extends StatelessWidget {
  const _PriorityFilter({required this.criteria, required this.onChanged});

  final TaskFilterCriteria criteria;
  final ValueChanged<TaskFilterCriteria> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = criteria.priority;
    return PopupMenuButton<TaskPriority?>(
      tooltip: AppStrings.priority,
      onSelected: (value) =>
          onChanged(criteria.copyWith(priority: () => value)),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text(AppStrings.anyPriority)),
        for (final priority in TaskPriority.values.reversed)
          PopupMenuItem(
            value: priority,
            child: Row(
              children: [
                Icon(priority.icon, color: priority.color(context), size: 18),
                const SizedBox(width: 8),
                Text(priority.label),
              ],
            ),
          ),
      ],
      child: _FilterButton(
        icon: selected?.icon ?? Icons.flag_outlined,
        label: selected?.label ?? AppStrings.priority,
        active: selected != null,
      ),
    );
  }
}

class _AssigneeFilter extends StatelessWidget {
  const _AssigneeFilter({required this.criteria, required this.onChanged});

  final TaskFilterCriteria criteria;
  final ValueChanged<TaskFilterCriteria> onChanged;

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamCubit>().state;
    final selectedId = criteria.assigneeId;
    final label = switch (selectedId) {
      null => AppStrings.assignee,
      TaskFilterCriteria.unassigned => AppStrings.unassigned,
      _ => team.byId(selectedId)?.firstName ?? AppStrings.assignee,
    };

    return PopupMenuButton<String?>(
      tooltip: AppStrings.assignee,
      onSelected: (value) =>
          onChanged(criteria.copyWith(assigneeId: () => value)),
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text(AppStrings.anyone)),
        const PopupMenuItem(
          value: TaskFilterCriteria.unassigned,
          child: Text(AppStrings.unassigned),
        ),
        for (final member in team.employees)
          PopupMenuItem(
            value: member.id,
            child: Row(
              children: [
                UserAvatar(name: member.displayName, size: 24),
                const SizedBox(width: 10),
                Text(member.displayName),
              ],
            ),
          ),
      ],
      child: _FilterButton(
        icon: Icons.person_outline_rounded,
        label: label,
        active: selectedId != null,
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? scheme.secondaryContainer : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const Icon(Icons.arrow_drop_down_rounded, size: 20),
        ],
      ),
    );
  }
}
