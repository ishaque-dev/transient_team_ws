import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transient_team_ws/core/firebase/firestore_collections.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_remote_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreCollections collections;
  late TaskRemoteDsImpl ds;

  final task = TaskEntity(
    id: 't1',
    title: 'Ship release',
    description: 'v1.2',
    priority: TaskPriority.urgent,
    status: TaskStatus.todo,
    dueDate: DateTime(2026, 11, 20),
    assigneeId: 'e1',
    assigneeName: 'Eli',
    createdById: 'a1',
    createdByName: 'Asha',
    createdAt: DateTime(2026, 11, 1),
    updatedAt: DateTime(2026, 11, 1),
  );
  TaskActivityEntity activity(String id) => TaskActivityEntity(
    id: id,
    type: TaskActivityType.created,
    authorId: 'a1',
    authorName: 'Asha',
    message: 'created this task',
    createdAt: DateTime(2026, 11, 1),
  );
  final notification = AppNotificationEntity(
    id: 'n1',
    recipient: 'e1',
    type: NotificationType.taskAssigned,
    taskId: 't1',
    taskTitle: 'Ship release',
    actorId: 'a1',
    actorName: 'Asha',
    message: 'assigned you “Ship release”',
    createdAt: DateTime(2026, 11, 1),
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    collections = FirestoreCollections(firestore, 'dev');
    ds = TaskRemoteDsImpl(collections);
  });

  test('createTask writes task, activity and notification under the env', () async {
    await ds.createTask(task, [activity('act1')], [notification]);

    final doc = await firestore.doc('environments/dev/tasks/t1').get();
    expect(doc.data()!['title'], 'Ship release');
    expect(doc.data()!['priority'], 'urgent');
    expect((await collections.activity('t1').get()).docs, hasLength(1));
    expect((await collections.notifications.doc('n1').get()).data()!['recipient'], 'e1');
  });

  test('watchTasks scopes to the assignee', () async {
    await ds.createTask(task, [], []);
    await collections.tasks.doc('t2').set({'id': 't2', 'title': 'Other', 'assigneeId': 'e2', 'status': 'todo'});

    expect((await ds.watchTasks().first).map((t) => t.id), unorderedEquals(['t1', 't2']));
    expect((await ds.watchTasks(assigneeId: 'e1').first).single.title, 'Ship release');
  });

  test('updateStatus sets completedAt and only touches status fields', () async {
    await ds.createTask(task, [], []);
    await ds.updateStatus('t1', TaskStatus.completed, [activity('act2')], []);

    final done = (await ds.watchTasks().first).single;
    expect(done.status, TaskStatus.completed);
    expect(done.completedAt, isNotNull);
    expect(done.title, 'Ship release');

    await ds.updateStatus('t1', TaskStatus.inProgress, [], []);
    expect((await ds.watchTasks().first).single.completedAt, isNull);
  });

  test('rateTask stores the rating map', () async {
    await ds.createTask(task, [], []);
    await ds.rateTask(
      't1',
      TaskRating(quality: 4, timeliness: 5, note: 'Nice', ratedById: 'a1', ratedByName: 'Asha', ratedAt: DateTime(2026)),
      [],
      [],
    );
    final rated = (await ds.watchTasks().first).single;
    expect(rated.rating!.overall, 4.5);
    expect(rated.rating!.note, 'Nice');
  });

  test('deleteTask removes the activity trail too', () async {
    await ds.createTask(task, [activity('a'), activity('b')], []);
    await ds.deleteTask('t1');
    expect((await collections.tasks.get()).docs, isEmpty);
    expect((await collections.activity('t1').get()).docs, isEmpty);
  });

  test('watchActivity returns entries oldest first', () async {
    await collections.activity('t1').doc('late').set({'type': 'comment', 'message': 'second', 'createdAt': DateTime(2026, 11, 3)});
    await collections.activity('t1').doc('early').set({'type': 'comment', 'message': 'first', 'createdAt': DateTime(2026, 11, 2)});
    final items = await ds.watchActivity('t1').first;
    expect(items.map((a) => a.message), ['first', 'second']);
  });

  test('legacy and malformed documents parse leniently', () async {
    await collections.tasks.doc('old').set({'title': 'Legacy', 'status': 'pending', 'dueDate': '2026-01-05T00:00:00.000'});
    final legacy = (await ds.watchTasks().first).single;
    expect(legacy.status, TaskStatus.todo);
    expect(legacy.priority, TaskPriority.medium);
    expect(legacy.dueDate, DateTime(2026, 1, 5));
  });
}
