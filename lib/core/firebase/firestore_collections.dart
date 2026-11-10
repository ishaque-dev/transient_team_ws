import 'package:cloud_firestore/cloud_firestore.dart';

/// Single source of truth for Firestore paths.
///
/// ```
/// environments/{namespace}/meta/workspace
/// environments/{namespace}/users/{uid}
/// environments/{namespace}/tasks/{taskId}
/// environments/{namespace}/tasks/{taskId}/activity/{activityId}
/// environments/{namespace}/notifications/{notificationId}
/// environments/{namespace}/subscription/current
/// ```
class FirestoreCollections {
  FirestoreCollections(this.firestore, this.namespace);

  final FirebaseFirestore firestore;
  final String namespace;

  DocumentReference<Map<String, dynamic>> get _root =>
      firestore.collection('environments').doc(namespace);

  CollectionReference<Map<String, dynamic>> get users =>
      _root.collection('users');

  CollectionReference<Map<String, dynamic>> get tasks =>
      _root.collection('tasks');

  CollectionReference<Map<String, dynamic>> get notifications =>
      _root.collection('notifications');

  CollectionReference<Map<String, dynamic>> activity(String taskId) =>
      tasks.doc(taskId).collection('activity');

  /// Subscription record, editable only from the Firebase console.
  DocumentReference<Map<String, dynamic>> get subscription =>
      _root.collection('subscription').doc('current');

  /// Created once, together with the first admin's profile.
  DocumentReference<Map<String, dynamic>> get workspace =>
      _root.collection('meta').doc('workspace');

  WriteBatch batch() => firestore.batch();
}
