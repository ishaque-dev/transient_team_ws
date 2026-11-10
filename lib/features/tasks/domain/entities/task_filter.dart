import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

/// Which tasks a user is allowed to stream.
class TaskScope extends Equatable {
  const TaskScope.all() : assigneeId = null;
  const TaskScope.assignedTo(String this.assigneeId);

  final String? assigneeId;

  @override
  List<Object?> get props => [assigneeId];
}

enum TaskQuickFilter {
  all,
  open,
  overdue,
  todo,
  inProgress,
  onHold,
  completed,

  /// Completed tasks an admin has not rated yet.
  toRate;

  String get label => switch (this) {
    TaskQuickFilter.toRate => 'To rate',
    TaskQuickFilter.all => 'All',
    TaskQuickFilter.open => 'Open',
    TaskQuickFilter.overdue => 'Overdue',
    TaskQuickFilter.todo => TaskStatus.todo.label,
    TaskQuickFilter.inProgress => TaskStatus.inProgress.label,
    TaskQuickFilter.onHold => TaskStatus.onHold.label,
    TaskQuickFilter.completed => TaskStatus.completed.label,
  };

  bool matches(TaskEntity task, DateTime now) => switch (this) {
    TaskQuickFilter.all => true,
    TaskQuickFilter.open => task.status.isOpen,
    TaskQuickFilter.overdue => task.isOverdue(now),
    TaskQuickFilter.todo => task.status == TaskStatus.todo,
    TaskQuickFilter.inProgress => task.status == TaskStatus.inProgress,
    TaskQuickFilter.onHold => task.status == TaskStatus.onHold,
    TaskQuickFilter.completed => task.status == TaskStatus.completed,
    TaskQuickFilter.toRate => task.isCompleted && task.rating == null,
  };
}

enum TaskSort {
  dueDate,
  priority,
  recentlyUpdated,
  newest;

  String get label => switch (this) {
    TaskSort.dueDate => 'Due date',
    TaskSort.priority => 'Priority',
    TaskSort.recentlyUpdated => 'Recently updated',
    TaskSort.newest => 'Newest first',
  };

  int compare(TaskEntity a, TaskEntity b) {
    final primary = switch (this) {
      TaskSort.dueDate => a.dueDate.compareTo(b.dueDate),
      TaskSort.priority => b.priority.index.compareTo(a.priority.index),
      TaskSort.recentlyUpdated => b.updatedAt.compareTo(a.updatedAt),
      TaskSort.newest => b.createdAt.compareTo(a.createdAt),
    };
    if (primary != 0) return primary;
    // Stable tie-breakers: earlier due date, then higher priority, then title.
    final due = a.dueDate.compareTo(b.dueDate);
    if (due != 0) return due;
    final priority = b.priority.index.compareTo(a.priority.index);
    if (priority != 0) return priority;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}

class TaskFilterCriteria extends Equatable {
  const TaskFilterCriteria({
    this.query = '',
    this.quickFilter = TaskQuickFilter.all,
    this.priority,
    this.assigneeId,
    this.sort = TaskSort.dueDate,
  });

  /// Value for [assigneeId] that selects tasks without an assignee.
  static const String unassigned = '__unassigned__';

  final String query;
  final TaskQuickFilter quickFilter;
  final TaskPriority? priority;
  final String? assigneeId;
  final TaskSort sort;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      quickFilter != TaskQuickFilter.all ||
      priority != null ||
      assigneeId != null;

  List<TaskEntity> apply(Iterable<TaskEntity> tasks, DateTime now) {
    final needle = query.trim().toLowerCase();
    final result = tasks.where((task) {
      if (!quickFilter.matches(task, now)) return false;
      if (priority != null && task.priority != priority) return false;
      if (assigneeId == unassigned && task.assigneeId != null) return false;
      if (assigneeId != null &&
          assigneeId != unassigned &&
          task.assigneeId != assigneeId) {
        return false;
      }
      if (needle.isEmpty) return true;
      return task.title.toLowerCase().contains(needle) ||
          task.description.toLowerCase().contains(needle) ||
          (task.assigneeName?.toLowerCase().contains(needle) ?? false);
    }).toList()..sort(sort.compare);
    return result;
  }

  TaskFilterCriteria copyWith({
    String? query,
    TaskQuickFilter? quickFilter,
    TaskPriority? Function()? priority,
    String? Function()? assigneeId,
    TaskSort? sort,
  }) {
    return TaskFilterCriteria(
      query: query ?? this.query,
      quickFilter: quickFilter ?? this.quickFilter,
      priority: priority != null ? priority() : this.priority,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [query, quickFilter, priority, assigneeId, sort];
}

/// Tasks due on [day] (by calendar date).
bool isDueOn(TaskEntity task, DateTime day) =>
    calendarDaysBetween(day, task.dueDate) == 0;
