import 'package:transient_team_ws/features/auth/domain/entities/auth_request_entity.dart';

class AuthRequestParamModel {
  final String email;
  final String password;

  AuthRequestParamModel({required this.email, required this.password});

  factory AuthRequestParamModel.fromEntity({
    required AuthRequestParamEntity authParam,
  }) {
    return AuthRequestParamModel(
      email: authParam.email,
      password: authParam.password,
    );
  }
}
