import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transient_team_ws/core/database/db.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_local_ds_impl.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_enum_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

class MockDatabase extends Mock implements Database {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockBatch extends Mock implements Batch {}

void main() {
  late TaskLocalDsImpl localDs;
  late MockDatabase mockDatabase;
  late MockDatabaseHelper mockDbHelper;

  setUp(() {
    mockDatabase = MockDatabase();
    mockDbHelper = MockDatabaseHelper();
    localDs = TaskLocalDsImpl(mockDbHelper);
    when(() => mockDbHelper.database).thenAnswer((_) async => mockDatabase);
  });

  const tTaskModel = TaskModel(
    id: 'uuid-123',
    title: 'Test Task',
    description: 'Test Description',
    priority: TaskPriorityModel.high,
    dueDate: '2023-10-27T12:30:00.000',
    status: TaskStatusModel.pending,
  );

  group('getTasks', () {
    test('should build query correctly with search and filters', () async {
      // arrange
      when(() => mockDatabase.query(
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
            orderBy: any(named: 'orderBy'),
          )).thenAnswer((_) async => []);

      // act
      await localDs.getTasks(
        query: 'search',
        status: 'pending',
        priority: 'high',
        limit: 20,
        offset: 10,
      );

      // assert
      verify(() => mockDatabase.query(
            'tasks',
            where: 'title LIKE ? AND status = ? AND priority = ?',
            whereArgs: ['%search%', 'pending', 'high'],
            limit: 20,
            offset: 10,
            orderBy: 'dueDate ASC',
          )).called(1);
    });
  });

  group('insertTask', () {
    test('should call insert on database', () async {
      // arrange
      when(() => mockDatabase.insert(any(), any(), conflictAlgorithm: any(named: 'conflictAlgorithm')))
          .thenAnswer((_) async => 1);

      // act
      await localDs.insertTask(tTaskModel);

      // assert
      verify(() => mockDatabase.insert(
            'tasks',
            tTaskModel.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          )).called(1);
    });
  });

  group('cacheTasks', () {
    test('should use batch to insert multiple tasks', () async {
      // arrange
      final mockBatch = MockBatch();
      when(() => mockDatabase.batch()).thenReturn(mockBatch);
      when(() => mockBatch.commit(noResult: any(named: 'noResult')))
          .thenAnswer((_) async => []);

      // act
      await localDs.cacheTasks([tTaskModel]);

      // assert
      verify(() => mockDatabase.batch()).called(1);
      verify(() => mockBatch.insert(
            'tasks',
            tTaskModel.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          )).called(1);
      verify(() => mockBatch.commit(noResult: true)).called(1);
    });
  });
}
