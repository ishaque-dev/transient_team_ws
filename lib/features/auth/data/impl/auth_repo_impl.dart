import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/utils/either_stream.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_params.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

final class AuthRepoImpl implements IAuthRepo {
  AuthRepoImpl({required this.remoteDataSource, required this.localDataSource});

  final IAuthRemoteDs remoteDataSource;
  final IAuthLocalDs localDataSource;

  @override
  Future<Either<Failure, UserEntity>> login(LoginParams params) {
    return _signedIn(
      () => remoteDataSource.login(
        email: params.email,
        password: params.password,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(SignUpParams params) {
    return _signedIn(
      () => remoteDataSource.signUp(
        name: params.name,
        email: params.email,
        password: params.password,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity?>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();
      if (user == null) return const Right(null);
      await localDataSource.cacheCurrentUser(user);
      return Right(user.toEntity());
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    Failure? remoteFailure;
    try {
      await remoteDataSource.logout();
    } catch (error) {
      remoteFailure = AppErrorHandler.handle(error);
    }
    try {
      // Always forget the cached profile, even if the network call failed.
      await localDataSource.clearUser();
    } catch (_) {}
    return remoteFailure == null ? const Right(unit) : Left(remoteFailure);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.cacheCurrentUser(user);
      return Right(user.toEntity());
    } catch (error) {
      final failure = AppErrorHandler.handle(error);
      if (failure is NetworkFailure || failure is RequestTimeoutFailure) {
        // Offline cold start: trust the last known profile.
        final cached = await _cachedUser();
        if (cached != null) return Right(cached.toEntity());
      } else {
        await _clearCache();
      }
      return Left(failure);
    }
  }

  @override
  Stream<Either<Failure, UserEntity>> watchUser(String userId) {
    // Plain transforms (not async*) so cancelling the subscription returns
    // promptly; sign-out waits on nothing here.
    return remoteDataSource.watchUser(userId).asyncMap((user) async {
      if (user.isActive) {
        try {
          await localDataSource.cacheCurrentUser(user);
        } catch (_) {}
      }
      return user.toEntity();
    }).toEither();
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) {
    return _unit(() => remoteDataSource.sendPasswordReset(email));
  }

  @override
  Future<Either<Failure, Unit>> updateName(UpdateNameParams params) {
    return _unit(
      () =>
          remoteDataSource.updateName(userId: params.userId, name: params.name),
    );
  }

  @override
  Future<Either<Failure, Unit>> markNotificationsSeen(String userId) {
    return _unit(() => remoteDataSource.markNotificationsSeen(userId));
  }

  Future<Either<Failure, UserEntity>> _signedIn(
    Future<UserModel> Function() call,
  ) async {
    try {
      final user = await call();
      await localDataSource.cacheCurrentUser(user);
      return Right(user.toEntity());
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Unit>> _unit(Future<void> Function() call) async {
    try {
      await call();
      return const Right(unit);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<UserModel?> _cachedUser() async {
    try {
      return await localDataSource.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearCache() async {
    try {
      await localDataSource.clearUser();
    } catch (_) {}
  }
}
