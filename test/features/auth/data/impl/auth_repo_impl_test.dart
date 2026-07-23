import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/impl/auth_repo_impl.dart';
import 'package:transient_team_ws/features/auth/data/models/auth_request_model.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';

class MockAuthRemoteDs extends Mock implements IAuthRemoteDs {}

class MockAuthLocalDs extends Mock implements IAuthLocalDs {}

void main() {
  late AuthRepoImpl repository;
  late MockAuthRemoteDs mockRemoteDs;
  late MockAuthLocalDs mockLocalDs;

  setUp(() {
    mockRemoteDs = MockAuthRemoteDs();
    mockLocalDs = MockAuthLocalDs();
    repository = AuthRepoImpl(
      remoteDataSource: mockRemoteDs,
      localDataSource: mockLocalDs,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = UserModel(id: '1', email: tEmail);
  const tCreds = AuthRequestParamEntity(email: tEmail, password: tPassword);

  group('signUp', () {
    test('should return remote user and cache it when successful', () async {
      // arrange
      when(
        () => mockRemoteDs.signUp(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).thenAnswer((_) async => tUser);
      when(
        () => mockLocalDs.cacheCurrentUser(tUser),
      ).thenAnswer((_) async => {});

      // act
      final result = await repository.signUp(authRequestParams: tCreds);

      // assert
      expect(result, right(tUser));
      verify(
        () => mockRemoteDs.signUp(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).called(1);
      verify(() => mockLocalDs.cacheCurrentUser(tUser)).called(1);
    });

    test('should return failure when remote call fails', () async {
      // arrange
      final exception = Exception('Remote failure');
      when(
        () => mockRemoteDs.signUp(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).thenThrow(exception);

      // act
      final result = await repository.signUp(authRequestParams: tCreds);

      // assert
      expect(result.isLeft(), true);
      verify(
        () => mockRemoteDs.signUp(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).called(1);
      verifyZeroInteractions(mockLocalDs);
    });
  });

  group('login', () {
    test('should return remote user and cache it when successful', () async {
      // arrange
      when(
        () => mockRemoteDs.login(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).thenAnswer((_) async => tUser);
      when(
        () => mockLocalDs.cacheCurrentUser(tUser),
      ).thenAnswer((_) async => {});

      // act
      final result = await repository.login(authRequestParams: tCreds);

      // assert
      expect(result, right(tUser));
      verify(
        () => mockRemoteDs.login(
          authRequestParmModel: AuthRequestParamModel.fromEntity(
            authParam: tCreds,
          ),
        ),
      ).called(1);
      verify(() => mockLocalDs.cacheCurrentUser(tUser)).called(1);
    });
  });

  group('logout', () {
    test('should clear remote and local data source when successful', () async {
      // arrange
      when(() => mockRemoteDs.logout()).thenAnswer((_) async => {});
      when(() => mockLocalDs.clearUser()).thenAnswer((_) async => {});

      // act
      final result = await repository.logout();

      // assert
      expect(result, right(unit));
      verify(() => mockRemoteDs.logout()).called(1);
      verify(() => mockLocalDs.clearUser()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return cached user when available', () async {
      // arrange
      when(() => mockLocalDs.getCurrentUser()).thenAnswer((_) async => tUser);

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, right(tUser));
      verify(() => mockLocalDs.getCurrentUser()).called(1);
      verifyZeroInteractions(mockRemoteDs);
    });

    test('should fetch from remote and cache when no local user', () async {
      // arrange
      when(() => mockLocalDs.getCurrentUser()).thenAnswer((_) async => null);
      when(() => mockRemoteDs.getCurrentUser()).thenAnswer((_) async => tUser);
      when(
        () => mockLocalDs.cacheCurrentUser(tUser),
      ).thenAnswer((_) async => {});

      // act
      final result = await repository.getCurrentUser();

      // assert
      expect(result, right(tUser));
      verify(() => mockLocalDs.getCurrentUser()).called(1);
      verify(() => mockRemoteDs.getCurrentUser()).called(1);
      verify(() => mockLocalDs.cacheCurrentUser(tUser)).called(1);
    });
  });
}
