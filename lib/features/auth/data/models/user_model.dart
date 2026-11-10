import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';

final class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.employee,
    this.isActive = true,
    this.photoUrl,
    this.createdAt,
    this.notificationsSeenAt,
  });

  final String id;
  final String email;
  final String name;
  final UserRole role;
  final bool isActive;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? notificationsSeenAt;

  factory UserModel.fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return UserModel(
      id: id,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      role: UserRole.fromName(data['role'] as String?),
      isActive: (data['isActive'] as bool?) ?? false,
      photoUrl: data['photoUrl'] as String?,
      createdAt: parseDateTime(data['createdAt']),
      notificationsSeenAt: parseDateTime(data['notificationsSeenAt']),
    );
  }

  /// Fields written when a profile is first created.
  Map<String, dynamic> toNewProfile() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'isActive': isActive,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Local cache format (SharedPreferences).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: (json['name'] as String?) ?? '',
      role: UserRole.fromName(json['role'] as String?),
      isActive: (json['isActive'] as bool?) ?? true,
      photoUrl: json['photoUrl'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      notificationsSeenAt: parseDateTime(json['notificationsSeenAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'isActive': isActive,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'notificationsSeenAt': notificationsSeenAt?.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      isActive: entity.isActive,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      notificationsSeenAt: entity.notificationsSeenAt,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      role: role,
      isActive: isActive,
      photoUrl: photoUrl,
      createdAt: createdAt,
      notificationsSeenAt: notificationsSeenAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    isActive,
    photoUrl,
    createdAt,
    notificationsSeenAt,
  ];
}
