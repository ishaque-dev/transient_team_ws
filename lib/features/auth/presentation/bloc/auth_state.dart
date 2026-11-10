part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {}

/// Something went wrong; shown as an error on the sign-in screen.
final class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Informational outcome while signed out (access requested, reset email
/// sent, account deactivated).
final class AuthNotice extends AuthState {
  const AuthNotice(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
