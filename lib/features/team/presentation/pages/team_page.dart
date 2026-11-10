import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/analytics/domain/performance_summary.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    final team = context.watch<TeamCubit>().state;
    final tasks = context.select((TaskListBloc bloc) => bloc.state.tasks);
    final inactive = team.inactiveEmployees;
    final employees = team.employees;

    PerformanceSummary summaryFor(UserEntity member) =>
        PerformanceSummary.fromTasks(
          tasks.where((t) => t.assigneeId == member.id),
        );

    Widget body;
    if (team.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (team.errorMessage != null && team.members.isEmpty) {
      body = ErrorView(
        message: team.errorMessage!,
        onRetry: context.read<TeamCubit>().start,
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          if (inactive.isNotEmpty)
            _Group(
              title: '${AppStrings.inactiveMembers} · ${inactive.length}',
              children: [
                for (final m in inactive) _MemberTile(member: m, summary: null),
              ],
            ),
          _Group(
            title: 'Employees · ${employees.length}',
            children: employees.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No employees yet. Add your first teammate.'),
                    ),
                  ]
                : [
                    for (final m in employees)
                      _MemberTile(member: m, summary: summaryFor(m)),
                  ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.team),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      floatingActionButton: !context.flags.addMember
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add-member',
              onPressed: () => context.push(AppRoutes.addMember),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(AppStrings.addMember),
            ),
      body: body,
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

enum _MemberAction { viewPerformance, activate, deactivate }

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.summary});

  final UserEntity member;
  final PerformanceSummary? summary;

  Future<void> _onAction(BuildContext context, _MemberAction action) async {
    final cubit = context.read<TeamCubit>();
    switch (action) {
      case _MemberAction.viewPerformance:
        context.push(AppRoutes.employee(member.id));
      case _MemberAction.activate:
        await cubit.setActive(member, true);
      case _MemberAction.deactivate:
        final confirmed = await showConfirmDialog(
          context,
          title: 'Deactivate ${member.displayName}?',
          message:
              'They will be signed out and can no longer access the workspace. '
              'Their tasks stay assigned to them.',
          confirmLabel: AppStrings.deactivate,
          destructive: true,
        );
        if (confirmed) await cubit.setActive(member, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = summary;
    final canManage = context.flags.memberManagement;

    final subtitle = !member.isActive
        ? Text(member.email)
        : Text(
            s == null || s.total == 0
                ? member.email
                : '${s.open} open · ${s.completed} done'
                      '${s.overdue > 0 ? ' · ${s.overdue} overdue' : ''}',
            style: TextStyle(
              color: (s?.overdue ?? 0) > 0 ? palette.critical : muted,
            ),
          );

    return ListTile(
      onTap: member.isActive
          ? () => context.push(AppRoutes.employee(member.id))
          : null,
      leading: UserAvatar(name: member.displayName),
      title: Text(
        member.displayName,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle,
      trailing: !member.isActive
          ? !canManage
                ? null
                : FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () => _onAction(context, _MemberAction.activate),
                    child: const Text('Approve'),
                  )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s?.score != null)
                  Text(
                    '${s!.score}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                PopupMenuButton<_MemberAction>(
                  tooltip: 'Manage ${member.displayName}',
                  onSelected: (action) => _onAction(context, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: _MemberAction.viewPerformance,
                      child: Text('View performance'),
                    ),
                    if (canManage)
                      const PopupMenuItem(
                        value: _MemberAction.deactivate,
                        child: Text(AppStrings.deactivate),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}
