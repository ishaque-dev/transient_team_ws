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
