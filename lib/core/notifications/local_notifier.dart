import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows system notifications for events the app hears about through its
/// Firestore listeners. No server or push service is involved, so alerts
/// arrive while the app is running (foreground or recently backgrounded).
abstract interface class ILocalNotifier {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Payloads of notifications the user tapped.
  Stream<String> get taps;
}

class LocalNotifier implements ILocalNotifier {
  LocalNotifier(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channelId = 'task_updates';
  static const _channelName = 'Task updates';

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    if (_ready || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );
      _ready = true;
    } catch (error) {
      debugPrint('Local notifications unavailable: $error');
    }
  }

  @override
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Assignments, status changes and ratings',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Could not show notification: $error');
    }
  }
}
