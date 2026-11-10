import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/team/domain/repository/i_team_repo.dart';

class WatchTeamMembersUseCase
    implements UseCaseStream<List<UserEntity>, NoParam> {
  WatchTeamMembersUseCase(this.repository);
  final ITeamRepo repository;

  @override
  Stream<Either<Failure, List<UserEntity>>> call({
    required NoParam parameters,
  }) {
    return repository.watchMembers();
  }
}

class AddMemberParams extends Equatable {
  const AddMemberParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.actor,
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final UserEntity actor;

  @override
  List<Object?> get props => [name, email, password, role, actor];
}

class AddTeamMemberUseCase implements UseCase<UserEntity, AddMemberParams> {
  AddTeamMemberUseCase(this.repository);
  final ITeamRepo repository;

  @override
  Future<Either<Failure, UserEntity>> call({
    required AddMemberParams parameters,
  }) async {
    final p = parameters;
    if (!p.actor.isAdmin) {
      return Left(ForbiddenFailure(message: 'Only admins can add members.'));
    }
    if (p.name.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a name.'));
    }
    if (!p.email.contains('@')) {
      return Left(ValidationFailure(message: 'Enter a valid email.'));
    }
    if (p.password.length < 6) {
      return Left(
        ValidationFailure(message: 'Password must be at least 6 characters.'),
      );
    }
    return repository.addMember(
      name: p.name.trim(),
      email: p.email.trim(),
      password: p.password,
      role: p.role,
    );
  }
}

class MemberChangeParams<T> extends Equatable {
  const MemberChangeParams({
    required this.member,
    required this.value,
    required this.actor,
  });

  final UserEntity member;
  final T value;
  final UserEntity actor;

  @override
  List<Object?> get props => [member, value, actor];
}

Failure? _guardMemberChange(UserEntity actor, UserEntity member) {
  if (!actor.isAdmin) {
    return ForbiddenFailure(message: 'Only admins can manage the team.');
  }
  if (actor.id == member.id) {
    // Keeps at least one admin in the workspace at all times.
    return ValidationFailure(
      message: "You can't change your own role or access.",
    );
  }
  return null;
}

class UpdateMemberRoleUseCase
    implements UseCase<Unit, MemberChangeParams<UserRole>> {
  UpdateMemberRoleUseCase(this.repository);
  final ITeamRepo repository;

  @override
  Future<Either<Failure, Unit>> call({
    required MemberChangeParams<UserRole> parameters,
  }) async {
    final blocked = _guardMemberChange(parameters.actor, parameters.member);
    if (blocked != null) return Left(blocked);
    return repository.updateRole(parameters.member.id, parameters.value);
  }
}

class SetMemberActiveUseCase
    implements UseCase<Unit, MemberChangeParams<bool>> {
  SetMemberActiveUseCase(this.repository);
  final ITeamRepo repository;

  @override
  Future<Either<Failure, Unit>> call({
    required MemberChangeParams<bool> parameters,
  }) async {
    final blocked = _guardMemberChange(parameters.actor, parameters.member);
    if (blocked != null) return Left(blocked);
    return repository.setActive(parameters.member.id, parameters.value);
  }
}
