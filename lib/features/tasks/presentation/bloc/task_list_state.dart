part of 'task_list_bloc.dart';

enum TaskListStatus { initial, loading, success, failure }

final class TaskListState extends Equatable {
  const TaskListState({
    this.status = TaskListStatus.initial,
    this.tasks = const [],
    this.visibleTasks = const [],
    this.criteria = const TaskFilterCriteria(),
    this.errorMessage,
  });

  final TaskListStatus status;

  /// Everything the user may see, unfiltered (drives dashboards).
  final List<TaskEntity> tasks;

  /// [tasks] after search, filters and sorting (drives the task list).
  final List<TaskEntity> visibleTasks;
  final TaskFilterCriteria criteria;
  final String? errorMessage;

  bool get isLoading =>
      status == TaskListStatus.initial || status == TaskListStatus.loading;

  TaskEntity? taskById(String id) =>
      tasks.where((task) => task.id == id).firstOrNull;

  TaskListState copyWith({
    TaskListStatus? status,
    List<TaskEntity>? tasks,
    List<TaskEntity>? visibleTasks,
    TaskFilterCriteria? criteria,
    String? errorMessage,
  }) {
    return TaskListState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      visibleTasks: visibleTasks ?? this.visibleTasks,
      criteria: criteria ?? this.criteria,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    tasks,
    visibleTasks,
    criteria,
    errorMessage,
  ];
}
