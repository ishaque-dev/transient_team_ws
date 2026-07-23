import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_local_ds.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

class TaskRepoImpl implements ITaskRepo {
  final ITaskRemoteDs _remoteDs;
  final ITaskLocalDs _localDs;
  final IAuthLocalDs _authLocalDs;

  TaskRepoImpl({
    required this._remoteDs,
    required this._localDs,
    required this._authLocalDs,
  });

  Future<String> _getUserId() async {
    final user = await _authLocalDs.getCurrentUser();
    if (user == null) {
      throw UnauthorizedFailure(message: 'User not logged in');
    }
    return user.id;
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks({
    int offset = 0,
    int limit = 10,
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
  }) async {
    try {
      final userId = await _getUserId();

      // 1. Fetch from remote (Source of Truth)
      final remoteTasks = await _remoteDs.getTasks(
        userId: userId,
        offset: offset,
        limit: limit,
        query: query,
        status: status?.name,
        priority: priority?.name,
      );

      // 2. Cache the fetched tasks locally
      if (remoteTasks.isNotEmpty) {
        await _localDs.cacheTasks(remoteTasks);
      }

      // 3. Perform filtering and sorting always locally from the indexed DB
      final localTasks = await _localDs.getTasks(
        offset: offset,
        limit: limit,
        query: query,
        status: status?.name,
        priority: priority?.name,
      );

      return Right(localTasks.map((e) => e.toEntity()).toList());
    } catch (error) {
      // 4. On network failure, fall back to local database
      try {
        final localTasks = await _localDs.getTasks(
          offset: offset,
          limit: limit,
          query: query,
          status: status?.name,
          priority: priority?.name,
        );
        return Right(localTasks.map((e) => e.toEntity()).toList());
      } catch (e) {
        return Left(AppErrorHandler.handle(e));
      }
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById({required String id}) async {
    try {
      final localTask = await _localDs.getTaskById(id);
      if (localTask != null) {
        return Right(localTask.toEntity());
      }
      return Left(NotFoundFailure());
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> createTask({required TaskEntity task}) async {
    try {
      final userId = await _getUserId();
      final taskModel = TaskModel.fromEntity(task);
      
      // 1. Sync to remote (Source of Truth)
      await _remoteDs.createTask(userId: userId, task: taskModel);
      
      // 2. Insert into local
      await _localDs.insertTask(taskModel);
      
      return Right(task);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask({required TaskEntity task}) async {
    try {
      final userId = await _getUserId();
      final taskModel = TaskModel.fromEntity(task);
      
      // 1. Update remote
      await _remoteDs.updateTask(userId: userId, task: taskModel);
      
      // 2. Update local
      await _localDs.updateTask(taskModel);
      
      return Right(task);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTask({required String id}) async {
    try {
      final userId = await _getUserId();
      await _remoteDs.deleteTask(userId: userId, taskId: id);
      await _localDs.deleteTask(id);
      return const Right(unit);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
