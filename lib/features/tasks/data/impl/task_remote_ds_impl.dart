import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

class TaskRemoteDsImpl implements ITaskRemoteDs {
  final FirebaseFirestore _firestore;

  TaskRemoteDsImpl(this._firestore);

  static const String _collectionPath = 'tasks';

  @override
  Future<List<TaskModel>> getTasks({
    required String userId,
    int offset = 0,
    int limit = 10,
    String? query,
    String? status,
    String? priority,
  }) async {
    var firestoreQuery = _firestore
        .collection(_collectionPath)
        .where('assignedUserId', isEqualTo: userId);

    if (status != null) {
      firestoreQuery = firestoreQuery.where('status', isEqualTo: status);
    }

    if (priority != null) {
      firestoreQuery = firestoreQuery.where('priority', isEqualTo: priority);
    }

    // Firestore pagination logic would go here in a real app.
    // We limit and fetch.
    final snapshot = await firestoreQuery.limit(limit + offset).get();
    
    return snapshot.docs
        .map((doc) => TaskModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    // Use the client-generated UUID as the document ID
    await _firestore.collection(_collectionPath).doc(task.id).set(task.toJson());
    return task;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    await _firestore.collection(_collectionPath).doc(task.id).update(task.toJson());
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }
}
