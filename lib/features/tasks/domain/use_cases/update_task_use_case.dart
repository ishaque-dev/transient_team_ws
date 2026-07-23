import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

class UpdateTaskUseCase implements UseCase<TaskEntity, TaskEntity> {
  final ITaskRepo repository;

  UpdateTaskUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call({required TaskEntity parameters}) {
    return repository.updateTask(task: parameters);
  }
}
