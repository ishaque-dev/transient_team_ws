import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/repository/i_auth_repo.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/get_logged_in_user_use_case.dart';

class MockAuthRepo extends Mock implements IAuthRepo {}

void main() {
  late GetLoggedInUserUseCase useCase;
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepo();
    useCase = GetLoggedInUserUseCase(authRepository: mockAuthRepo);
  });

  final tNoParam = NoParam();
  const tUser = UserEntity(id: '1', email: 'test@example.com');

  test('should get user from repository', () async {
    // arrange
    when(() => mockAuthRepo.getCurrentUser())
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await useCase(parameters: tNoParam);

    // assert
    expect(result, const Right(tUser));
    verify(() => mockAuthRepo.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });

  test('should return failure from repository when fetching user fails', () async {
    // arrange
    final tFailure = DefaultFailure(message: 'Fetch failed');
    when(() => mockAuthRepo.getCurrentUser())
        .thenAnswer((_) async => Left(tFailure));

    // act
    final result = await useCase(parameters: tNoParam);

    // assert
    expect(result, Left(tFailure));
    verify(() => mockAuthRepo.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepo);
  });
}
