import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/repository/i_notification_repo.dart';

class NotificationScope extends Equatable {
  const NotificationScope({required this.userId, required this.isAdmin});

  final String userId;
  final bool isAdmin;

  @override
  List<Object?> get props => [userId, isAdmin];
}

class WatchNotificationsUseCase
    implements UseCaseStream<List<AppNotificationEntity>, NotificationScope> {
  WatchNotificationsUseCase(this.repository);
  final INotificationRepo repository;

  @override
  Stream<Either<Failure, List<AppNotificationEntity>>> call({
    required NotificationScope parameters,
  }) {
    return repository.watchNotifications(
      userId: parameters.userId,
      isAdmin: parameters.isAdmin,
    );
  }
}
