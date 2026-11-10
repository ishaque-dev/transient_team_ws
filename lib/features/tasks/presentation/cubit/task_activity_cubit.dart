import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';

class TaskActivityState extends Equatable {
  const TaskActivityState({
    this.isLoading = true,
    this.items = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<TaskActivityEntity> items;
  final String? errorMessage;

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class TaskActivityCubit extends Cubit<TaskActivityState> {
  TaskActivityCubit(this._watchActivity) : super(const TaskActivityState());

  final WatchTaskActivityUseCase _watchActivity;
  StreamSubscription<dynamic>? _subscription;

  void watch(String taskId) {
    _subscription?.cancel();
    _subscription = _watchActivity(parameters: taskId).listen((result) {
      result.fold(
        (failure) => emit(
          TaskActivityState(
            isLoading: false,
            items: state.items,
            errorMessage: failure.message,
          ),
        ),
        (items) => emit(TaskActivityState(isLoading: false, items: items)),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
