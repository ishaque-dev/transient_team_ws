import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_remote_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_enum_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

void main() {
  late TaskRemoteDsImpl remoteDs;
  late FakeFirebaseFirestore fakeFirestore;
  const tUserCollection = 'users_test';
  const tUserId = 'user123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    remoteDs = TaskRemoteDsImpl(fakeFirestore, tUserCollection);
  });

  const tTaskModel = TaskModel(
    id: 'task123',
    title: 'Test Task',
    description: 'Desc',
    priority: TaskPriorityModel.high,
    dueDate: '2023-10-27',
    status: TaskStatusModel.pending,
  );

  group('getTasks', () {
    test('should return list of TaskModel on success', () async {
      // arrange
      await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .set(tTaskModel.toJson());

      // act
      final result = await remoteDs.getTasks(userId: tUserId);

      // assert
      expect(result.length, 1);
      expect(result.first.id, tTaskModel.id);
    });

    test('should apply filters correctly in Firestore', () async {
      // arrange
      await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .set(tTaskModel.toJson());
      
      final otherTask = TaskModel(
        id: 'task456',
        title: 'Other Task',
        description: 'Desc',
        priority: TaskPriorityModel.low,
        dueDate: '2023-10-28',
        status: TaskStatusModel.completed,
      );
      await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(otherTask.id)
          .set(otherTask.toJson());

      // act: filter by completed
      final result = await remoteDs.getTasks(userId: tUserId, status: 'completed');

      // assert
      expect(result.length, 1);
      expect(result.first.status, TaskStatusModel.completed);
    });
  });

  group('createTask', () {
    test('should successfully create task in Firestore', () async {
      // act
      await remoteDs.createTask(userId: tUserId, task: tTaskModel);

      // assert
      final doc = await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .get();
      
      expect(doc.exists, true);
      expect(doc.data()!['id'], tTaskModel.id);
    });
  });

  group('updateTask', () {
    test('should successfully update task in Firestore', () async {
      // arrange
      await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .set(tTaskModel.toJson());

      final updatedTask = TaskModel(
        id: tTaskModel.id,
        title: 'Updated Title',
        description: tTaskModel.description,
        priority: tTaskModel.priority,
        dueDate: tTaskModel.dueDate,
        status: tTaskModel.status,
      );

      // act
      await remoteDs.updateTask(userId: tUserId, task: updatedTask);

      // assert
      final doc = await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .get();
      
      expect(doc.data()!['title'], 'Updated Title');
    });
  });

  group('deleteTask', () {
    test('should successfully delete task from Firestore', () async {
      // arrange
      await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .set(tTaskModel.toJson());

      // act
      await remoteDs.deleteTask(userId: tUserId, taskId: tTaskModel.id);

      // assert
      final doc = await fakeFirestore
          .collection(tUserCollection)
          .doc(tUserId)
          .collection('tasks')
          .doc(tTaskModel.id)
          .get();
      
      expect(doc.exists, false);
    });
  });
}
