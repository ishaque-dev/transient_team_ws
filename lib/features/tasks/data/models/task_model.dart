import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

enum TaskPriorityModel {
  low,
  medium,
  high;

  static TaskPriorityModel fromDomain(TaskPriority priority) {
    return TaskPriorityModel.values.byName(priority.name);
  }

  TaskPriority toDomain() {
    return TaskPriority.values.byName(name);
  }
}

enum TaskStatusModel {
  pending,
  inProgress,
  completed;

  static TaskStatusModel fromDomain(TaskStatus status) {
    return TaskStatusModel.values.byName(status.name);
  }

  TaskStatus toDomain() {
    return TaskStatus.values.byName(name);
  }
}

class TaskModel {
  final int? id;
  final String title;
  final String description;
  final TaskPriorityModel priority;
  final String dueDate;
  final TaskStatusModel status;
  final String? assignedUserId;

  const TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    this.assignedUserId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: TaskPriorityModel.values.byName(json['priority'] as String),
      dueDate: json['dueDate'] as String,
      status: TaskStatusModel.values.byName(json['status'] as String),
      assignedUserId: json['assignedUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'dueDate': dueDate,
      'status': status.name,
      if (assignedUserId != null) 'assignedUserId': assignedUserId,
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: TaskPriorityModel.fromDomain(entity.priority),
      dueDate: entity.dueDate.toIso8601String(),
      status: TaskStatusModel.fromDomain(entity.status),
      assignedUserId: entity.assignedUserId,
    );
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      priority: priority.toDomain(),
      dueDate: DateTime.parse(dueDate),
      status: status.toDomain(),
      assignedUserId: assignedUserId,
    );
  }
}
