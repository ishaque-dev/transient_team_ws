import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

abstract interface class ITaskRemoteDs {
  Future<List<TaskModel>> getTasks({
    required String userId,
    int offset = 0,
    int limit = 10,
    String? query,
    String? status,
    String? priority,
  });

  Future<TaskModel> createTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}
