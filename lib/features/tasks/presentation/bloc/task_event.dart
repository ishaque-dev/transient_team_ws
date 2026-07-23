part of 'task_bloc.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

final class FetchTasksRequested extends TaskEvent {
  const FetchTasksRequested();
}

final class LoadMoreTasksRequested extends TaskEvent {
  const LoadMoreTasksRequested();
}

final class TaskSearchChanged extends TaskEvent {
  final String query;
  const TaskSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

final class TaskStatusFilterChanged extends TaskEvent {
  final TaskStatus? status;
  const TaskStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

final class TaskPriorityFilterChanged extends TaskEvent {
  final TaskPriority? priority;
  const TaskPriorityFilterChanged(this.priority);

  @override
  List<Object?> get props => [priority];
}

final class CreateTaskRequested extends TaskEvent {
  final TaskEntity task;
  const CreateTaskRequested(this.task);

  @override
  List<Object?> get props => [task];
}

final class UpdateTaskRequested extends TaskEvent {
  final TaskEntity task;
  const UpdateTaskRequested(this.task);

  @override
  List<Object?> get props => [task];
}

final class DeleteTaskRequested extends TaskEvent {
  final String taskId;
  const DeleteTaskRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}
