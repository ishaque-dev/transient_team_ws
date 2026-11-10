import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

abstract interface class INotificationRemoteDs {
  Stream<List<AppNotificationEntity>> watchNotifications({
    required List<String> recipients,
    int limit = 50,
  });
}
