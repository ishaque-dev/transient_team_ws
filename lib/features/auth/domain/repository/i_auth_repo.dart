import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

abstract interface class IAuthRepo {
  Future<Either<UserEntity, Failure>> signUp({
    required String email,
    required String password,
  });

  Future<Either<UserEntity, Failure>> login({
    required String email,
    required String password,
  });

  Future<Either<Unit, Failure>> logout();

  Future<Either<UserEntity, Failure>> getCurrentUser();
}
