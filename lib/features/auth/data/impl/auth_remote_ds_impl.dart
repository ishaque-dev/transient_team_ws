import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/google_credential_source.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_remote_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/notifications/data/models/app_notification_model.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

final class AuthRemoteDsImpl implements IAuthRemoteDs {
  AuthRemoteDsImpl(this._auth, this._collections, this._google);

  final FirebaseAuth _auth;
  final FirestoreCollections _collections;
  final IGoogleCredentialSource _google;

  @override
  Future<UserModel> login({required String email, required String password}) {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await _loadOrCreateProfile(_requireUser(credential.user));
      return _ensureActive(profile);
    });
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _requireUser(credential.user);
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {
        // The Firestore profile is the source of truth for names.
      }
      final profile = await _createProfile(user, name: name.trim());
      return _ensureActive(profile, justRequested: true);
    });
  }

  @override
  Future<UserModel?> signInWithGoogle() {
    return _guard(() async {
      final credential = await _google.obtainCredential();
      if (credential == null) return null;
      final result = await _auth.signInWithCredential(credential);
      final user = _requireUser(result.user);
      final existing = await _collections.users.doc(user.uid).get();
      if (existing.exists && existing.data() != null) {
        return _ensureActive(
          UserModel.fromFirestore(existing.data()!, id: existing.id),
        );
      }
      final profile = await _createProfile(user, name: user.displayName ?? '');
      return _ensureActive(profile, justRequested: true);
    });
  }

  @override
  Future<void> logout() {
    return _guard(() async {
      await _auth.signOut();
      // Don't hold the user on screen waiting for Google's SDK.
      unawaited(_google.signOut());
    });
  }

  @override
  Future<UserModel> getCurrentUser() {
    return _guard(() async {
      // Waits for Firebase to restore a persisted session on cold start.
      final user = _auth.currentUser ?? await _auth.authStateChanges().first;
      if (user == null) throw UnauthorizedFailure();
      final profile = await _loadOrCreateProfile(user);
      return _ensureActive(profile);
    });
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    return _collections.users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) throw NotFoundFailure();
      return UserModel.fromFirestore(data, id: snapshot.id);
    });
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> updateName({required String userId, required String name}) {
    return _guard(() async {
      await _collections.users.doc(userId).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      try {
        await _auth.currentUser?.updateDisplayName(name);
      } catch (_) {}
    });
  }

  @override
  Future<void> markNotificationsSeen(String userId) {
    return _guard(
      () => _collections.users.doc(userId).update({
        'notificationsSeenAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<UserModel> _loadOrCreateProfile(User user) async {
    final snapshot = await _collections.users.doc(user.uid).get();
    final data = snapshot.data();
    if (snapshot.exists && data != null) {
      return UserModel.fromFirestore(data, id: snapshot.id);
    }
    // The Firebase account exists without a profile, e.g. a sign-up that was
    // interrupted. Register it the same way a fresh sign-up would be.
    return _createProfile(user, name: user.displayName ?? '');
  }

  /// The first profile in a workspace becomes the admin, written in the same
  /// batch as the workspace marker so security rules can enforce "only once".
  /// Everyone after that starts as an inactive employee awaiting approval.
  Future<UserModel> _createProfile(User user, {required String name}) async {
    final email = user.email ?? '';
    final workspace = await _collections.workspace.get();
    if (!workspace.exists) {
      final admin = UserModel(
        id: user.uid,
        email: email,
        name: name,
        role: UserRole.admin,
        isActive: true,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      try {
        final batch = _collections.batch()
          ..set(_collections.users.doc(user.uid), admin.toNewProfile())
          ..set(_collections.workspace, {
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        await batch.commit();
        return admin;
      } on FirebaseException catch (error) {
        // Another account claimed the workspace first; continue as employee.
        if (error.code != 'permission-denied') rethrow;
      }
    }

    final employee = UserModel(
      id: user.uid,
      email: email,
      name: name,
      role: UserRole.employee,
      isActive: false,
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    // Profile and the admins' "access requested" notification are written
    // together, so a request is never left unannounced.
    final displayName = name.trim().isEmpty ? email : name.trim();
    final request = _collections.notifications.doc();
    final batch = _collections.batch()
      ..set(_collections.users.doc(user.uid), employee.toNewProfile())
      ..set(
        request,
        AppNotificationModel.toFirestore(
          AppNotificationEntity(
            id: request.id,
            recipient: AppNotificationEntity.adminsAudience,
            type: NotificationType.accessRequested,
            taskId: '',
            taskTitle: '',
            actorId: user.uid,
            actorName: displayName,
            message: 'requested access as an employee. Review it in Team.',
            createdAt: DateTime.now(),
          ),
        ),
      );
    await batch.commit();
    return employee;
  }

  Future<UserModel> _ensureActive(
    UserModel profile, {
    bool justRequested = false,
  }) async {
    if (profile.isActive) return profile;
    await _auth.signOut();
    unawaited(_google.signOut());
    throw AccountInactiveFailure(
      message: justRequested ? AppErrorMessages.accessRequested : null,
    );
  }

  User _requireUser(User? user) {
    if (user == null) throw UnauthorizedFailure();
    return user;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseAuthException catch (error) {
      throw FirebaseAuthFailureMapper.fromCode(error.code, cause: error);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }
}
