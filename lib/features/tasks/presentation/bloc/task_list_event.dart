part of 'task_list_bloc.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

final class TaskListSubscriptionRequested extends TaskListEvent {
  const TaskListSubscriptionRequested();
}

/// Debounced free-text search.
final class TaskListQueryChanged extends TaskListEvent {
  const TaskListQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Replaces the filters (status chip, priority, assignee, sort).
final class TaskListCriteriaChanged extends TaskListEvent {
  const TaskListCriteriaChanged(this.criteria);

  final TaskFilterCriteria criteria;

  @override
  List<Object?> get props => [criteria];
}
