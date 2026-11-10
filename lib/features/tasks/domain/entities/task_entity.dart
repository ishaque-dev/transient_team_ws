import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
    TaskPriority.urgent => 'Urgent',
  };

  static TaskPriority fromName(String? value) =>
      TaskPriority.values.asNameMap()[value] ?? TaskPriority.medium;
}

enum TaskStatus {
  todo,
  inProgress,
  onHold,
  completed;

  String get label => switch (this) {
    TaskStatus.todo => 'To do',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.onHold => 'On hold',
    TaskStatus.completed => 'Completed',
  };

  bool get isOpen => this != TaskStatus.completed;

  /// Accepts the legacy `pending` value from earlier builds.
  static TaskStatus fromName(String? value) {
    if (value == 'pending') return TaskStatus.todo;
    return TaskStatus.values.asNameMap()[value] ?? TaskStatus.todo;
  }
}

/// An admin's review of a completed task.
class TaskRating extends Equatable {
  const TaskRating({
    required this.quality,
    required this.timeliness,
    required this.ratedById,
    required this.ratedByName,
    required this.ratedAt,
    this.note,
  });

  /// 1-5: how good the delivered work was.
  final int quality;

  /// 1-5: how well the deadline was met.
  final int timeliness;
  final String? note;
  final String ratedById;
  final String ratedByName;
  final DateTime ratedAt;

  double get overall => (quality + timeliness) / 2;

  @override
  List<Object?> get props => [
    quality,
    timeliness,
    note,
    ratedById,
    ratedByName,
    ratedAt,
  ];
}

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.assigneeName,
    this.completedAt,
    this.rating,
  });

  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;

  /// Calendar day the task is due; the time component is ignored.
  final DateTime dueDate;
  final String? assigneeId;
  final String? assigneeName;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final TaskRating? rating;

  bool get isCompleted => status == TaskStatus.completed;

  bool isOverdue(DateTime now) =>
      !isCompleted && calendarDaysBetween(now, dueDate) < 0;

  /// Days between the due date and completion; 0 or negative means on time.
  /// Null while the task is still open.
  int? get daysLate {
    final done = completedAt;
    if (!isCompleted || done == null) return null;
    return calendarDaysBetween(dueDate, done);
  }

  bool? get completedOnTime {
    final late = daysLate;
    return late == null ? null : late <= 0;
  }

  /// Timeliness score an admin would most likely give, from how late the
  /// task was finished.
  int get suggestedTimeliness {
    final late = daysLate ?? 0;
    if (late <= 0) return 5;
    if (late == 1) return 4;
    if (late <= 3) return 3;
    if (late <= 7) return 2;
    return 1;
  }

  TaskEntity copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? Function()? assigneeId,
    String? Function()? assigneeName,
    DateTime? updatedAt,
    DateTime? Function()? completedAt,
    TaskRating? Function()? rating,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      assigneeName: assigneeName != null ? assigneeName() : this.assigneeName,
      createdById: createdById,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      rating: rating != null ? rating() : this.rating,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    status,
    dueDate,
    assigneeId,
    assigneeName,
    createdById,
    createdByName,
    createdAt,
    updatedAt,
    completedAt,
    rating,
  ];
}
