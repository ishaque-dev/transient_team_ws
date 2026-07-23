import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_task_by_id_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_tasks_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:uuid/uuid.dart';

class MockTaskRepo extends Mock implements ITaskRepo {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late MockTaskRepo mockRepo;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(TaskEntity(
      id: '1',
      title: 't',
      description: 'd',
      priority: TaskPriority.low,
      dueDate: DateTime.now(),
      status: TaskStatus.pending,
    ));
  });

  setUp(() {
    mockRepo = MockTaskRepo();
    mockUuid = MockUuid();
  });

  final tTask = TaskEntity(
    id: 'uuid-123',
    title: 'Test Task',
    description: 'Test Description',
    priority: TaskPriority.high,
    dueDate: DateTime(2023, 10, 27),
    status: TaskStatus.pending,
  );

  group('CreateTaskUseCase', () {
    test('should generate UUID and call repository', () async {
      // arrange
      final useCase = CreateTaskUseCase(mockRepo, uuid: mockUuid);
      final taskWithoutId = TaskEntity(
        id: '', // Empty or dummy ID
        title: tTask.title,
        description: tTask.description,
        priority: tTask.priority,
        dueDate: tTask.dueDate,
        status: tTask.status,
      );

      when(() => mockUuid.v4()).thenReturn('uuid-123');
      when(() => mockRepo.createTask(task: any(named: 'task')))
          .thenAnswer((_) async => Right(tTask));

      // act
      final result = await useCase(parameters: taskWithoutId);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tTask));
      
      verify(() => mockUuid.v4()).called(1);
      verify(() => mockRepo.createTask(task: tTask)).called(1);
    });
  });

  group('GetTasksUseCase', () {
    test('should call repository with correct params', () async {
      // arrange
      final useCase = GetTasksUseCase(mockRepo);
      const params = GetTasksParams(query: 'search', limit: 5, priority: TaskPriority.high);
      when(() => mockRepo.getTasks(
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            status: any(named: 'status'),
            priority: any(named: 'priority'),
          )).thenAnswer((_) async => Right([tTask]));

      // act
      final result = await useCase(parameters: params);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, [tTask]));
      
      verify(() => mockRepo.getTasks(offset: 0, limit: 5, query: 'search', priority: TaskPriority.high)).called(1);
    });
  });

  group('UpdateTaskUseCase', () {
    test('should call repository update', () async {
      // arrange
      final useCase = UpdateTaskUseCase(mockRepo);
      when(() => mockRepo.updateTask(task: any(named: 'task')))
          .thenAnswer((_) async => Right(tTask));

      // act
      final result = await useCase(parameters: tTask);

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tTask));
      
      verify(() => mockRepo.updateTask(task: tTask)).called(1);
    });
  });

  group('DeleteTaskUseCase', () {
    test('should call repository delete', () async {
      // arrange
      final useCase = DeleteTaskUseCase(mockRepo);
      when(() => mockRepo.deleteTask(id: any(named: 'id')))
          .thenAnswer((_) async => const Right(unit));

      // act
      final result = await useCase(parameters: 'uuid-123');

      // assert
      expect(result.isRight(), true);
      
      verify(() => mockRepo.deleteTask(id: 'uuid-123')).called(1);
    });
  });

  group('GetTaskByIdUseCase', () {
    test('should call repository getById', () async {
      // arrange
      final useCase = GetTaskByIdUseCase(mockRepo);
      when(() => mockRepo.getTaskById(id: any(named: 'id')))
          .thenAnswer((_) async => Right(tTask));

      // act
      final result = await useCase(parameters: 'uuid-123');

      // assert
      expect(result.isRight(), true);
      result.fold((l) => fail('Should be right'), (r) => expect(r, tTask));

      verify(() => mockRepo.getTaskById(id: 'uuid-123')).called(1);
    });
  });
}
