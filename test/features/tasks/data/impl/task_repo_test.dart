import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/features/auth/data/data_sources/i_auth_local_ds.dart';
import 'package:transient_team_ws/features/auth/data/models/user_model.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_local_ds.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_remote_ds.dart';
import 'package:transient_team_ws/features/tasks/data/impl/task_repo_impl.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_enum_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

class MockTaskRemoteDs extends Mock implements ITaskRemoteDs {}
class MockTaskLocalDs extends Mock implements ITaskLocalDs {}
class MockAuthLocalDs extends Mock implements IAuthLocalDs {}

class FakeTaskModel extends Fake implements TaskModel {}
class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late TaskRepoImpl repository;
  late MockTaskRemoteDs mockRemoteDs;
  late MockTaskLocalDs mockLocalDs;
  late MockAuthLocalDs mockAuthLocalDs;

  setUpAll(() {
    registerFallbackValue(FakeTaskModel());
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockRemoteDs = MockTaskRemoteDs();
    mockLocalDs = MockTaskLocalDs();
    mockAuthLocalDs = MockAuthLocalDs();
    repository = TaskRepoImpl(
      remoteDs: mockRemoteDs,
      localDs: mockLocalDs,
      authLocalDs: mockAuthLocalDs,
    );
  });

  const tUserId = 'user123';
  const tUserModel = UserModel(id: tUserId, email: 'test@example.com');
  const tTaskModel = TaskModel(
    id: 'uuid-123',
    title: 'Test Task',
    description: 'Test Description',
    priority: TaskPriorityModel.high,
    dueDate: '2023-10-27T12:30:00.000',
    status: TaskStatusModel.pending,
    assignedUserId: tUserId,
  );

  final tTaskEntity = tTaskModel.toEntity();

  group('getTasks', () {
    test('should fetch from remote, cache, and return from local when successful', () async {
      // arrange
      when(() => mockAuthLocalDs.getCurrentUser()).thenAnswer((_) async => tUserModel);
      when(() => mockRemoteDs.getTasks(
            userId: any(named: 'userId'),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
          )).thenAnswer((_) async => [tTaskModel]);
      when(() => mockLocalDs.cacheTasks(any())).thenAnswer((_) async => {});
      when(() => mockLocalDs.getTasks(
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
          )).thenAnswer((_) async => [tTaskModel]);

      // act
      final result = await repository.getTasks(priority: TaskPriority.high);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, [tTaskEntity]));
      
      verify(() => mockAuthLocalDs.getCurrentUser()).called(1);
      verify(() => mockRemoteDs.getTasks(userId: tUserId, offset: 0, limit: 10, priority: 'high')).called(1);
      verify(() => mockLocalDs.cacheTasks([tTaskModel])).called(1);
      verify(() => mockLocalDs.getTasks(offset: 0, limit: 10, priority: 'high')).called(1);
    });
  });

  group('createTask', () {
    test('should call local insert, then remote, and return entity', () async {
      // arrange
      when(() => mockAuthLocalDs.getCurrentUser()).thenAnswer((_) async => tUserModel);
      when(() => mockLocalDs.insertTask(any())).thenAnswer((_) async => {});
      when(() => mockRemoteDs.createTask(
            userId: any(named: 'userId'),
            task: any(named: 'task'),
          )).thenAnswer((_) async => tTaskModel);

      // act
      final result = await repository.createTask(task: tTaskEntity);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tTaskEntity));

      verify(() => mockAuthLocalDs.getCurrentUser()).called(1);
      verify(() => mockLocalDs.insertTask(any())).called(1);
      verify(() => mockRemoteDs.createTask(userId: tUserId, task: any(named: 'task'))).called(1);
    });
  });

  group('deleteTask', () {
    test('should call remote, then local delete', () async {
      // arrange
      when(() => mockAuthLocalDs.getCurrentUser()).thenAnswer((_) async => tUserModel);
      when(() => mockRemoteDs.deleteTask(
            userId: any(named: 'userId'),
            taskId: any(named: 'taskId'),
          )).thenAnswer((_) async => {});
      when(() => mockLocalDs.deleteTask(any())).thenAnswer((_) async => {});

      // act
      final result = await repository.deleteTask(id: 'uuid-123');

      // assert
      expect(result.isRight(), true);
      verify(() => mockAuthLocalDs.getCurrentUser()).called(1);
      verify(() => mockRemoteDs.deleteTask(userId: tUserId, taskId: 'uuid-123')).called(1);
      verify(() => mockLocalDs.deleteTask('uuid-123')).called(1);
    });
  });
}
