import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

abstract interface class ITeamRepo {
  Stream<Either<Failure, List<UserEntity>>> watchMembers();

  Future<Either<Failure, UserEntity>> addMember({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<Either<Failure, Unit>> updateRole(String userId, UserRole role);

  Future<Either<Failure, Unit>> setActive(String userId, bool isActive);
}
