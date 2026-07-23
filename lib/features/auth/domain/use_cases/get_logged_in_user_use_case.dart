import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';

class GetLoggedInUserUseCase implements UseCase<UserEntity, NoParam> {
  final IAuthRepo authRepository;

  GetLoggedInUserUseCase({required this.authRepository});

  @override
  Future<Either<Failure, UserEntity>> call({required NoParam parameters}) {
    return authRepository.getCurrentUser();
  }
}
