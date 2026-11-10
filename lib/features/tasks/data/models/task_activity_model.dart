import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

abstract final class TaskActivityModel {
  static TaskActivityEntity fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final toStatus = data['toStatus'] as String?;
    return TaskActivityEntity(
      id: id,
      type: TaskActivityType.fromName(data['type'] as String?),
      authorId: (data['authorId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
      toStatus: toStatus == null ? null : TaskStatus.fromName(toStatus),
    );
  }

  static Map<String, dynamic> toFirestore(TaskActivityEntity activity) {
    return {
      'id': activity.id,
      'type': activity.type.name,
      'authorId': activity.authorId,
      'authorName': activity.authorName,
      'message': activity.message,
      'toStatus': activity.toStatus?.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
