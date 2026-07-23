import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

abstract interface class IAuthRemoteDs {
  Future<UserModel> signUp({required String email, required String password});

  Future<UserModel> login({required String email, required String password});

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}
