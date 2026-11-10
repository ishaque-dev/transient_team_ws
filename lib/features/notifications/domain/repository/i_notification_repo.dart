import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

abstract interface class INotificationRepo {
  /// Newest first. Admins also receive notifications addressed to all admins.
  Stream<Either<Failure, List<AppNotificationEntity>>> watchNotifications({
    required String userId,
    required bool isAdmin,
  });
}
