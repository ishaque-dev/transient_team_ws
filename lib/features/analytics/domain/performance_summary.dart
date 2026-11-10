import 'package:equatable/equatable.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

/// Monday of the week containing [day].
DateTime weekStart(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - DateTime.monday));

class WeeklyCount extends Equatable {
  const WeeklyCount(this.weekStart, this.count);

  final DateTime weekStart;
  final int count;

  @override
  List<Object?> get props => [weekStart, count];
}

/// Aggregate delivery metrics for a set of tasks (a team or one employee).
class PerformanceSummary extends Equatable {
  const PerformanceSummary({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.onHold,
    required this.completed,
    required this.overdue,
    required this.dueSoon,
    required this.completedOnTime,
    required this.ratedCount,
    required this.weeklyCompleted,
    this.averageQuality,
    this.averageTimeliness,
  });

  factory PerformanceSummary.fromTasks(
    Iterable<TaskEntity> tasks, {
    DateTime? now,
    int weeks = 6,
  }) {
    final today = now ?? DateTime.now();
    var todo = 0, inProgress = 0, onHold = 0, completed = 0;
    var overdue = 0, dueSoon = 0, onTime = 0, rated = 0;
    var qualitySum = 0, timelinessSum = 0, total = 0;

    final firstWeek = weekStart(
      DateTime(today.year, today.month, today.day - 7 * (weeks - 1)),
    );
    final weekly = List<int>.filled(weeks, 0);

    for (final task in tasks) {
      total++;
      switch (task.status) {
        case TaskStatus.todo:
          todo++;
        case TaskStatus.inProgress:
          inProgress++;
        case TaskStatus.onHold:
          onHold++;
        case TaskStatus.completed:
          completed++;
      }

      if (task.isCompleted) {
        if (task.completedOnTime ?? false) onTime++;
        final done = task.completedAt;
        if (done != null) {
          final index = calendarDaysBetween(firstWeek, weekStart(done)) ~/ 7;
          if (index >= 0 && index < weeks) weekly[index]++;
        }
      } else {
        final daysLeft = calendarDaysBetween(today, task.dueDate);
        if (daysLeft < 0) {
          overdue++;
        } else if (daysLeft <= 3) {
          dueSoon++;
        }
      }

      final rating = task.rating;
      if (rating != null) {
        rated++;
        qualitySum += rating.quality;
        timelinessSum += rating.timeliness;
      }
    }

    return PerformanceSummary(
      total: total,
      todo: todo,
      inProgress: inProgress,
      onHold: onHold,
      completed: completed,
      overdue: overdue,
      dueSoon: dueSoon,
      completedOnTime: onTime,
      ratedCount: rated,
      averageQuality: rated == 0 ? null : qualitySum / rated,
      averageTimeliness: rated == 0 ? null : timelinessSum / rated,
      weeklyCompleted: [
        for (var i = 0; i < weeks; i++)
          WeeklyCount(
            DateTime(firstWeek.year, firstWeek.month, firstWeek.day + 7 * i),
            weekly[i],
          ),
      ],
    );
  }

  final int total;
  final int todo;
  final int inProgress;
  final int onHold;
  final int completed;

  /// Open tasks past their due date.
  final int overdue;

  /// Open tasks due within the next three days (not yet overdue).
  final int dueSoon;
  final int completedOnTime;
  final int ratedCount;
  final double? averageQuality;
  final double? averageTimeliness;

  /// Oldest week first; the last entry is the current week.
  final List<WeeklyCount> weeklyCompleted;

  int get open => total - completed;
  int get completedLate => completed - completedOnTime;

  int count(TaskStatus status) => switch (status) {
    TaskStatus.todo => todo,
    TaskStatus.inProgress => inProgress,
    TaskStatus.onHold => onHold,
    TaskStatus.completed => completed,
  };

  double? get completionRate => total == 0 ? null : completed / total;

  /// Deadline achievement: tasks finished on time, out of every task whose
  /// deadline has been tested (finished, or open past its due date).
  double? get deadlineRate {
    final tested = completed + overdue;
    return tested == 0 ? null : completedOnTime / tested;
  }

  /// Average of the admin's quality and deadline stars (1-5).
  double? get averageRating {
    final quality = averageQuality;
    final timeliness = averageTimeliness;
    if (quality == null || timeliness == null) return null;
    return (quality + timeliness) / 2;
  }

  /// 0-100 blend of deadline achievement (40%), admin ratings (40%) and
  /// completion rate (20%). Missing parts are left out and the remaining
  /// weights rescaled; null when there is nothing to score yet.
  int? get score {
    final parts = <(double, double)>[
      if (deadlineRate != null) (deadlineRate!, 0.4),
      if (averageRating != null) ((averageRating! - 1) / 4, 0.4),
      if (completionRate != null && completed > 0) (completionRate!, 0.2),
    ];
    if (parts.isEmpty || completed == 0 && overdue == 0) return null;
    final weight = parts.fold<double>(0, (sum, part) => sum + part.$2);
    final value = parts.fold<double>(0, (sum, part) => sum + part.$1 * part.$2);
    return (value / weight * 100).round().clamp(0, 100);
  }

  @override
  List<Object?> get props => [
    total,
    todo,
    inProgress,
    onHold,
    completed,
    overdue,
    dueSoon,
    completedOnTime,
    ratedCount,
    averageQuality,
    averageTimeliness,
    weeklyCompleted,
  ];
}

class EmployeePerformance extends Equatable {
  const EmployeePerformance({required this.employee, required this.summary});

  final UserEntity employee;
  final PerformanceSummary summary;

  /// One entry per active employee, best score first.
  static List<EmployeePerformance> rank({
    required Iterable<UserEntity> members,
    required Iterable<TaskEntity> tasks,
    DateTime? now,
  }) {
    final byAssignee = <String, List<TaskEntity>>{};
    for (final task in tasks) {
      final assignee = task.assigneeId;
      if (assignee != null) {
        (byAssignee[assignee] ??= []).add(task);
      }
    }

    final entries = [
      for (final member in members)
        if (member.isActive && member.role == UserRole.employee)
          EmployeePerformance(
            employee: member,
            summary: PerformanceSummary.fromTasks(
              byAssignee[member.id] ?? const [],
              now: now,
            ),
          ),
    ];

    entries.sort((a, b) {
      final scoreA = a.summary.score ?? -1;
      final scoreB = b.summary.score ?? -1;
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      final completed = b.summary.completed.compareTo(a.summary.completed);
      if (completed != 0) return completed;
      return a.employee.displayName.compareTo(b.employee.displayName);
    });
    return entries;
  }

  @override
  List<Object?> get props => [employee, summary];
}
