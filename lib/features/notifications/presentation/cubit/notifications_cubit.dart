import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/notifications/local_notifier.dart';
import 'package:transient_team_ws/core/notifications/notification_alert_tracker.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/auth/domain/use_cases/auth_use_cases.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/use_cases/watch_notifications_use_case.dart';

enum NotificationsStatus { loading, ready, failure }

/// Notification payload that opens the Team tab instead of a task.
const teamNotificationPayload = '__team__';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.seenAt,
    this.incoming,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotificationEntity> items;
  final DateTime? seenAt;

  /// The latest notification that arrived while the app was open.
  final AppNotificationEntity? incoming;
  final String? errorMessage;

  int get unreadCount => items.where((n) => n.isUnreadFor(seenAt)).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotificationEntity>? items,
    DateTime? seenAt,
    AppNotificationEntity? incoming,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      seenAt: seenAt ?? this.seenAt,
      incoming: incoming ?? this.incoming,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, seenAt, incoming, errorMessage];
}

/// Listens to the user's notification feed. New entries that arrive after the
/// first snapshot become [NotificationsState.incoming] and a system
/// notification.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required WatchNotificationsUseCase watchNotifications,
    required MarkNotificationsSeenUseCase markNotificationsSeen,
    required ILocalNotifier localNotifier,
    required UserEntity user,
    required this._tracker,
    bool Function()? alertsEnabled,
  }) : _alertsEnabled = alertsEnabled ?? _always,
       _watch = watchNotifications,
       _markSeen = markNotificationsSeen,
       _notifier = localNotifier,
       _user = user,
       super(NotificationsState(seenAt: user.notificationsSeenAt));

  final WatchNotificationsUseCase _watch;
  final MarkNotificationsSeenUseCase _markSeen;
  final ILocalNotifier _notifier;
  final UserEntity _user;

  /// Remote switch for phone notifications.
  final bool Function() _alertsEnabled;
  static bool _always() => true;

  StreamSubscription<Either<Failure, List<AppNotificationEntity>>>?
  _subscription;
  final NotificationAlertTracker _tracker;

  void start() {
    _subscription?.cancel();
    _subscription = _watch(
      parameters: NotificationScope(userId: _user.id, isAdmin: _user.isAdmin),
    ).listen(_onResult);
  }

  void _onResult(Either<Failure, List<AppNotificationEntity>> result) {
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (items) {
        final visible = items.where((n) => n.actorId != _user.id).toList();
        emit(state.copyWith(status: NotificationsStatus.ready, items: visible));
        _alertFresh(visible);
      },
    );
  }

  /// Raises a phone notification for each update not shown before, including
  /// ones that arrived while the app was closed. The tracker is shared with
  /// the background check, so nothing is announced twice.
  Future<void> _alertFresh(List<AppNotificationEntity> visible) async {
    final fresh = await _tracker.takeFresh(_user.id, visible);
    if (fresh.isEmpty || isClosed || !_alertsEnabled()) return;
    for (final notification in fresh.reversed) {
      await _notifier.show(
        id: notification.id.hashCode & 0x7fffffff,
        title: notification.actorName,
        body: notification.message,
        payload: notification.isAboutTask
            ? notification.taskId
            : teamNotificationPayload,
      );
    }
  }

  Future<void> markAllSeen() async {
    if (state.unreadCount == 0) return;
    emit(state.copyWith(seenAt: DateTime.now()));
    await _markSeen(parameters: _user.id);
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
