import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounce(duration).switchMap(mapper);

/// Streams the tasks visible to the signed-in user and applies search,
/// filters and sorting on the device.
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({
    required this._watchTasks,
    required this.scope,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const TaskListState()) {
    on<TaskListSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<TaskListQueryChanged>(
      _onQueryChanged,
      transformer: _debounce(const Duration(milliseconds: 200)),
    );
    on<TaskListCriteriaChanged>(_onCriteriaChanged);
  }

  final WatchTasksUseCase _watchTasks;
  final TaskScope scope;
  final DateTime Function() _clock;

  Future<void> _onSubscriptionRequested(
    TaskListSubscriptionRequested event,
    Emitter<TaskListState> emit,
  ) async {
    if (state.tasks.isEmpty) {
      emit(state.copyWith(status: TaskListStatus.loading));
    }
    await emit.forEach(
      _watchTasks(parameters: scope),
      onData: (result) => result.fold(
        (failure) => state.copyWith(
          status: TaskListStatus.failure,
          errorMessage: failure.message,
        ),
        (tasks) => _recompute(
          state.copyWith(status: TaskListStatus.success, tasks: tasks),
        ),
      ),
    );
  }

  void _onQueryChanged(
    TaskListQueryChanged event,
    Emitter<TaskListState> emit,
  ) {
    emit(
      _recompute(
        state.copyWith(criteria: state.criteria.copyWith(query: event.query)),
      ),
    );
  }

  void _onCriteriaChanged(
    TaskListCriteriaChanged event,
    Emitter<TaskListState> emit,
  ) {
    emit(_recompute(state.copyWith(criteria: event.criteria)));
  }

  TaskListState _recompute(TaskListState next) {
    return next.copyWith(
      visibleTasks: next.criteria.apply(next.tasks, _clock()),
    );
  }
}
