import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';

/// Every write is atomic with its activity entries and notifications.
abstract interface class ITaskRepo {
  Stream<Either<Failure, List<TaskEntity>>> watchTasks(TaskScope scope);

  Stream<Either<Failure, List<TaskActivityEntity>>> watchActivity(
    String taskId,
  );

  Future<Either<Failure, Unit>> createTask(
    TaskEntity task, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  });

  Future<Either<Failure, Unit>> updateTask(
    TaskEntity task, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  });

  /// Touches only the status fields, which is all an employee may change.
  Future<Either<Failure, Unit>> updateStatus(
    String taskId,
    TaskStatus status, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  });

  Future<Either<Failure, Unit>> rateTask(
    String taskId,
    TaskRating rating, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  });

  Future<Either<Failure, Unit>> addComment(
    String taskId, {
    required TaskActivityEntity comment,
    required List<AppNotificationEntity> notifications,
  });

  Future<Either<Failure, Unit>> deleteTask(String taskId);
}
