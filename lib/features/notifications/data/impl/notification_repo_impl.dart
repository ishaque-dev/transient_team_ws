import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/utils/either_stream.dart';
import 'package:transient_team_ws/features/notifications/data/data_sources/i_notification_remote_ds.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/repository/i_notification_repo.dart';

class NotificationRepoImpl implements INotificationRepo {
  NotificationRepoImpl({required this.remoteDs});

  final INotificationRemoteDs remoteDs;

  @override
  Stream<Either<Failure, List<AppNotificationEntity>>> watchNotifications({
    required String userId,
    required bool isAdmin,
  }) {
    return remoteDs
        .watchNotifications(
          recipients: [
            userId,
            if (isAdmin) AppNotificationEntity.adminsAudience,
          ],
        )
        .toEither();
  }
}
