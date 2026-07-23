import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/logout_use_case.dart';

class MockAuthRepo extends Mock implements IAuthRepo {}

void main() {
  late LogoutUseCase useCase;
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepo();
    useCase = LogoutUseCase(authRepository: mockAuthRepo);
  });

  final tNoParam = NoParam();

  test('should call repository logout and return success', () async {
    // arrange
    when(() => mockAuthRepo.logout())
        .thenAnswer((_) async => const Right(unit));

    // act
    final result = await useCase(parameters: tNoParam);

    // assert
    expect(result, const Right(unit));
    verify(() => mockAuthRepo.logout()).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });

  test('should return failure from repository when logout fails', () async {
    // arrange
    final tFailure = DefaultFailure(message: 'Logout failed');
    when(() => mockAuthRepo.logout())
        .thenAnswer((_) async => Left(tFailure));

    // act
    final result = await useCase(parameters: tNoParam);

    // assert
    expect(result, Left(tFailure));
    verify(() => mockAuthRepo.logout()).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });
}
