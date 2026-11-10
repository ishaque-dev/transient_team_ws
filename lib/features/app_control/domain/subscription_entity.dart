import 'package:equatable/equatable.dart';

/// The workspace's subscription, managed by the developer in Firestore
/// (`environments/prod/subscription/current`). The app can only read it.
class SubscriptionEntity extends Equatable {
  const SubscriptionEntity({
    required this.plan,
    required this.status,
    required this.validUntil,
    this.validFrom,
  });

  final String plan;

  /// `active` or `suspended`.
  final String status;
  final DateTime? validFrom;
  final DateTime? validUntil;

  bool get isSuspended => status != 'active';

  bool isValid(DateTime now) =>
      !isSuspended && validUntil != null && !now.isAfter(validUntil!);

  /// Whole days left, or null when there is no end date.
  int? daysLeft(DateTime now) {
    final end = validUntil;
    if (end == null) return null;
    return end.difference(now).inHours ~/ 24;
  }

  @override
  List<Object?> get props => [plan, status, validFrom, validUntil];
}
