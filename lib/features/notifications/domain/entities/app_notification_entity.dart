import 'package:equatable/equatable.dart';

enum NotificationType {
  taskAssigned,
  taskUpdated,
  statusChanged,
  comment,
  rated,

  /// Someone signed up and is waiting for an admin's approval.
  accessRequested;

  static NotificationType fromName(String? value) =>
      NotificationType.values.asNameMap()[value] ??
      NotificationType.taskUpdated;
}

class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.recipient,
    required this.type,
    required this.taskId,
    required this.taskTitle,
    required this.actorId,
    required this.actorName,
    required this.message,
    required this.createdAt,
  });

  bool get isAboutTask => taskId.isNotEmpty;

  /// Recipient value that targets every admin.
  static const String adminsAudience = 'admins';

  /// A user id, or [adminsAudience].
  final String recipient;
  final String id;
  final NotificationType type;
  final String taskId;
  final String taskTitle;
  final String actorId;
  final String actorName;

  /// Sentence fragment that follows the actor's name, e.g.
  /// `completed "Prepare Q3 report"`.
  final String message;
  final DateTime createdAt;

  bool isUnreadFor(DateTime? seenAt) =>
      seenAt == null || createdAt.isAfter(seenAt);

  @override
  List<Object?> get props => [
    id,
    recipient,
    type,
    taskId,
    taskTitle,
    actorId,
    actorName,
    message,
    createdAt,
  ];
}
