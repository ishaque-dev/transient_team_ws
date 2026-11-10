import 'package:cloud_firestore/cloud_firestore.dart';

/// Strips the time component so due dates compare by calendar day.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Whole calendar days from [from] to [to] (negative when [to] is earlier).
int calendarDaysBetween(DateTime from, DateTime to) =>
    dateOnly(to).difference(dateOnly(from)).inDays;

/// Reads the date shapes Firestore and the local cache may hand back.
///
/// A pending server timestamp arrives as `null` until the server confirms the
/// write, so callers usually fall back to "now".
DateTime? parseDateTime(Object? value) {
  return switch (value) {
    Timestamp() => value.toDate(),
    DateTime() => value,
    String() => DateTime.tryParse(value),
    int() => DateTime.fromMillisecondsSinceEpoch(value),
    _ => null,
  };
}
