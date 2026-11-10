part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckStatus extends AuthEvent {}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

final class AuthGoogleSignInRequested extends AuthEvent {}

final class AuthLogoutRequested extends AuthEvent {}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Emitted internally whenever the signed-in user's profile document changes.
final class AuthProfileChanged extends AuthEvent {
  const AuthProfileChanged(this.result);

  final Either<Failure, UserEntity> result;

  @override
  List<Object?> get props => [result];
}
