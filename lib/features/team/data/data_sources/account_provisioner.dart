import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';

/// Creates Firebase Auth accounts for other people without signing the
/// current admin out.
abstract interface class IAccountProvisioner {
  /// Creates the account, then runs [onCreated] with its uid. If [onCreated]
  /// throws, the new account is deleted again so a retry can reuse the email.
  Future<T> createAccount<T>({
    required String email,
    required String password,
    required String displayName,
    required Future<T> Function(String uid) onCreated,
  });
}

/// Uses a secondary [FirebaseApp], whose auth session is separate from the
/// signed-in admin's, and signs that session out when done.
final class FirebaseAccountProvisioner implements IAccountProvisioner {
  FirebaseAccountProvisioner(this._options);

  final FirebaseOptions _options;
  static const _appName = 'coopiq-provisioning';

  Future<FirebaseAuth> _secondaryAuth() async {
    final existing = Firebase.apps.where((app) => app.name == _appName);
    final app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(name: _appName, options: _options);
    return FirebaseAuth.instanceFor(app: app);
  }

  @override
  Future<T> createAccount<T>({
    required String email,
    required String password,
    required String displayName,
    required Future<T> Function(String uid) onCreated,
  }) async {
    final auth = await _secondaryAuth();
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthenticationFailure();
      try {
        await user.updateDisplayName(displayName);
      } catch (_) {}
      try {
        return await onCreated(user.uid);
      } catch (_) {
        try {
          await user.delete();
        } catch (_) {}
        rethrow;
      }
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailureMapper.fromCode(error.code, cause: error);
    } finally {
      await auth.signOut();
    }
  }
}
