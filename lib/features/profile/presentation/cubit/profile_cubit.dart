import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';
import 'package:transient_team_ws/core/utils/action_feedback.dart';
import 'package:transient_team_ws/features/auth/domain/entities/auth_params.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/auth_use_cases.dart';

class ProfileCubit extends Cubit<ActionFeedback?> {
  ProfileCubit({
    required this.user,
    required this._updateName,
    required this._sendPasswordReset,
  }) : super(null);

  final UserEntity user;
  final UpdateDisplayNameUseCase _updateName;
  final SendPasswordResetUseCase _sendPasswordReset;
  int _serial = 0;

  Future<void> updateName(String name) async {
    final result = await _updateName(
      parameters: UpdateNameParams(userId: user.id, name: name),
    );
    result.fold(
      (failure) => _emit(failure.message, isError: true),
      (_) => _emit(AppStrings.nameUpdated),
    );
  }

  Future<void> sendPasswordReset() async {
    final result = await _sendPasswordReset(parameters: user.email);
    result.fold(
      (failure) => _emit(failure.message, isError: true),
      (_) => _emit(AppStrings.resetEmailSent),
    );
  }

  void _emit(String message, {bool isError = false}) {
    if (!isClosed) {
      emit(ActionFeedback(message, isError: isError, serial: ++_serial));
    }
  }
}
