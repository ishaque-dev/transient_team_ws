import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_tasks_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/update_task_use_case.dart';

part 'task_event.dart';
part 'task_state.dart';

const _tasksLimit = 10;
const _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;

  TaskBloc({
    required this._getTasksUseCase,
    required this._createTaskUseCase,
    required this._updateTaskUseCase,
    required this._deleteTaskUseCase,
  })  : super(const TaskState()) {
    on<FetchTasksRequested>(_onFetchTasksRequested);
    on<LoadMoreTasksRequested>(
      _onLoadMoreTasksRequested,
      transformer: throttleDroppable(_throttleDuration),
    );
    on<TaskSearchChanged>(_onTaskSearchChanged);
    on<TaskStatusFilterChanged>(_onTaskStatusFilterChanged);
    on<TaskPriorityFilterChanged>(_onTaskPriorityFilterChanged);
    on<CreateTaskRequested>(_onCreateTaskRequested);
    on<UpdateTaskRequested>(_onUpdateTaskRequested);
    on<DeleteTaskRequested>(_onDeleteTaskRequested);
  }

  Future<void> _onFetchTasksRequested(
    FetchTasksRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskBlocStatus.loading));

    final result = await _getTasksUseCase(
      parameters: GetTasksParams(
        offset: 0,
        limit: _tasksLimit,
        query: state.query,
        status: state.filterStatus,
        priority: state.filterPriority,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (tasks) => emit(state.copyWith(
        status: TaskBlocStatus.success,
        tasks: tasks,
        hasReachedMax: tasks.length < _tasksLimit,
      )),
    );
  }

  Future<void> _onLoadMoreTasksRequested(
    LoadMoreTasksRequested event,
    Emitter<TaskState> emit,
  ) async {
    if (state.hasReachedMax) return;

    final result = await _getTasksUseCase(
      parameters: GetTasksParams(
        offset: state.tasks.length,
        limit: _tasksLimit,
        query: state.query,
        status: state.filterStatus,
        priority: state.filterPriority,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (tasks) {
        emit(tasks.isEmpty
            ? state.copyWith(hasReachedMax: true)
            : state.copyWith(
                status: TaskBlocStatus.success,
                tasks: List.of(state.tasks)..addAll(tasks),
                hasReachedMax: tasks.length < _tasksLimit,
              ));
      },
    );
  }

  Future<void> _onTaskSearchChanged(
    TaskSearchChanged event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    add(const FetchTasksRequested());
  }

  Future<void> _onTaskStatusFilterChanged(
    TaskStatusFilterChanged event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(filterStatus: () => event.status));
    add(const FetchTasksRequested());
  }

  Future<void> _onTaskPriorityFilterChanged(
    TaskPriorityFilterChanged event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(filterPriority: () => event.priority));
    add(const FetchTasksRequested());
  }

  Future<void> _onCreateTaskRequested(
    CreateTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _createTaskUseCase(parameters: event.task);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (newTask) {
        final updatedTasks = List.of(state.tasks)..insert(0, newTask);
        emit(state.copyWith(
          status: TaskBlocStatus.success,
          tasks: updatedTasks,
        ));
      },
    );
  }

  Future<void> _onUpdateTaskRequested(
    UpdateTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _updateTaskUseCase(parameters: event.task);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (updatedTask) {
        final updatedTasks = state.tasks.map((task) {
          return task.id == updatedTask.id ? updatedTask : task;
        }).toList();

        emit(state.copyWith(
          status: TaskBlocStatus.success,
          tasks: updatedTasks,
        ));
      },
    );
  }

  Future<void> _onDeleteTaskRequested(
    DeleteTaskRequested event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _deleteTaskUseCase(parameters: event.taskId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TaskBlocStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedTasks = state.tasks
            .where((task) => task.id != event.taskId)
            .toList();

        emit(state.copyWith(
          status: TaskBlocStatus.success,
          tasks: updatedTasks,
        ));
      },
    );
  }
}
