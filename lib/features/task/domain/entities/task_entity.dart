import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/features/task/domain/entities/task_enum.dart';

class TaskEntity extends Equatable {
  final String? id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final TaskStatus status;
  final String? assignedUserId;

  const TaskEntity({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    this.assignedUserId,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    priority,
    dueDate,
    status,
    assignedUserId,
  ];
}
