import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/core/firebase/firestore_writes.dart';
import 'package:transient_team_ws/features/notifications/data/models/app_notification_model.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_activity_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

class TaskRemoteDsImpl implements ITaskRemoteDs {
  TaskRemoteDsImpl(
    this._collections, {
    this.ackTimeout = const Duration(seconds: 10),
  });

  final FirestoreCollections _collections;
  final Duration ackTimeout;

  @override
  Stream<List<TaskEntity>> watchTasks({String? assigneeId}) {
    Query<Map<String, dynamic>> query = _collections.tasks;
    if (assigneeId != null) {
      // Single-field equality: served by Firestore's automatic index.
      query = query.where('assigneeId', isEqualTo: assigneeId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc.data(), id: doc.id))
          .toList(),
    );
  }

  @override
  Stream<List<TaskActivityEntity>> watchActivity(String taskId) {
    return _collections.activity(taskId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => TaskActivityModel.fromFirestore(doc.data(), id: doc.id))
          .toList();
      // Sorted here rather than in the query: entries with a pending server
      // timestamp would otherwise drop out of an ordered query briefly.
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    });
  }

  @override
  Future<void> createTask(
    TaskEntity task,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  ) {
    return _write(task.id, activities, notifications, (batch) {
      batch.set(_collections.tasks.doc(task.id), TaskModel.newDocument(task));
    });
  }

  @override
  Future<void> updateTask(
    TaskEntity task,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  ) {
    return _write(task.id, activities, notifications, (batch) {
      batch.update(
        _collections.tasks.doc(task.id),
        TaskModel.editableFields(task),
      );
    });
  }

  @override
  Future<void> updateStatus(
    String taskId,
    TaskStatus status,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  ) {
    return _write(taskId, activities, notifications, (batch) {
      batch.update(
        _collections.tasks.doc(taskId),
        TaskModel.statusFields(status),
      );
    });
  }

  @override
  Future<void> rateTask(
    String taskId,
    TaskRating rating,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  ) {
    return _write(taskId, activities, notifications, (batch) {
      batch.update(_collections.tasks.doc(taskId), {
        'rating': TaskModel.ratingToMap(rating),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> addActivity(
    String taskId,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
  ) {
    return _write(taskId, activities, notifications, (_) {});
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      final activity = await _collections.activity(taskId).get();
      final batch = _collections.batch();
      for (final doc in activity.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_collections.tasks.doc(taskId));
      await commitBatch(batch, ackTimeout: ackTimeout);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }

  Future<void> _write(
    String taskId,
    List<TaskActivityEntity> activities,
    List<AppNotificationEntity> notifications,
    void Function(WriteBatch batch) mutateTask,
  ) async {
    try {
      final batch = _collections.batch();
      mutateTask(batch);
      for (final activity in activities) {
        batch.set(
          _collections.activity(taskId).doc(activity.id),
          TaskActivityModel.toFirestore(activity),
        );
      }
      for (final notification in notifications) {
        batch.set(
          _collections.notifications.doc(notification.id),
          AppNotificationModel.toFirestore(notification),
        );
      }
      await commitBatch(batch, ackTimeout: ackTimeout);
    } catch (error) {
      throw AppErrorHandler.handle(error);
    }
  }
}
