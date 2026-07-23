import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

abstract interface class IAuthLocalDS {
  Future<UserModel> getCurrentUser();
  Future<void> cacheCurrentUser(UserModel user);
  Future<void> clearUser();
}
