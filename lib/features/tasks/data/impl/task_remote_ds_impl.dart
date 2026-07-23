import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

class TaskRemoteDsImpl implements ITaskRemoteDs {
  final FirebaseFirestore _firestore;

  TaskRemoteDsImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> _userTasks(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  @override
  Future<List<TaskModel>> getTasks({
    required String userId,
    int offset = 0,
    int limit = 10,
    String? query,
    String? status,
    String? priority,
  }) async {
    var firestoreQuery = _userTasks(userId);

    Query<Map<String, dynamic>> finalQuery = firestoreQuery;

    if (status != null) {
      finalQuery = finalQuery.where('status', isEqualTo: status);
    }

    if (priority != null) {
      finalQuery = finalQuery.where('priority', isEqualTo: priority);
    }

    final snapshot = await finalQuery.limit(limit + offset).get();

    return snapshot.docs
        .map((doc) => TaskModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<TaskModel> createTask({
    required String userId,
    required TaskModel task,
  }) async {
    await _userTasks(userId).doc(task.id).set(task.toJson());
    return task;
  }

  @override
  Future<TaskModel> updateTask({
    required String userId,
    required TaskModel task,
  }) async {
    await _userTasks(userId).doc(task.id).update(task.toJson());
    return task;
  }

  @override
  Future<void> deleteTask({
    required String userId,
    required String taskId,
  }) async {
    await _userTasks(userId).doc(taskId).delete();
  }
}
