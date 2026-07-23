import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/get_logged_in_user_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/login_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:transient_team_ws/features/auth/presentation/bloc/auth_bloc.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetLoggedInUserUseCase extends Mock implements GetLoggedInUserUseCase {}

class FakeAuthRequestParamEntity extends Fake implements AuthRequestParamEntity {}

class FakeNoParam extends Fake implements NoParam {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetLoggedInUserUseCase mockGetLoggedInUserUseCase;

  setUpAll(() {
    registerFallbackValue(FakeAuthRequestParamEntity());
    registerFallbackValue(FakeNoParam());
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetLoggedInUserUseCase = MockGetLoggedInUserUseCase();
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      signUpUseCase: mockSignUpUseCase,
      logoutUseCase: mockLogoutUseCase,
      getLoggedInUserUseCase: mockGetLoggedInUserUseCase,
    );
  });

  const tUser = UserEntity(id: '1', email: 'test@example.com');
  const tEmail = 'test@example.com';
  const tPassword = 'password123';

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, AuthInitial());
  });

  group('AuthCheckStatus', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when user is logged in',
      build: () {
        when(() => mockGetLoggedInUserUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [
        AuthLoading(),
        const Authenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Unauthenticated] when user is not logged in',
      build: () {
        when(() => mockGetLoggedInUserUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Left(DefaultFailure()));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when login is successful',
      build: () {
        when(() => mockLoginUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const Authenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthFailure] when login fails',
      build: () {
        when(() => mockLoginUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Left(DefaultFailure(message: 'Login failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthFailure('Login failed'),
      ],
    );
  });

  group('AuthSignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Authenticated] when signup is successful',
      build: () {
        when(() => mockSignUpUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const Authenticated(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthFailure] when signup fails',
      build: () {
        when(() => mockSignUpUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Left(DefaultFailure(message: 'SignUp failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthSignUpRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthFailure('SignUp failed'),
      ],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, Unauthenticated] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => const Right(unit));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        AuthLoading(),
        Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthFailure] when logout fails',
      build: () {
        when(() => mockLogoutUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Left(DefaultFailure(message: 'Logout failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [
        AuthLoading(),
        const AuthFailure('Logout failed'),
      ],
    );
  });
}
