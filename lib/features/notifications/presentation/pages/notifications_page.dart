import 'package:transient_team_ws/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/app_control/presentation/app_control_cubit.dart';
import 'package:transient_team_ws/core/theme/app_palette.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/core/utils/formatters.dart';
import 'package:transient_team_ws/core/widgets/feedback_views.dart';
import 'package:transient_team_ws/core/widgets/user_avatar.dart';
import 'package:transient_team_ws/features/home/presentation/home_scope.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/notifications/presentation/cubit/notifications_cubit.dart';

/// App-bar bell with an unread badge.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.select(
      (NotificationsCubit cubit) => cubit.state.unreadCount,
    );
    if (!context.flags.notifications) return const SizedBox.shrink();
    return IconButton(
      tooltip: unread == 0 ? 'Notifications' : '$unread unread notifications',
      onPressed: () => context.push(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(
          unread > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  /// Read marker as it was when the page opened, so new items stay
  /// highlighted while the user looks at them.
  late final DateTime? _seenAtOnOpen;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<NotificationsCubit>();
    _seenAtOnOpen = cubit.state.seenAt;
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.markAllSeen());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final today = dateOnly(DateTime.now());

    Widget body;
    if (state.status == NotificationsStatus.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.status == NotificationsStatus.failure &&
        state.items.isEmpty) {
      body = ErrorView(message: state.errorMessage ?? 'Could not load updates');
    } else if (state.items.isEmpty) {
      body = const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications yet',
        message:
            'Assignments, status changes, comments and ratings show up here in real time.',
      );
    } else {
      final todayItems = state.items
          .where((n) => dateOnly(n.createdAt) == today)
          .toList();
      final earlier = state.items
          .where((n) => dateOnly(n.createdAt) != today)
          .toList();
      body = ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (todayItems.isNotEmpty) ...[
            const _GroupHeader('Today'),
            for (final n in todayItems)
              _NotificationTile(
                notification: n,
                unread: n.isUnreadFor(_seenAtOnOpen),
              ),
          ],
          if (earlier.isNotEmpty) ...[
            const _GroupHeader('Earlier'),
            for (final n in earlier)
              _NotificationTile(
                notification: n,
                unread: n.isUnreadFor(_seenAtOnOpen),
              ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: body,
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.unread});

  final AppNotificationEntity notification;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = context.palette;
    final (IconData icon, Color color) = switch (notification.type) {
      NotificationType.taskAssigned => (
        Icons.assignment_ind_rounded,
        palette.todo,
      ),
      NotificationType.statusChanged => (
        Icons.published_with_changes_rounded,
        palette.completed,
      ),
      NotificationType.comment => (
        Icons.chat_bubble_outline_rounded,
        palette.onHold,
      ),
      NotificationType.rated => (Icons.star_rounded, const Color(0xFFF5A524)),
      NotificationType.taskUpdated => (
        Icons.edit_note_rounded,
        palette.inProgress,
      ),
      NotificationType.accessRequested => (
        Icons.person_add_alt_1_rounded,
        palette.todo,
      ),
    };

    return Material(
      color: unread ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(name: notification.actorName, size: 42),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ),
          ],
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: notification.actorName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' ${notification.message}'),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(Formatters.timeAgo(notification.createdAt)),
        trailing: unread
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: notification.isAboutTask
            ? () => context.push(AppRoutes.task(notification.taskId))
            : notification.type == NotificationType.accessRequested &&
                  context.currentUser.isAdmin
            ? () => context.go(AppRoutes.team)
            : null,
      ),
    );
  }
}
