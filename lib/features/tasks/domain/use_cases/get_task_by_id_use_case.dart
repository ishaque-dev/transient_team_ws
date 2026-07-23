import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

class GetTaskByIdUseCase implements UseCase<TaskEntity, String> {
  final ITaskRepo repository;

  GetTaskByIdUseCase(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call({required String parameters}) {
    return repository.getTaskById(id: parameters);
  }
}
