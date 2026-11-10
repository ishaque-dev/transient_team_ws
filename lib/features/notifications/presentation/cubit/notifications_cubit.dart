import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/notifications/local_notifier.dart';
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
  Set<String>? _knownIds;

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
        final known = _knownIds;
        _knownIds = visible.map((n) => n.id).toSet();

        AppNotificationEntity? newest;
        if (known != null) {
          final fresh = visible.where((n) => !known.contains(n.id)).toList();
          // A system notification for every new update, whether the app is
          // open or in the background.
          for (final notification
              in _alertsEnabled()
                  ? fresh.reversed
                  : const <AppNotificationEntity>[]) {
            _notifier.show(
              id: notification.id.hashCode & 0x7fffffff,
              title: notification.actorName,
              body: notification.message,
              payload: notification.isAboutTask
                  ? notification.taskId
                  : teamNotificationPayload,
            );
          }
          if (fresh.isNotEmpty) newest = fresh.first;
        }

        emit(
          state.copyWith(
            status: NotificationsStatus.ready,
            items: visible,
            incoming: newest,
          ),
        );
      },
    );
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
