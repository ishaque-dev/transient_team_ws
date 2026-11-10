import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

abstract interface class ITeamRemoteDs {
  Stream<List<UserModel>> watchMembers();

  Future<UserModel> addMember({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> updateRole(String userId, UserRole role);

  Future<void> setActive(String userId, bool isActive);
}
