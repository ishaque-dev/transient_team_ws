import 'package:intl/intl.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';

abstract final class Formatters {
  static final _shortDate = DateFormat('d MMM');
  static final _longDate = DateFormat('EEE, d MMM yyyy');
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');

  static String shortDate(DateTime value, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return value.year == today.year
        ? _shortDate.format(value)
        : DateFormat('d MMM yyyy').format(value);
  }

  static String longDate(DateTime value) => _longDate.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  /// "Due today", "Due in 3 days", "Overdue by 2 days".
  static String dueLabel(DateTime due, {DateTime? now}) {
    final days = calendarDaysBetween(now ?? DateTime.now(), due);
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days == -1) return 'Overdue by 1 day';
    if (days < 0) return 'Overdue by ${-days} days';
    if (days < 7) return 'Due in $days days';
    return 'Due ${shortDate(due, now: now)}';
  }

  static String timeAgo(DateTime value, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(value);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(value, now: now);
  }

  static String percent(double ratio) => '${(ratio * 100).round()}%';
}
