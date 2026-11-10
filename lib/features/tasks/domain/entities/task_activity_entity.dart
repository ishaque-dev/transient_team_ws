import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

enum TaskActivityType {
  created,
  comment,
  statusChanged,
  assigned,
  edited,
  rated;

  static TaskActivityType fromName(String? value) =>
      TaskActivityType.values.asNameMap()[value] ?? TaskActivityType.edited;
}

/// One entry in a task's audit trail.
class TaskActivityEntity extends Equatable {
  const TaskActivityEntity({
    required this.id,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.toStatus,
  });

  final String id;
  final TaskActivityType type;
  final String authorId;
  final String authorName;

  /// For comments, the comment text. Otherwise a sentence fragment that
  /// follows the author's name, e.g. `changed the status to Completed`.
  final String message;
  final DateTime createdAt;
  final TaskStatus? toStatus;

  @override
  List<Object?> get props => [
    id,
    type,
    authorId,
    authorName,
    message,
    createdAt,
    toStatus,
  ];
}
