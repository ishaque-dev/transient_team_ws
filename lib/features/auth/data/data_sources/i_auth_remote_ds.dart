import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

abstract interface class IAuthRemoteDs {
  /// Throws `AccountInactiveFailure` if the account is not approved.
  Future<UserModel> login({required String email, required String password});

  /// The first account in a workspace becomes its admin. Later accounts are
  /// created inactive and this throws `AccountInactiveFailure`.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Returns null if the user cancelled the Google account picker.
  Future<UserModel?> signInWithGoogle();

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Stream<UserModel> watchUser(String userId);

  Future<void> sendPasswordReset(String email);

  Future<void> updateName({required String userId, required String name});

  Future<void> markNotificationsSeen(String userId);
}
