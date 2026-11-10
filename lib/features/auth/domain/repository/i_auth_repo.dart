import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_params.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

abstract interface class IAuthRepo {
  Future<Either<Failure, UserEntity>> login(LoginParams params);

  /// Returns `Left(AccountInactiveFailure)` when the new account must wait for
  /// an admin's approval (every account except the very first one).
  Future<Either<Failure, UserEntity>> signUp(SignUpParams params);

  /// `Right(null)` means the user closed the Google account picker.
  Future<Either<Failure, UserEntity?>> signInWithGoogle();

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Live profile, so role changes and deactivation apply immediately.
  Stream<Either<Failure, UserEntity>> watchUser(String userId);

  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  Future<Either<Failure, Unit>> updateName(UpdateNameParams params);

  Future<Either<Failure, Unit>> markNotificationsSeen(String userId);
}
