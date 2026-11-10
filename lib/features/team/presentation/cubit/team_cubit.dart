import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/core/utils/action_feedback.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/auth_use_cases.dart';
import 'package:transient_team_ws/features/team/domain/use_cases/team_use_cases.dart';

class TeamState extends Equatable {
  const TeamState({
    this.isLoading = true,
    this.members = const [],
    this.errorMessage,
    this.feedback,
  });

  final bool isLoading;
  final List<UserEntity> members;
  final String? errorMessage;
  final ActionFeedback? feedback;

  List<UserEntity> get activeMembers =>
      members.where((member) => member.isActive).toList();

  /// Active employees: the people tasks are assigned to and the only
  /// accounts admins manage in the app.
  List<UserEntity> get employees => activeMembers
      .where((member) => member.role == UserRole.employee)
      .toList();

  /// People a task can be assigned to.
  List<UserEntity> get assignable => employees;

  /// Employees waiting for approval or deactivated.
  List<UserEntity> get inactiveEmployees => members
      .where((member) => !member.isActive && member.role == UserRole.employee)
      .toList();

  UserEntity? byId(String? id) =>
      id == null ? null : members.where((m) => m.id == id).firstOrNull;

  TeamState copyWith({
    bool? isLoading,
    List<UserEntity>? members,
    String? errorMessage,
    ActionFeedback? feedback,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      errorMessage: errorMessage,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  List<Object?> get props => [isLoading, members, errorMessage, feedback];
}

class TeamCubit extends Cubit<TeamState> {
  TeamCubit({
    required this.actor,
    required this._watchMembers,
    required this._addMember,
    required this._updateRole,
    required this._setActive,
    required this._sendPasswordReset,
  }) : super(const TeamState());

  final UserEntity actor;
  final WatchTeamMembersUseCase _watchMembers;
  final AddTeamMemberUseCase _addMember;
  final UpdateMemberRoleUseCase _updateRole;
  final SetMemberActiveUseCase _setActive;
  final SendPasswordResetUseCase _sendPasswordReset;

  StreamSubscription<Either<Failure, List<UserEntity>>>? _subscription;
  int _serial = 0;

  void start() {
    _subscription?.cancel();
    _subscription = _watchMembers(parameters: NoParam()).listen((result) {
      result.fold(
        (failure) => emit(
          state.copyWith(isLoading: false, errorMessage: failure.message),
        ),
        (members) => emit(state.copyWith(isLoading: false, members: members)),
      );
    });
  }

  Future<bool> addMember({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    required bool sendPasswordSetupEmail,
  }) async {
    final result = await _addMember(
      parameters: AddMemberParams(
        name: name,
        email: email,
        password: password,
        role: role,
        actor: actor,
      ),
    );
    if (result.isLeft()) {
      _feedback(result.getLeft().toNullable()!.message, isError: true);
      return false;
    }

    var message = '$name was added to the team';
    if (sendPasswordSetupEmail) {
      final reset = await _sendPasswordReset(parameters: email);
      message = reset.isRight()
          ? '$message. A password setup email is on its way.'
          : '$message, but the setup email could not be sent.';
    }
    _feedback(message);
    return true;
  }

  Future<void> changeRole(UserEntity member, UserRole role) async {
    final result = await _updateRole(
      parameters: MemberChangeParams(member: member, value: role, actor: actor),
    );
    result.fold(
      (failure) => _feedback(failure.message, isError: true),
      (_) =>
          _feedback('${member.displayName} is now ${role.label.toLowerCase()}'),
    );
  }

  Future<void> setActive(UserEntity member, bool isActive) async {
    final result = await _setActive(
      parameters: MemberChangeParams(
        member: member,
        value: isActive,
        actor: actor,
      ),
    );
    result.fold(
      (failure) => _feedback(failure.message, isError: true),
      (_) => _feedback(
        isActive
            ? '${member.displayName} can now sign in'
            : '${member.displayName} was deactivated',
      ),
    );
  }

  void _feedback(String message, {bool isError = false}) {
    if (isClosed) return;
    emit(
      state.copyWith(
        feedback: ActionFeedback(message, isError: isError, serial: ++_serial),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
