import 'package:firebase_auth/firebase_auth.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';

final class AuthRemoteDsImpl implements IAuthRemoteDs {
  AuthRemoteDsImpl(this._firebaseAuth);
  final FirebaseAuth _firebaseAuth;

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toUserModel(credential.user);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailureMapper.fromCode(error.code, cause: error);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toUserModel(credential.user);
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailureMapper.fromCode(error.code, cause: error);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailureMapper.fromCode(error.code, cause: error);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      return _toUserModel(_firebaseAuth.currentUser);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  UserModel _toUserModel(User? user) {
    if (user == null) {
      throw UnauthorizedFailure();
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw AuthenticationFailure(
        message: 'The signed-in account does not have an email address.',
      );
    }

    return UserModel(id: user.uid, email: email);
  }
}
