import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

final class AuthLocalDsImpl implements IAuthLocalDs {
  AuthLocalDsImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> cacheCurrentUser(UserModel user) async {
    try {
      final didSave = await _preferences.setString(
        AppStrings.sharedPrefUserKey,
        jsonEncode(user.toJson()),
      );
      if (!didSave) {
        throw CacheWriteFailure();
      }
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await _preferences.remove(AppStrings.sharedPrefUserKey);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final value = _preferences.getString(AppStrings.sharedPrefUserKey);
      if (value == null) {
        return null;
      }

      final json = jsonDecode(value) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }
}
