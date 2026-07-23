import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:uuid/uuid.dart';

class CreateTaskUseCase implements UseCase<TaskEntity, TaskEntity> {
  final ITaskRepo repository;
  final Uuid uuid;

  CreateTaskUseCase(this.repository, {this.uuid = const Uuid()});

  @override
  Future<Either<Failure, TaskEntity>> call({required TaskEntity parameters}) {
    // Generate UUID and assign to task before saving
    final taskWithId = parameters.copyWith(id: uuid.v4());
    
    return repository.createTask(task: taskWithId);
  }
}
