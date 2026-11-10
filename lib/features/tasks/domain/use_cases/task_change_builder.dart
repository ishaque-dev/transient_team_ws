import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:uuid/uuid.dart';

/// Builds the activity entries and notifications that accompany a task change.
///
/// Routing rule: when an employee changes a task, every admin hears about it;
/// when an admin changes a task, its assignee does (unless the admin is the
/// assignee).
class TaskChangeBuilder {
  TaskChangeBuilder({required this.actor, required this.uuid, DateTime? now})
    : now = now ?? DateTime.now();

  final UserEntity actor;
  final Uuid uuid;
  final DateTime now;

  TaskActivityEntity activity(
    TaskActivityType type,
    String message, {
    TaskStatus? toStatus,
  }) {
    return TaskActivityEntity(
      id: uuid.v4(),
      type: type,
      authorId: actor.id,
      authorName: actor.displayName,
      message: message,
      createdAt: now,
      toStatus: toStatus,
    );
  }

  /// Recipient for changes to [task] made by [actor], or null for nobody.
  String? recipientFor(TaskEntity task) {
    if (!actor.isAdmin) return AppNotificationEntity.adminsAudience;
    final assignee = task.assigneeId;
    if (assignee == null || assignee == actor.id) return null;
    return assignee;
  }

  List<AppNotificationEntity> notify(
    TaskEntity task,
    NotificationType type,
    String message, {
    String? recipient,
  }) {
    final target = recipient ?? recipientFor(task);
    if (target == null || target == actor.id) return const [];
    return [
      AppNotificationEntity(
        id: uuid.v4(),
        recipient: target,
        type: type,
        taskId: task.id,
        taskTitle: task.title,
        actorId: actor.id,
        actorName: actor.displayName,
        message: message,
        createdAt: now,
      ),
    ];
  }
}

String quoted(String title) => '“$title”';
