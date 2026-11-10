import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_params.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  LoginUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, UserEntity>> call({required LoginParams parameters}) {
    return authRepository.login(parameters);
  }
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  SignUpUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, UserEntity>> call({
    required SignUpParams parameters,
  }) async {
    if (parameters.name.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter your name.'));
    }
    return authRepository.signUp(parameters);
  }
}

class GoogleSignInUseCase implements UseCase<UserEntity?, NoParam> {
  GoogleSignInUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, UserEntity?>> call({required NoParam parameters}) {
    return authRepository.signInWithGoogle();
  }
}

class LogoutUseCase implements UseCase<Unit, NoParam> {
  LogoutUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, Unit>> call({required NoParam parameters}) {
    return authRepository.logout();
  }
}

class GetLoggedInUserUseCase implements UseCase<UserEntity, NoParam> {
  GetLoggedInUserUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, UserEntity>> call({required NoParam parameters}) {
    return authRepository.getCurrentUser();
  }
}

class WatchUserProfileUseCase implements UseCaseStream<UserEntity, String> {
  WatchUserProfileUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Stream<Either<Failure, UserEntity>> call({required String parameters}) {
    return authRepository.watchUser(parameters);
  }
}

class SendPasswordResetUseCase implements UseCase<Unit, String> {
  SendPasswordResetUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, Unit>> call({required String parameters}) async {
    final email = parameters.trim();
    if (email.isEmpty) {
      return Left(ValidationFailure(message: 'Enter your email first.'));
    }
    return authRepository.sendPasswordReset(email);
  }
}

class UpdateDisplayNameUseCase implements UseCase<Unit, UpdateNameParams> {
  UpdateDisplayNameUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, Unit>> call({
    required UpdateNameParams parameters,
  }) async {
    final name = parameters.name.trim();
    if (name.isEmpty) {
      return Left(ValidationFailure(message: 'Name cannot be empty.'));
    }
    return authRepository.updateName(
      UpdateNameParams(userId: parameters.userId, name: name),
    );
  }
}

class MarkNotificationsSeenUseCase implements UseCase<Unit, String> {
  MarkNotificationsSeenUseCase({required this.authRepository});
  final IAuthRepo authRepository;

  @override
  Future<Either<Failure, Unit>> call({required String parameters}) {
    return authRepository.markNotificationsSeen(parameters);
  }
}
