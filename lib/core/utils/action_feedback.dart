import 'package:equatable/equatable.dart';

/// One-shot message for a snackbar. [serial] makes repeated identical
/// messages distinct so listeners fire every time.
class ActionFeedback extends Equatable {
  const ActionFeedback(this.message, {this.isError = false, this.serial = 0});

  final String message;
  final bool isError;
  final int serial;

  @override
  List<Object?> get props => [message, isError, serial];
}
