import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/auth_request_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

final class AuthRepoImpl implements IAuthRepo {
  AuthRepoImpl({
    required this._remoteDataSource,
    required this._localDataSource,
  });

  final IAuthRemoteDs _remoteDataSource;
  final IAuthLocalDs _localDataSource;

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required AuthRequestParamEntity authRequestParams,
  }) async {
    try {
      final user = await _remoteDataSource.signUp(
        authRequestParmModel: AuthRequestParamModel.fromEntity(
          authParam: authRequestParams,
        ),
      );
      await _localDataSource.cacheCurrentUser(user);
      return right(user.toEntity());
    } catch (error) {
      return left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required AuthRequestParamEntity authRequestParams,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        authRequestParmModel: AuthRequestParamModel.fromEntity(
          authParam: authRequestParams,
        ),
      );
      await _localDataSource.cacheCurrentUser(user);
      return right(user.toEntity());
    } catch (error) {
      return left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _remoteDataSource.logout();
      await _localDataSource.clearUser();
      return right(unit);
    } catch (error) {
      return left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // The cache gives an immediate answer for app start and offline use.
      final cachedUser = await _localDataSource.getCurrentUser();
      if (cachedUser != null) {
        return right(cachedUser.toEntity());
      }
      final remoteUser = await _remoteDataSource.getCurrentUser();
      await _localDataSource.cacheCurrentUser(remoteUser);
      return right(remoteUser.toEntity());
    } catch (error) {
      return left(AppErrorHandler.handle(error));
    }
  }
}
