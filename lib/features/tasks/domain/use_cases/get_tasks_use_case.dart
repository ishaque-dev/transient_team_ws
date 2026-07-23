import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

class GetTasksUseCase implements UseCase<List<TaskEntity>, GetTasksParams> {
  final ITaskRepo repository;

  GetTasksUseCase(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call({required GetTasksParams parameters}) {
    return repository.getTasks(
      offset: parameters.offset,
      limit: parameters.limit,
      query: parameters.query,
      status: parameters.status,
      priority: parameters.priority,
    );
  }
}

class GetTasksParams extends Equatable {
  final int offset;
  final int limit;
  final String? query;
  final TaskStatus? status;
  final TaskPriority? priority;

  const GetTasksParams({
    this.offset = 0,
    this.limit = 10,
    this.query,
    this.status,
    this.priority,
  });

  @override
  List<Object?> get props => [offset, limit, query, status, priority];
}
