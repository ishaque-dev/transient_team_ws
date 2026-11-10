import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/app_control/domain/feature_flags.dart';
import 'package:transient_team_ws/features/app_control/domain/subscription_entity.dart';

/// Remote Config (feature switches) plus the Firestore subscription record.
class AppControlRemoteDs {
  AppControlRemoteDs(this._remoteConfig, this._collections);

  final FirebaseRemoteConfig _remoteConfig;
  final FirestoreCollections _collections;

  /// Loads the latest switches, falling back to in-app defaults when offline.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(FlagKeys.defaults);
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      await _remoteConfig.fetchAndActivate().timeout(
        const Duration(seconds: 6),
      );
    } catch (error) {
      debugPrint('Remote Config unavailable, using defaults: $error');
    }
  }

  FeatureFlags currentFlags() => FeatureFlags.read(
    getBool: _remoteConfig.getBool,
    getString: _remoteConfig.getString,
  );

  /// Emits whenever the owner publishes a change in the Firebase console.
  Stream<FeatureFlags> watchFlags() {
    return _remoteConfig.onConfigUpdated
        .asyncMap((_) async {
          await _remoteConfig.activate();
          return currentFlags();
        })
        .handleError((Object error) {
          debugPrint('Remote Config live updates unavailable: $error');
        });
  }

  /// Null when the subscription record does not exist.
  Stream<SubscriptionEntity?> watchSubscription() {
    return _collections.subscription.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return SubscriptionEntity(
        plan: (data['plan'] as String?) ?? 'Standard',
        status: (data['status'] as String?) ?? 'active',
        validFrom: parseDateTime(data['validFrom']),
        validUntil: parseDateTime(data['validUntil']),
      );
    });
  }
}
