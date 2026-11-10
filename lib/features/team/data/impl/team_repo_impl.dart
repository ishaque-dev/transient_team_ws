import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/utils/either_stream.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/team/data/data_sources/i_team_remote_ds.dart';
import 'package:transient_team_ws/features/team/domain/repository/i_team_repo.dart';

class TeamRepoImpl implements ITeamRepo {
  TeamRepoImpl({required this.remoteDs});

  final ITeamRemoteDs remoteDs;

  @override
  Stream<Either<Failure, List<UserEntity>>> watchMembers() {
    return remoteDs
        .watchMembers()
        .map((models) => models.map((model) => model.toEntity()).toList())
        .toEither();
  }

  @override
  Future<Either<Failure, UserEntity>> addMember({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final model = await remoteDs.addMember(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return Right(model.toEntity());
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateRole(String userId, UserRole role) {
    return _run(() => remoteDs.updateRole(userId, role));
  }

  @override
  Future<Either<Failure, Unit>> setActive(String userId, bool isActive) {
    return _run(() => remoteDs.setActive(userId, isActive));
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
