import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/core/notifications/local_notifier.dart';
import 'package:transient_team_ws/core/notifications/notification_alert_tracker.dart';
import 'package:transient_team_ws/features/notifications/data/models/app_notification_model.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:transient_team_ws/firebase_options.dart';
import 'package:workmanager/workmanager.dart';

/// Phone notifications while the app is closed (Android).
///
/// Every ~15 minutes Android's WorkManager wakes the app in the background;
/// it reads new Firestore notifications for the signed-in user and shows them
/// with flutter_local_notifications. No server is involved.
abstract final class BackgroundNotifications {
  static const _uniqueName = 'coopiq-notification-check';
  static const _taskName = 'checkNotifications';

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_supported) return;
    try {
      await Workmanager().initialize(notificationCheckDispatcher);
    } catch (error) {
      debugPrint('Background notifications unavailable: $error');
    }
  }

  /// Starts the periodic check for [scope] (called after sign-in).
  static Future<void> enable(
    NotificationAlertTracker tracker,
    AlertScope scope,
  ) async {
    await tracker.saveScope(scope);
    if (!_supported) return;
    try {
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (error) {
      debugPrint('Could not schedule notification checks: $error');
    }
  }

  /// Stops the check (called on sign-out).
  static Future<void> disable(NotificationAlertTracker tracker) async {
    await tracker.clearScope();
    if (!_supported) return;
    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void notificationCheckDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      await checkForNewNotifications();
    } catch (error) {
      debugPrint('Background notification check failed: $error');
    }
    // Always report success; the next periodic run tries again anyway.
    return true;
  });
}

/// One background pass: fetch notifications newer than the last one shown,
/// then raise a system notification for each.
Future<void> checkForNewNotifications() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final tracker = NotificationAlertTracker(SharedPreferencesAsync());
  final scope = await tracker.readScope();
  if (scope == null) return _log('no signed-in scope');

  final user =
      FirebaseAuth.instance.currentUser ??
      await FirebaseAuth.instance.authStateChanges().first;
  if (user == null || user.uid != scope.userId) {
    return _log('auth user ${user?.uid} does not match scope ${scope.userId}');
  }

  final since = await tracker.lastAlerted(scope.userId);
  if (since == null) return _log('no alert baseline yet');

  final notifications = FirestoreCollections(
    FirebaseFirestore.instance,
    'prod',
  ).notifications;
  final recipients = [
    scope.userId,
    if (scope.isAdmin) AppNotificationEntity.adminsAudience,
  ];
  final snapshot = await notifications
      .where('recipient', whereIn: recipients)
      .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get(const GetOptions(source: Source.server));

  final fresh = await tracker.takeFresh(
    scope.userId,
    snapshot.docs.map(
      (doc) => AppNotificationModel.fromFirestore(doc.data(), id: doc.id),
    ),
  );
  _log('${snapshot.docs.length} newer than $since, ${fresh.length} to show');
  if (fresh.isEmpty) return;

  final notifier = LocalNotifier(FlutterLocalNotificationsPlugin());
  await notifier.initialize();
  for (final notification in fresh.reversed) {
    await notifier.show(
      id: notification.id.hashCode & 0x7fffffff,
      title: notification.actorName,
      body: notification.message,
      payload: notification.isAboutTask
          ? notification.taskId
          : teamNotificationPayload,
    );
  }
}

void _log(String message) => debugPrint('[background-notifications] $message');
