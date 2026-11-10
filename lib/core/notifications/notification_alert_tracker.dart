import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

/// Who the background check fetches notifications for.
class AlertScope {
  const AlertScope({required this.userId, required this.isAdmin});

  final String userId;
  final bool isAdmin;
}

/// Remembers, per user, the newest notification already shown on the phone,
/// so each update raises exactly one system notification, whether it is
/// picked up by the open app or by the background check.
///
/// Uses [SharedPreferencesAsync] (no in-memory cache) because the background
/// check runs in a separate isolate.
class NotificationAlertTracker {
  NotificationAlertTracker(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _scopeUser = 'alerts.scope.user';
  static const _scopeAdmin = 'alerts.scope.admin';
  static String _lastKey(String userId) => 'alerts.last.$userId';

  /// Most system notifications shown in one go; older ones stay in the bell.
  static const maxBurst = 5;

  Future<DateTime?> lastAlerted(String userId) async {
    final millis = await _prefs.getInt(_lastKey(userId));
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Returns notifications not yet shown (newest first) and marks them shown.
  /// On a user's first run nothing is returned: history is not replayed.
  Future<List<AppNotificationEntity>> takeFresh(
    String userId,
    Iterable<AppNotificationEntity> items,
  ) async {
    final last = await lastAlerted(userId);
    if (last == null) {
      await _prefs.setInt(
        _lastKey(userId),
        DateTime.now().millisecondsSinceEpoch,
      );
      return const [];
    }
    final fresh =
        items
            .where((n) => n.actorId != userId && n.createdAt.isAfter(last))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (fresh.isEmpty) return const [];
    await _prefs.setInt(
      _lastKey(userId),
      fresh.first.createdAt.millisecondsSinceEpoch,
    );
    return fresh.take(maxBurst).toList();
  }

  Future<void> saveScope(AlertScope scope) async {
    await _prefs.setString(_scopeUser, scope.userId);
    await _prefs.setBool(_scopeAdmin, scope.isAdmin);
  }

  Future<AlertScope?> readScope() async {
    final user = await _prefs.getString(_scopeUser);
    if (user == null) return null;
    return AlertScope(
      userId: user,
      isAdmin: await _prefs.getBool(_scopeAdmin) ?? false,
    );
  }

  Future<void> clearScope() async {
    await _prefs.remove(_scopeUser);
    await _prefs.remove(_scopeAdmin);
  }
}
