import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';

class MockTaskRepo extends Mock implements ITaskRepo {}

const admin = UserEntity(id: 'a1', email: 'boss@co.com', name: 'Asha Admin', role: UserRole.admin);
const employee = UserEntity(id: 'e1', email: 'eli@co.com', name: 'Eli Emp');

TaskEntity task({
  TaskStatus status = TaskStatus.todo,
  String? assigneeId = 'e1',
  DateTime? due,
  DateTime? completedAt,
}) => TaskEntity(
  id: 't1',
  title: 'Prepare report',
  description: 'Q3 numbers',
  priority: TaskPriority.high,
  status: status,
  dueDate: due ?? DateTime(2026, 11, 10),
  assigneeId: assigneeId,
  assigneeName: assigneeId == null ? null : 'Eli Emp',
  createdById: 'a1',
  createdByName: 'Asha Admin',
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
  completedAt: completedAt,
);

void main() {
  late MockTaskRepo repo;

  setUpAll(() {
    registerFallbackValue(task());
    registerFallbackValue(TaskStatus.todo);
    registerFallbackValue(
      TaskRating(quality: 1, timeliness: 1, ratedById: '', ratedByName: '', ratedAt: DateTime(2026)),
    );
  });

  setUp(() => repo = MockTaskRepo());

  List<AppNotificationEntity> capturedNotifications(Invocation inv) =>
      inv.namedArguments[#notifications] as List<AppNotificationEntity>;

  group('CreateTaskUseCase', () {
    test('creates task with activity and notifies the assignee', () async {
      List<AppNotificationEntity>? notifications;
      List<TaskActivityEntity>? activities;
      when(() => repo.createTask(any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')))
          .thenAnswer((inv) async {
            notifications = capturedNotifications(inv);
            activities = inv.namedArguments[#activities] as List<TaskActivityEntity>;
            return const Right(unit);
          });

      final result = await CreateTaskUseCase(repo).call(
        parameters: CreateTaskParams(
          title: '  Prepare report ',
          description: 'x',
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 11, 12, 15, 30),
          assignee: employee,
          actor: admin,
        ),
      );

      final created = result.getRight().toNullable()!;
      expect(created.title, 'Prepare report');
      expect(created.status, TaskStatus.todo);
      expect(created.dueDate, DateTime(2026, 11, 12));
      expect(created.assigneeId, 'e1');
      expect(created.id, isNotEmpty);
      expect(activities!.single.type, TaskActivityType.created);
      expect(notifications!.single.recipient, 'e1');
      expect(notifications!.single.type, NotificationType.taskAssigned);
    });

    test('rejects employees and empty titles', () async {
      final forbidden = await CreateTaskUseCase(repo).call(
        parameters: CreateTaskParams(title: 'x', description: '', priority: TaskPriority.low, dueDate: DateTime(2026), actor: employee),
      );
      expect(forbidden.getLeft().toNullable(), isA<ForbiddenFailure>());

      final invalid = await CreateTaskUseCase(repo).call(
        parameters: CreateTaskParams(title: '   ', description: '', priority: TaskPriority.low, dueDate: DateTime(2026), actor: admin),
      );
      expect(invalid.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => repo.createTask(any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')));
    });
  });

  group('ChangeTaskStatusUseCase', () {
    test('employee completing a task notifies all admins', () async {
      List<AppNotificationEntity>? notifications;
      when(() => repo.updateStatus(any(), any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')))
          .thenAnswer((inv) async {
            notifications = capturedNotifications(inv);
            return const Right(unit);
          });

      final result = await ChangeTaskStatusUseCase(repo).call(
        parameters: ChangeTaskStatusParams(task: task(), status: TaskStatus.completed, actor: employee),
      );

      expect(result.isRight(), isTrue);
      expect(notifications!.single.recipient, AppNotificationEntity.adminsAudience);
      expect(notifications!.single.message, contains('completed'));
    });

    test('admin changing status notifies the assignee', () async {
      List<AppNotificationEntity>? notifications;
      when(() => repo.updateStatus(any(), any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')))
          .thenAnswer((inv) async {
            notifications = capturedNotifications(inv);
            return const Right(unit);
          });

      await ChangeTaskStatusUseCase(repo).call(
        parameters: ChangeTaskStatusParams(task: task(), status: TaskStatus.onHold, actor: admin),
      );
      expect(notifications!.single.recipient, 'e1');
    });

    test('employee cannot update someone else\'s task', () async {
      final result = await ChangeTaskStatusUseCase(repo).call(
        parameters: ChangeTaskStatusParams(task: task(assigneeId: 'other'), status: TaskStatus.completed, actor: employee),
      );
      expect(result.getLeft().toNullable(), isA<ForbiddenFailure>());
    });

    test('no-op when status is unchanged', () async {
      final result = await ChangeTaskStatusUseCase(repo).call(
        parameters: ChangeTaskStatusParams(task: task(), status: TaskStatus.todo, actor: employee),
      );
      expect(result.isRight(), isTrue);
      verifyZeroInteractions(repo);
    });
  });

  group('UpdateTaskUseCase', () {
    test('reassignment logs activity and notifies the new assignee', () async {
      List<AppNotificationEntity>? notifications;
      List<TaskActivityEntity>? activities;
      when(() => repo.updateTask(any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')))
          .thenAnswer((inv) async {
            notifications = capturedNotifications(inv);
            activities = inv.namedArguments[#activities] as List<TaskActivityEntity>;
            return const Right(unit);
          });
      const newPerson = UserEntity(id: 'e2', email: 'n@co.com', name: 'Nia New');
      final original = task();

      final result = await UpdateTaskUseCase(repo).call(
        parameters: UpdateTaskParams(
          original: original,
          title: original.title,
          description: original.description,
          priority: TaskPriority.urgent,
          status: original.status,
          dueDate: original.dueDate,
          assignee: newPerson,
          actor: admin,
        ),
      );

      expect(result.getRight().toNullable()!.assigneeId, 'e2');
      expect(activities!.map((a) => a.type), [TaskActivityType.assigned, TaskActivityType.edited]);
      expect(activities!.last.message, 'updated the priority');
      expect(notifications!.single.recipient, 'e2');
    });

    test('unchanged form does not write', () async {
      final original = task();
      final result = await UpdateTaskUseCase(repo).call(
        parameters: UpdateTaskParams(
          original: original,
          title: original.title,
          description: original.description,
          priority: original.priority,
          status: original.status,
          dueDate: original.dueDate,
          assignee: employee,
          actor: admin,
        ),
      );
      expect(result.getRight().toNullable(), original);
      verifyZeroInteractions(repo);
    });
  });

  group('RateTaskUseCase', () {
    test('admin rates a completed task and the assignee is notified', () async {
      List<AppNotificationEntity>? notifications;
      when(() => repo.rateTask(any(), any(), activities: any(named: 'activities'), notifications: any(named: 'notifications')))
          .thenAnswer((inv) async {
            notifications = capturedNotifications(inv);
            return const Right(unit);
          });

      final result = await RateTaskUseCase(repo).call(
        parameters: RateTaskParams(
          task: task(status: TaskStatus.completed, completedAt: DateTime(2026, 11, 9)),
          quality: 5,
          timeliness: 4,
          note: '  Great work ',
          actor: admin,
        ),
      );

      final rating = result.getRight().toNullable()!;
      expect(rating.overall, 4.5);
      expect(rating.note, 'Great work');
      expect(notifications!.single.recipient, 'e1');
      expect(notifications!.single.type, NotificationType.rated);
    });

    test('rejects open tasks, out-of-range stars and employees', () async {
      Future<Object?> run(TaskEntity t, int q, UserEntity actor) async => (await RateTaskUseCase(repo).call(
            parameters: RateTaskParams(task: t, quality: q, timeliness: 3, actor: actor),
          ))
          .getLeft()
          .toNullable();

      expect(await run(task(), 4, admin), isA<ValidationFailure>());
      expect(await run(task(status: TaskStatus.completed), 6, admin), isA<ValidationFailure>());
      expect(await run(task(status: TaskStatus.completed), 4, employee), isA<ForbiddenFailure>());
    });
  });

  test('AddTaskCommentUseCase rejects blank comments', () async {
    final result = await AddTaskCommentUseCase(repo).call(
      parameters: AddTaskCommentParams(task: task(), message: '  ', actor: employee),
    );
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  group('TaskEntity deadline helpers', () {
    test('on-time vs late completion', () {
      final onTime = task(status: TaskStatus.completed, completedAt: DateTime(2026, 11, 10, 23, 59));
      final late = task(status: TaskStatus.completed, completedAt: DateTime(2026, 11, 13, 9));
      expect(onTime.completedOnTime, isTrue);
      expect(onTime.suggestedTimeliness, 5);
      expect(late.daysLate, 3);
      expect(late.completedOnTime, isFalse);
      expect(late.suggestedTimeliness, 3);
    });

    test('overdue only for open tasks past the due day', () {
      final now = DateTime(2026, 11, 11, 8);
      expect(task().isOverdue(now), isTrue);
      expect(task(due: DateTime(2026, 11, 11)).isOverdue(now), isFalse);
      expect(task(status: TaskStatus.completed).isOverdue(now), isFalse);
    });
  });
}
