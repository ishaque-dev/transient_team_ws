import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/core/firebase/firestore_writes.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/team/data/data_sources/account_provisioner.dart';
import 'package:transient_team_ws/features/team/data/data_sources/i_team_remote_ds.dart';

class TeamRemoteDsImpl implements ITeamRemoteDs {
  TeamRemoteDsImpl(this._collections, this._provisioner);

  final FirestoreCollections _collections;
  final IAccountProvisioner _provisioner;

  @override
  Stream<List<UserModel>> watchMembers() {
    return _collections.users.snapshots().map((snapshot) {
      final members = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
      members.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return members;
    });
  }

  @override
  Future<UserModel> addMember({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      return await _provisioner.createAccount(
        email: email,
        password: password,
        displayName: name,
        onCreated: (uid) async {
          final member = UserModel(
            id: uid,
            email: email,
            name: name,
            role: role,
            isActive: true,
            createdAt: DateTime.now(),
          );
          await _collections.users.doc(uid).set(member.toNewProfile());
          return member;
        },
      );
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  @override
  Future<void> updateRole(String userId, UserRole role) {
    return _update(userId, {'role': role.name});
  }

  @override
  Future<void> setActive(String userId, bool isActive) {
    return _update(userId, {'isActive': isActive});
  }

  Future<void> _update(String userId, Map<String, dynamic> fields) async {
    try {
      final batch = _collections.batch()
        ..update(_collections.users.doc(userId), {
          ...fields,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      await commitBatch(batch);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }
}
