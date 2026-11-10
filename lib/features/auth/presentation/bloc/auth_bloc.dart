import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_params.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/auth_use_cases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
    required LogoutUseCase logoutUseCase,
    required GetLoggedInUserUseCase getLoggedInUserUseCase,
    required WatchUserProfileUseCase watchUserProfileUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
  }) : _login = loginUseCase,
       _signUp = signUpUseCase,
       _googleSignIn = googleSignInUseCase,
       _logout = logoutUseCase,
       _getLoggedInUser = getLoggedInUserUseCase,
       _watchUserProfile = watchUserProfileUseCase,
       _sendPasswordReset = sendPasswordResetUseCase,
       super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLogin);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthProfileChanged>(_onProfileChanged);
  }

  final LoginUseCase _login;
  final SignUpUseCase _signUp;
  final GoogleSignInUseCase _googleSignIn;
  final LogoutUseCase _logout;
  final GetLoggedInUserUseCase _getLoggedInUser;
  final WatchUserProfileUseCase _watchUserProfile;
  final SendPasswordResetUseCase _sendPasswordReset;

  StreamSubscription<Either<Failure, UserEntity>>? _profileSubscription;

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _getLoggedInUser(parameters: NoParam());
    result.fold((failure) {
      emit(
        failure is AccountInactiveFailure
            ? AuthNotice(failure.message)
            : Unauthenticated(),
      );
    }, (user) => _authenticated(user, emit));
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _login(
      parameters: LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (user) => _authenticated(user, emit),
    );
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _signUp(
      parameters: SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => _emitFailure(failure, emit),
      (user) => _authenticated(user, emit),
    );
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _googleSignIn(parameters: NoParam());
    result.fold((failure) => _emitFailure(failure, emit), (user) {
      if (user == null) {
        emit(Unauthenticated()); // Picker dismissed.
      } else {
        _authenticated(user, emit);
      }
    });
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _stopWatchingProfile();
    emit(AuthLoading());
    // Always land on the sign-in screen, even if sign-out is slow or fails.
    await _logout(
      parameters: NoParam(),
    ).timeout(const Duration(seconds: 5), onTimeout: () => const Right(unit));
    emit(Unauthenticated());
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _sendPasswordReset(parameters: event.email);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthNotice(AppStrings.resetEmailSent)),
    );
  }

  Future<void> _onProfileChanged(
    AuthProfileChanged event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is! Authenticated) return;

    final failure = event.result.getLeft().toNullable();
    final user = event.result.getRight().toNullable();
    if (failure is NotFoundFailure) {
      await _forceSignOut(emit, AppStrings.sessionEnded);
    } else if (user != null && !user.isActive) {
      await _forceSignOut(emit, AppStrings.accountDeactivated);
    } else if (user != null && user != current.user) {
      emit(Authenticated(user));
    }
    // Other failures (e.g. offline) keep the current session.
  }

  void _authenticated(UserEntity user, Emitter<AuthState> emit) {
    emit(Authenticated(user));
    _profileSubscription?.cancel();
    _profileSubscription = _watchUserProfile(
      parameters: user.id,
    ).listen((result) => add(AuthProfileChanged(result)));
  }

  void _emitFailure(Failure failure, Emitter<AuthState> emit) {
    emit(
      failure is AccountInactiveFailure
          ? AuthNotice(failure.message)
          : AuthFailure(failure.message),
    );
  }

  Future<void> _forceSignOut(Emitter<AuthState> emit, String message) async {
    _stopWatchingProfile();
    await _logout(parameters: NoParam());
    emit(AuthNotice(message));
  }

  /// Not awaited on purpose: the session must end even if the underlying
  /// listener is slow to shut down.
  void _stopWatchingProfile() {
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
  }

  @override
  Future<void> close() {
    _stopWatchingProfile();
    return super.close();
  }
}
