import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

abstract interface class ITaskLocalDs {
  Future<List<TaskModel>> getTasks({
    int offset = 0,
    int limit = 10,
    String? query,
    String? status,
    String? priority,
  });

  Future<TaskModel?> getTaskById(String id);
  Future<void> insertTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> cacheTasks(List<TaskModel> tasks);
}
