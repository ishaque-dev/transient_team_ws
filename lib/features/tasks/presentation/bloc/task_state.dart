part of 'task_bloc.dart';

enum TaskBlocStatus { initial, loading, success, failure }

final class TaskState extends Equatable {
  final List<TaskEntity> tasks;
  final TaskBlocStatus status;
  final bool hasReachedMax;
  final String? errorMessage;
  final String query;
  final TaskStatus? filterStatus;
  final TaskPriority? filterPriority;

  const TaskState({
    this.tasks = const [],
    this.status = TaskBlocStatus.initial,
    this.hasReachedMax = false,
    this.errorMessage,
    this.query = '',
    this.filterStatus,
    this.filterPriority,
  });

  TaskState copyWith({
    List<TaskEntity>? tasks,
    TaskBlocStatus? status,
    bool? hasReachedMax,
    String? errorMessage,
    String? query,
    TaskStatus? filterStatus,
    TaskPriority? filterPriority,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      query: query ?? this.query,
      filterStatus: filterStatus ?? this.filterStatus,
      filterPriority: filterPriority ?? this.filterPriority,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        status,
        hasReachedMax,
        errorMessage,
        query,
        filterStatus,
        filterPriority,
      ];
}
