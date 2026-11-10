import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

abstract final class AppNotificationModel {
  static AppNotificationEntity fromFirestore(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return AppNotificationEntity(
      id: id,
      recipient: (data['recipient'] as String?) ?? '',
      type: NotificationType.fromName(data['type'] as String?),
      taskId: (data['taskId'] as String?) ?? '',
      taskTitle: (data['taskTitle'] as String?) ?? '',
      actorId: (data['actorId'] as String?) ?? '',
      actorName: (data['actorName'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(AppNotificationEntity notification) {
    return {
      'id': notification.id,
      'recipient': notification.recipient,
      'type': notification.type.name,
      'taskId': notification.taskId,
      'taskTitle': notification.taskTitle,
      'actorId': notification.actorId,
      'actorName': notification.actorName,
      'message': notification.message,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
