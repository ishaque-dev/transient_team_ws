import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

abstract interface class IAuthRepo {
  Future<Either<Failure, UserEntity>> signUp({
    required AuthRequestParamEntity authRequestParams,
  });

  Future<Either<Failure, UserEntity>> login({
    required AuthRequestParamEntity authRequestParams,
  });

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();
}
