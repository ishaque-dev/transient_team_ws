import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

abstract interface class ITaskRemoteDs {
  /// All tasks when [assigneeId] is null, otherwise that person's tasks.
  Stream<List<TaskEntity>> watchTasks({String? assigneeId});

  /// Oldest first.
  Stream<List<TaskActivityEntity>> watchActivity(String taskId);

  Future<void> createTask(
    TaskEntity task,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  );

  Future<void> updateTask(
    TaskEntity task,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  );

  Future<void> updateStatus(
    String taskId,
    TaskStatus status,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  );

  Future<void> rateTask(
    String taskId,
    TaskRating rating,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  );

  Future<void> addActivity(
    String taskId,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  );

  Future<void> deleteTask(String taskId);
}
