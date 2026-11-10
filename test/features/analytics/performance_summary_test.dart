import 'package:flutter_test/flutter_test.dart';
import 'package:transient_team_ws/features/analytics/domain/performance_summary.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

final now = DateTime(2026, 11, 12, 10); // Thursday

TaskEntity t({
  String assignee = 'e1',
  TaskStatus status = TaskStatus.todo,
  required DateTime due,
  DateTime? completedAt,
  int? quality,
  int? timeliness,
}) => TaskEntity(
  id: '${due.millisecondsSinceEpoch}-$assignee-${status.name}',
  title: 'x',
  description: '',
  priority: TaskPriority.medium,
  status: status,
  dueDate: due,
  assigneeId: assignee,
  createdById: 'a',
  createdByName: 'A',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  completedAt: completedAt,
  rating: quality == null
      ? null
      : TaskRating(quality: quality, timeliness: timeliness!, ratedById: 'a', ratedByName: 'A', ratedAt: now),
);

void main() {
  test('weekStart is Monday', () {
    expect(weekStart(DateTime(2026, 11, 12)), DateTime(2026, 11, 9));
    expect(weekStart(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
  });

  test('summary counts, rates and weekly buckets', () {
    final tasks = [
      t(status: TaskStatus.completed, due: DateTime(2026, 11, 10), completedAt: DateTime(2026, 11, 10), quality: 5, timeliness: 5),
      t(status: TaskStatus.completed, due: DateTime(2026, 11, 1), completedAt: DateTime(2026, 11, 4), quality: 3, timeliness: 2),
      t(due: DateTime(2026, 11, 11)), // overdue
      t(status: TaskStatus.inProgress, due: DateTime(2026, 11, 14)), // due soon
    ];
    final s = PerformanceSummary.fromTasks(tasks, now: now, weeks: 3);

    expect(s.total, 4);
    expect(s.completed, 2);
    expect(s.overdue, 1);
    expect(s.dueSoon, 1);
    expect(s.completedOnTime, 1);
    expect(s.deadlineRate, closeTo(1 / 3, 1e-9));
    expect(s.averageRating, 3.75);
    expect(s.weeklyCompleted.map((w) => w.count), [0, 1, 1]);
    expect(s.weeklyCompleted.last.weekStart, DateTime(2026, 11, 9));
    // 0.4 * 1/3 + 0.4 * (2.75/4) + 0.2 * 0.5 = 0.508 / 1.0
    expect(s.score, 51);
  });

  test('no score until something has been delivered or missed', () {
    expect(PerformanceSummary.fromTasks([t(due: DateTime(2026, 12, 1))], now: now).score, isNull);
    expect(PerformanceSummary.fromTasks(const [], now: now).completionRate, isNull);
  });

  test('ranking orders employees by score and includes idle employees', () {
    const good = UserEntity(id: 'e1', email: 'a@x.io', name: 'Good');
    const weak = UserEntity(id: 'e2', email: 'b@x.io', name: 'Weak');
    const idle = UserEntity(id: 'e3', email: 'c@x.io', name: 'Idle');
    const boss = UserEntity(id: 'a', email: 'd@x.io', name: 'Boss', role: UserRole.admin);
    final ranking = EmployeePerformance.rank(
      members: [weak, idle, good, boss],
      tasks: [
        t(assignee: 'e1', status: TaskStatus.completed, due: DateTime(2026, 11, 10), completedAt: DateTime(2026, 11, 9)),
        t(assignee: 'e2', due: DateTime(2026, 11, 1)),
      ],
      now: now,
    );
    expect(ranking.map((r) => r.employee.id), ['e1', 'e2', 'e3']);
    expect(ranking.first.summary.score, 100);
    expect(ranking[1].summary.score, 0);
  });
}
