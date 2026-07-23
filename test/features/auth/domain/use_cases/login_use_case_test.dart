import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/login_use_case.dart';

class MockAuthRepo extends Mock implements IAuthRepo {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepo();
    useCase = LoginUseCase(authRepository: mockAuthRepo);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tAuthParams = AuthRequestParamEntity(email: tEmail, password: tPassword);
  const tUser = UserEntity(id: '1', email: tEmail);

  test('should get user from the repository when login is successful', () async {
    // arrange
    when(() => mockAuthRepo.login(authRequestParams: tAuthParams))
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await useCase(parameters: tAuthParams);

    // assert
    expect(result, const Right(tUser));
    verify(() => mockAuthRepo.login(authRequestParams: tAuthParams)).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });

  test('should return failure from the repository when login fails', () async {
    // arrange
    final tFailure = DefaultFailure(message: 'Login failed');
    when(() => mockAuthRepo.login(authRequestParams: tAuthParams))
        .thenAnswer((_) async => Left(tFailure));

    // act
    final result = await useCase(parameters: tAuthParams);

    // assert
    expect(result, Left(tFailure));
    verify(() => mockAuthRepo.login(authRequestParams: tAuthParams)).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });
}
