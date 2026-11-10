import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  employee;

  String get label => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.employee => 'Employee',
  };

  /// Unknown or legacy values (e.g. `member`) fall back to [employee].
  static UserRole fromName(String? value) =>
      value == UserRole.admin.name ? UserRole.admin : UserRole.employee;
}

class UserEntity extends Equatable {
  const UserEntity({
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

  /// Notifications created after this moment count as unread.
  final DateTime? notificationsSeenAt;

  bool get isAdmin => role == UserRole.admin;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return email.contains('@') ? email.split('@').first : email;
  }

  String get firstName => displayName.split(' ').first;

  UserEntity copyWith({
    String? name,
    UserRole? role,
    bool? isActive,
    String? photoUrl,
    DateTime? notificationsSeenAt,
  }) {
    return UserEntity(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      notificationsSeenAt: notificationsSeenAt ?? this.notificationsSeenAt,
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
