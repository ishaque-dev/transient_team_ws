import 'package:equatable/equatable.dart';

enum TaskPriority {
  low,
  medium,
  high;
}

enum TaskStatus {
  pending,
  inProgress,
  completed;
}

class TaskEntity extends Equatable {
  final int? id;
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

  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    TaskStatus? status,
    String? assignedUserId,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      assignedUserId: assignedUserId ?? this.assignedUserId,
    );
  }
}
