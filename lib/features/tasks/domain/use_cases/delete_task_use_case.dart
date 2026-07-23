import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';

class DeleteTaskUseCase implements UseCase<Unit, String> {
  final ITaskRepo repository;

  DeleteTaskUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call({required String parameters}) {
    return repository.deleteTask(id: parameters);
  }
}
