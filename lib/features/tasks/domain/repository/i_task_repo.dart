import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

abstract interface class ITaskRepo {
  /// Retrieves a paginated list of tasks.
  Future<Either<Failure, List<TaskEntity>>> getTasks({
    int offset = 0,
    int limit = 10,
    String? query,
    TaskStatus? status,
    TaskPriority? priority,
  });

  /// Retrieves a specific task by its [id].
  Future<Either<Failure, TaskEntity>> getTaskById({required String id});

  /// Creates a new task and returns the created [TaskEntity].
  Future<Either<Failure, TaskEntity>> createTask({required TaskEntity task});

  /// Updates an existing task.
  Future<Either<Failure, TaskEntity>> updateTask({required TaskEntity task});

  /// Deletes a task by its [id].
  Future<Either<Failure, Unit>> deleteTask({required String id});
}
