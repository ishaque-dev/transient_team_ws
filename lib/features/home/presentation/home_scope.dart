import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:transient_team_ws/core/di/di.dart';
import 'package:transient_team_ws/core/notifications/local_notifier.dart';
import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:transient_team_ws/core/utils/action_feedback.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:transient_team_ws/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:transient_team_ws/features/tasks/presentation/cubit/task_actions_cubit.dart';
import 'package:transient_team_ws/features/team/presentation/cubit/team_cubit.dart';

extension CurrentUserX on BuildContext {
  /// The signed-in user, provided by [HomeScope].
  UserEntity get currentUser => read<UserEntity>();
}

/// Wraps every signed-in route (the shell route) with the user's live data:
/// tasks, task actions, notifications and, for admins, the team.
class HomeScope extends StatefulWidget {
  const HomeScope({super.key, required this.child});

  final Widget child;

  @override
  State<HomeScope> createState() => _HomeScopeState();
}

class _HomeScopeState extends State<HomeScope> {
  UserEntity? _user;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    // Keep the last user while signing out, until the router leaves.
    if (state is Authenticated) _user = state.user;
    final user = _user;
    if (user == null) return const SizedBox.shrink();

    return RepositoryProvider.value(
      value: user,
      // Recreated when a different user signs in or the role changes.
      child: _HomeBlocs(
        key: ValueKey('${user.id}:${user.role.name}'),
        user: user,
        child: widget.child,
      ),
    );
  }
}

class _HomeBlocs extends StatefulWidget {
  const _HomeBlocs({super.key, required this.user, required this.child});

  final UserEntity user;
  final Widget child;

  @override
  State<_HomeBlocs> createState() => _HomeBlocsState();
}

class _HomeBlocsState extends State<_HomeBlocs> {
  late final TaskListBloc _tasks;
  late final TaskActionsCubit _actions;
  late final NotificationsCubit _notifications;
  TeamCubit? _team;
  StreamSubscription<String>? _notificationTaps;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _tasks = serviceLocator<TaskListBloc>(
      param1: user.isAdmin
          ? const TaskScope.all()
          : TaskScope.assignedTo(user.id),
    )..add(const TaskListSubscriptionRequested());
    _actions = serviceLocator<TaskActionsCubit>(param1: user);
    _notifications = serviceLocator<NotificationsCubit>(param1: user)..start();
    if (user.isAdmin) _team = serviceLocator<TeamCubit>(param1: user)..start();

    final notifier = serviceLocator<ILocalNotifier>();
    notifier.requestPermission();
    _notificationTaps = notifier.taps.listen(_openFromNotification);
  }

  void _openFromNotification(String payload) {
    if (!mounted) return;
    final router = GoRouter.of(context);
    if (payload == teamNotificationPayload) {
      if (widget.user.isAdmin) router.go(AppRoutes.team);
    } else {
      router.push(AppRoutes.task(payload));
    }
  }

  @override
  void dispose() {
    _notificationTaps?.cancel();
    _tasks.close();
    _actions.close();
    _notifications.close();
    _team?.close();
    super.dispose();
  }

  void _showFeedback(BuildContext context, ActionFeedback? feedback) {
    if (feedback != null) {
      showAppSnackBar(context, feedback.message, isError: feedback.isError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _tasks),
        BlocProvider.value(value: _actions),
        BlocProvider.value(value: _notifications),
        if (team != null) BlocProvider.value(value: team),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TaskActionsCubit, ActionFeedback?>(
            listener: _showFeedback,
          ),
          if (team != null)
            BlocListener<TeamCubit, TeamState>(
              listenWhen: (a, b) => a.feedback != b.feedback,
              listener: (context, state) =>
                  _showFeedback(context, state.feedback),
            ),
        ],
        child: widget.child,
      ),
    );
  }
}
