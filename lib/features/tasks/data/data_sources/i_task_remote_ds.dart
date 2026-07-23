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

  Future<TaskModel> createTask({
    required String userId,
    required TaskModel task,
  });

  Future<TaskModel> updateTask({
    required String userId,
    required TaskModel task,
  });

  Future<void> deleteTask({
    required String userId,
    required String taskId,
  });
}
