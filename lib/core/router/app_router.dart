import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:transient_team_ws/core/widgets/brand.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/features/analytics/presentation/pages/employee_performance_page.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/features/app_control/presentation/blocked_page.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/auth/presentation/pages/auth_page.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/home/presentation/home_shell.dart';
import 'package:transient_team_ws/features/notifications/presentation/pages/notifications_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/task_details_page.dart';
import 'package:transient_team_ws/features/tasks/presentation/pages/task_form_page.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';
import 'package:transient_team_ws/features/team/presentation/pages/add_member_page.dart';

/// Re-runs redirects whenever auth or app-control state changes. Transient
/// `AuthLoading` states are ignored so the screen does not flicker.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.auth, this.control) {
    _authState = auth.state;
    _subscriptions = [
      auth.stream.listen((state) {
        if (state is AuthLoading) return;
        _authState = state;
        notifyListeners();
      }),
      control.stream.listen((_) => notifyListeners()),
    ];
  }

  final AuthBloc auth;
  final AppControlCubit control;
  late AuthState _authState;
  late final List<StreamSubscription<Object?>> _subscriptions;

  AuthState get authState => _authState;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

GoRouter createAppRouter({
  required AuthBloc auth,
  required AppControlCubit control,
}) {
  final refresh = _RouterRefresh(auth, control);

  String? redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    String? goTo(String target) => location == target ? null : target;

    final app = control.state;
    if (!app.isReady) return goTo(AppRoutes.splash);
    if (app.blockReason(DateTime.now()) != null) return goTo(AppRoutes.blocked);

    final authState = refresh.authState;
    if (authState is AuthInitial) return goTo(AppRoutes.splash);
    if (authState is! Authenticated) return goTo(AppRoutes.login);

    const publicRoutes = [AppRoutes.splash, AppRoutes.blocked, AppRoutes.login];
    if (publicRoutes.contains(location)) return AppRoutes.home;

    // Keep each role on its own tabs and screens.
    final isAdmin = authState.user.isAdmin;
    final adminOnly = [
      AppRoutes.team,
      AppRoutes.addMember,
      AppRoutes.newTaskPath,
    ];
    if (!isAdmin &&
        (adminOnly.contains(location) ||
            location.startsWith('/employee/') ||
            location.endsWith('/edit'))) {
      return AppRoutes.home;
    }
    if (isAdmin && location == AppRoutes.performance) return AppRoutes.home;
    return null;
  }

  Page<void> tabs(BuildContext context, GoRouterState state) {
    // One shared key: switching tabs updates this page in place, so every
    // tab keeps its scroll position and state.
    return NoTransitionPage(
      key: const ValueKey('home-tabs'),
      child: HomeTabs(location: state.matchedLocation),
    );
  }

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.blocked,
        builder: (context, _) => BlocBuilder<AppControlCubit, AppControlState>(
          builder: (context, app) => BlockedPage(
            reason:
                app.blockReason(DateTime.now()) ??
                BlockReason.subscriptionInvalid,
            flags: app.flags,
            subscription: app.subscription,
          ),
        ),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const AuthPage()),
      ShellRoute(
        builder: (context, state, child) => HomeScope(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, pageBuilder: tabs),
          GoRoute(path: AppRoutes.tasks, pageBuilder: tabs),
          GoRoute(path: AppRoutes.team, pageBuilder: tabs),
          GoRoute(path: AppRoutes.performance, pageBuilder: tabs),
          GoRoute(path: AppRoutes.profile, pageBuilder: tabs),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(
            path: AppRoutes.addMember,
            builder: (_, _) => const AddMemberPage(),
          ),
          GoRoute(
            path: AppRoutes.newTaskPath,
            builder: (_, state) => TaskFormPage(
              initialAssigneeId: state.uri.queryParameters['assignee'],
            ),
          ),
          GoRoute(
            path: AppRoutes.taskPath,
            builder: (_, state) =>
                TaskDetailsPage(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(
            path: AppRoutes.editTaskPath,
            builder: (context, state) {
              final task = context.read<TaskListBloc>().state.taskById(
                state.pathParameters['taskId']!,
              );
              if (task == null) return const _NotFound(AppStrings.taskNotFound);
              return TaskFormPage(task: task);
            },
          ),
          GoRoute(
            path: AppRoutes.employeePath,
            builder: (context, state) {
              final employee = context.watch<TeamCubit>().state.byId(
                state.pathParameters['userId'],
              );
              if (employee == null) {
                return const _NotFound('This employee could not be found.');
              }
              return EmployeePerformancePage(employee: employee);
            },
          ),
        ],
      ),
    ],
  );
}

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF3A044F),
      body: BrandBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoopiqLogo(width: 220),
              SizedBox(height: 32),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFF79331),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(icon: Icons.search_off_rounded, title: message),
    );
  }
}
