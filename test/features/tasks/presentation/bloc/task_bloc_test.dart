import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/create_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/delete_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/get_tasks_use_case.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/update_task_use_case.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_bloc.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

class FakeGetTasksParams extends Fake implements GetTasksParams {}
class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late TaskBloc taskBloc;
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;

  setUpAll(() {
    registerFallbackValue(FakeGetTasksParams());
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockGetTasksUseCase = MockGetTasksUseCase();
    mockCreateTaskUseCase = MockCreateTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();
    mockDeleteTaskUseCase = MockDeleteTaskUseCase();
    taskBloc = TaskBloc(
      getTasksUseCase: mockGetTasksUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskUseCase: mockUpdateTaskUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
    );
  });

  final tTask = TaskEntity(
    id: '1',
    title: 'Test',
    description: 'Desc',
    priority: TaskPriority.high,
    dueDate: DateTime.now(),
    status: TaskStatus.pending,
  );

  test('initial state should be TaskState with initial status', () {
    expect(taskBloc.state, const TaskState());
  });

  group('FetchTasksRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should emit [loading, success] when fetching tasks is successful',
      build: () {
        when(() => mockGetTasksUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Right([tTask]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const FetchTasksRequested()),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        TaskState(status: TaskBlocStatus.success, tasks: [tTask], hasReachedMax: true),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'should emit [loading, failure] when fetching tasks fails',
      build: () {
        when(() => mockGetTasksUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Left(DefaultFailure(message: 'Error')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const FetchTasksRequested()),
      expect: () => [
        const TaskState(status: TaskBlocStatus.loading),
        const TaskState(status: TaskBlocStatus.failure, errorMessage: 'Error'),
      ],
    );
  });

  group('LoadMoreTasksRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should append tasks when more tasks are fetched',
      build: () {
        when(() => mockGetTasksUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Right([tTask]));
        return taskBloc;
      },
      seed: () => TaskState(status: TaskBlocStatus.success, tasks: [tTask]),
      act: (bloc) => bloc.add(const LoadMoreTasksRequested()),
      expect: () => [
        TaskState(status: TaskBlocStatus.success, tasks: [tTask, tTask], hasReachedMax: true),
      ],
    );
  });

  group('CreateTaskRequested', () {
    blocTest<TaskBloc, TaskState>(
      'should add task to the list when successful',
      build: () {
        when(() => mockCreateTaskUseCase(parameters: any(named: 'parameters')))
            .thenAnswer((_) async => Right(tTask));
        return taskBloc;
      },
      act: (bloc) => bloc.add(CreateTaskRequested(tTask)),
      expect: () => [
        TaskState(status: TaskBlocStatus.success, tasks: [tTask]),
      ],
    );
  });
}
