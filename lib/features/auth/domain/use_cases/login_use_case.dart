import 'package:fpdart/fpdart.dart' show Either;
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

class LoginUseCase implements UseCase<UserEntity, AuthRequestParamEntity> {
  final IAuthRepo authRepository;

  LoginUseCase({required this.authRepository});
  @override
  Future<Either<Failure, UserEntity>> call({
    required AuthRequestParamEntity parameters,
  }) {
    return authRepository.login(authRequestParams: parameters);
  }
}
