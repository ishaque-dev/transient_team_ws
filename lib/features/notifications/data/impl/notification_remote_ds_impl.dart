import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/features/notifications/data/data_sources/i_notification_remote_ds.dart';
import 'package:transient_team_ws/features/notifications/data/models/app_notification_model.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';

class NotificationRemoteDsImpl implements INotificationRemoteDs {
  NotificationRemoteDsImpl(this._collections);

  final FirestoreCollections _collections;

  @override
  Stream<List<AppNotificationEntity>> watchNotifications({
    required List<String> recipients,
    int limit = 50,
  }) async* {
    final base = _collections.notifications.where(
      'recipient',
      whereIn: recipients,
    );
    try {
      // Needs the composite index in firestore.indexes.json.
      await for (final snapshot
          in base
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .snapshots()) {
        yield _parse(snapshot, limit);
      }
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
      // Index not deployed yet: keep working with an unordered query and
      // sort on the device instead.
      debugPrint(
        'Notifications index missing; run `firebase deploy --only '
        'firestore:indexes`. Falling back to client-side sorting.',
      );
      await for (final snapshot in base.limit(200).snapshots()) {
        yield _parse(snapshot, limit);
      }
    }
  }

  List<AppNotificationEntity> _parse(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    int limit,
  ) {
    final items =
        snapshot.docs
            .map(
              (doc) =>
                  AppNotificationModel.fromFirestore(doc.data(), id: doc.id),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }
}
