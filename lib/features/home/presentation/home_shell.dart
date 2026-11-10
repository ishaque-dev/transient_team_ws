import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:transient_team_ws/features/analytics/presentation/pages/admin_dashboard_page.dart';
import 'package:transient_team_ws/features/analytics/presentation/pages/employee_performance_page.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/profile/presentation/pages/profile_page.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/my_day_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/tasks_page.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';
import 'package:transient_team_ws/features/team/presentation/pages/team_page.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Role-based tab bar. Admins: Dashboard / Tasks / Team / Profile.
/// Employees: My day / My tasks / Performance / Profile. The selected tab
/// comes from the route ([location]); tab pages stay alive in an
/// [IndexedStack] while switching.
class HomeTabs extends StatelessWidget {
  const HomeTabs({super.key, required this.location});

  final String location;

  static const _admin = [
    _Destination(
      'Dashboard',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
    ),
    _Destination(
      AppStrings.tasks,
      Icons.checklist_rounded,
      Icons.checklist_rtl_rounded,
    ),
    _Destination(AppStrings.team, Icons.groups_outlined, Icons.groups_rounded),
    _Destination(
      AppStrings.profile,
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  static const _employee = [
    _Destination('My day', Icons.today_outlined, Icons.today_rounded),
    _Destination(
      AppStrings.myTasks,
      Icons.checklist_rounded,
      Icons.checklist_rtl_rounded,
    ),
    _Destination(
      'Performance',
      Icons.insights_outlined,
      Icons.insights_rounded,
    ),
    _Destination(
      AppStrings.profile,
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserEntity>();
    final isAdmin = user.isAdmin;
    final paths = isAdmin ? AppRoutes.adminTabs : AppRoutes.employeeTabs;
    final destinations = isAdmin ? _admin : _employee;
    final index = paths.indexOf(location).clamp(0, paths.length - 1);

    void openTasks(TaskQuickFilter filter) {
      final tasks = context.read<TaskListBloc>();
      tasks.add(
        TaskListCriteriaChanged(
          TaskFilterCriteria(
            quickFilter: filter,
            sort: tasks.state.criteria.sort,
          ),
        ),
      );
      context.go(AppRoutes.tasks);
    }

    final pages = isAdmin
        ? [
            AdminDashboardPage(
              onOpenTasks: openTasks,
              onOpenTeam: () => context.go(AppRoutes.team),
            ),
            const TasksPage(),
            const TeamPage(),
            const ProfilePage(),
          ]
        : [
            const MyDayPage(),
            const TasksPage(),
            EmployeePerformancePage(employee: user, isSelfView: true),
            const ProfilePage(),
          ];

        // Read here in build (not inside LayoutBuilder's callback).
    final now = DateTime.now();
    final pendingApprovals = isAdmin
        ? context.select(
            (TeamCubit cubit) => cubit.state.inactiveEmployees.length,
          )
        : 0;
    final overdue = isAdmin
        ? 0
        : context.select(
            (TaskListBloc bloc) =>
                bloc.state.tasks.where((t) => t.isOverdue(now)).length,
          );
    int badgeFor(int i) {
      if (isAdmin && i == 2) return pendingApprovals;
      if (!isAdmin && i == 0) return overdue;
      return 0;
    }

    Widget icon(int i, {required bool selected}) {
      final count = badgeFor(i);
      return Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(
          selected ? destinations[i].selectedIcon : destinations[i].icon,
        ),
      );
    }

    final badges = [for (var i = 0; i < destinations.length; i++) i];
    void select(int i) => context.go(paths[i]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = IndexedStack(index: index, children: pages);
        if (constraints.maxWidth < 840) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: [
                for (final i in badges)
                  NavigationDestination(
                    icon: icon(i, selected: false),
                    selectedIcon: icon(i, selected: true),
                    label: destinations[i].label,
                  ),
              ],
            ),
          );
        }
        final extended = constraints.maxWidth >= 1200;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extended,
                selectedIndex: index,
                onDestinationSelected: select,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final i in badges)
                    NavigationRailDestination(
                      icon: icon(i, selected: false),
                      selectedIcon: icon(i, selected: true),
                      label: Text(destinations[i].label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
