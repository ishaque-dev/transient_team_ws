import 'package:transient_team_ws/features/auth/data/models/auth_request_model.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

abstract interface class IAuthRemoteDs {
  Future<UserModel> signUp({
    required AuthRequestParamModel authRequestParmModel,
  });

  Future<UserModel> login({
    required AuthRequestParamModel authRequestParmModel,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}
