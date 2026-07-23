import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

final class UserModel extends UserEntity {
  const UserModel({required super.id, required super.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'] as String, email: json['email'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email};
  }
}
