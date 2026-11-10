import 'package:equatable/equatable.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpParams extends Equatable {
  const SignUpParams({
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

class UpdateNameParams extends Equatable {
  const UpdateNameParams({required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  List<Object?> get props => [userId, name];
}
