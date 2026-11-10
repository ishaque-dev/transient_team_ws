import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

/// Firestore mapping for tasks. Parsing is lenient so one malformed document
/// cannot break the whole live list.
abstract final class TaskModel {
  static TaskEntity fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final now = DateTime.now();
    return TaskEntity(
      id: id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      priority: TaskPriority.fromName(data['priority'] as String?),
      status: TaskStatus.fromName(data['status'] as String?),
      dueDate: dateOnly(parseDateTime(data['dueDate']) ?? now),
      assigneeId: data['assigneeId'] as String?,
      assigneeName: data['assigneeName'] as String?,
      createdById: (data['createdById'] as String?) ?? '',
      createdByName: (data['createdByName'] as String?) ?? '',
      // Pending server timestamps read as null until confirmed.
      createdAt: parseDateTime(data['createdAt']) ?? now,
      updatedAt: parseDateTime(data['updatedAt']) ?? now,
      completedAt: parseDateTime(data['completedAt']),
      rating: ratingFromMap(data['rating']),
    );
  }

  static TaskRating? ratingFromMap(Object? value) {
    if (value is! Map) return null;
    final quality = (value['quality'] as num?)?.toInt();
    final timeliness = (value['timeliness'] as num?)?.toInt();
    if (quality == null || timeliness == null) return null;
    return TaskRating(
      quality: quality,
      timeliness: timeliness,
      note: value['note'] as String?,
      ratedById: (value['ratedById'] as String?) ?? '',
      ratedByName: (value['ratedByName'] as String?) ?? '',
      ratedAt: parseDateTime(value['ratedAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> ratingToMap(TaskRating rating) {
    return {
      'quality': rating.quality,
      'timeliness': rating.timeliness,
      'note': rating.note,
      'ratedById': rating.ratedById,
      'ratedByName': rating.ratedByName,
      'ratedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Fields an admin may edit. Timestamps are set by the server.
  static Map<String, dynamic> editableFields(TaskEntity task) {
    return {
      'title': task.title,
      'description': task.description,
      'priority': task.priority.name,
      'status': task.status.name,
      'dueDate': Timestamp.fromDate(dateOnly(task.dueDate)),
      'assigneeId': task.assigneeId,
      'assigneeName': task.assigneeName,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': task.completedAt == null
          ? null
          : Timestamp.fromDate(task.completedAt!),
    };
  }

  static Map<String, dynamic> newDocument(TaskEntity task) {
    return {
      'id': task.id,
      ...editableFields(task),
      'createdById': task.createdById,
      'createdByName': task.createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// The only fields an employee's status update touches.
  static Map<String, dynamic> statusFields(TaskStatus status) {
    return {
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': status == TaskStatus.completed
          ? FieldValue.serverTimestamp()
          : null,
    };
  }
}
