import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Commits [batch], tolerating a missing server acknowledgement.
///
/// Firestore applies writes to its local cache immediately (live listeners
/// see them at once) but only completes `commit()` when the server confirms.
/// Offline that never happens, so after [ackTimeout] the write is treated as
/// queued: it stays in the local cache and syncs when the connection returns.
/// Server rejections, such as security-rule failures, still surface as errors
/// whenever the server answers within the timeout.
Future<void> commitBatch(
  WriteBatch batch, {
  Duration ackTimeout = const Duration(seconds: 10),
}) async {
  try {
    await batch.commit().timeout(ackTimeout);
  } on TimeoutException {
    // Queued offline; see above.
  }
}
