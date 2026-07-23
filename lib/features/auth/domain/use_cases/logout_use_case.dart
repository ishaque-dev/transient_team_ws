import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

class LogoutUseCase implements UseCase<Unit, NoParam> {
  final IAuthRepo authRepository;

  LogoutUseCase({required this.authRepository});

  @override
  Future<Either<Failure, Unit>> call({required NoParam parameters}) {
    return authRepository.logout();
  }
}
