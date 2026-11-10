import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/utils/either_stream.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

/// Firestore is the source of truth. Its built-in offline cache serves reads
/// and queues writes while the device is offline.
class TaskRepoImpl implements ITaskRepo {
  TaskRepoImpl({required this.remoteDs});

  final ITaskRemoteDs remoteDs;

  @override
  Stream<Either<Failure, List<TaskEntity>>> watchTasks(TaskScope scope) {
    return remoteDs.watchTasks(assigneeId: scope.assigneeId).toEither();
  }

  @override
  Stream<Either<Failure, List<TaskActivityEntity>>> watchActivity(
    String taskId,
  ) {
    return remoteDs.watchActivity(taskId).toEither();
  }

  @override
  Future<Either<Failure, Unit>> createTask(
    TaskEntity task, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  }) {
    return _run(() => remoteDs.createTask(task, activities, notifications));
  }

  @override
  Future<Either<Failure, Unit>> updateTask(
    TaskEntity task, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  }) {
    return _run(() => remoteDs.updateTask(task, activities, notifications));
  }

  @override
  Future<Either<Failure, Unit>> updateStatus(
    String taskId,
    TaskStatus status, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  }) {
    return _run(
      () => remoteDs.updateStatus(taskId, status, activities, notifications),
    );
  }

  @override
  Future<Either<Failure, Unit>> rateTask(
    String taskId,
    TaskRating rating, {
    required List<TaskActivityEntity> activities,
    required List<AppNotificationEntity> notifications,
  }) {
    return _run(
      () => remoteDs.rateTask(taskId, rating, activities, notifications),
    );
  }

  @override
  Future<Either<Failure, Unit>> addComment(
    String taskId, {
    required TaskActivityEntity comment,
    required List<AppNotificationEntity> notifications,
  }) {
    return _run(() => remoteDs.addActivity(taskId, [comment], notifications));
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String taskId) {
    return _run(() => remoteDs.deleteTask(taskId));
  }

  Future<Either<Failure, Unit>> _run(Future<void> Function() call) async {
    try {
      await call();
      return const Right(unit);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }
}
