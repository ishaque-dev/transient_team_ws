import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';
import 'package:transient_team_ws/features/tasks/presentation/bloc/task_list_bloc.dart';

class MockWatchTasks extends Mock implements WatchTasksUseCase {}

final now = DateTime(2026, 11, 10, 9);

TaskEntity t(String id, {
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  int dueInDays = 1,
  String? assignee = 'e1',
  String title = 'Task',
  TaskRating? rating,
}) => TaskEntity(
  id: id,
  title: '$title $id',
  description: '',
  priority: priority,
  status: status,
  dueDate: DateTime(2026, 11, 10 + dueInDays),
  assigneeId: assignee,
  assigneeName: assignee == null ? null : 'Eli',
  createdById: 'a1',
  createdByName: 'Asha',
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
  rating: rating,
);

void main() {
  group('TaskFilterCriteria', () {
    final tasks = [
      t('1', dueInDays: -2),
      t('2', status: TaskStatus.completed),
      t('3', priority: TaskPriority.urgent, dueInDays: 5, title: 'Invoice'),
      t('4', assignee: null, dueInDays: 3),
    ];

    test('quick filters', () {
      List<String> ids(TaskQuickFilter f) =>
          TaskFilterCriteria(quickFilter: f).apply(tasks, now).map((e) => e.id).toList();
      expect(ids(TaskQuickFilter.overdue), ['1']);
      expect(ids(TaskQuickFilter.completed), ['2']);
      expect(ids(TaskQuickFilter.open), ['1', '4', '3']);
      expect(ids(TaskQuickFilter.toRate), ['2']);
    });

    test('search, priority, assignee and sort', () {
      expect(const TaskFilterCriteria(query: 'invo').apply(tasks, now).single.id, '3');
      expect(const TaskFilterCriteria(priority: TaskPriority.urgent).apply(tasks, now).single.id, '3');
      expect(const TaskFilterCriteria(assigneeId: TaskFilterCriteria.unassigned).apply(tasks, now).single.id, '4');
      expect(
        const TaskFilterCriteria(sort: TaskSort.priority).apply(tasks, now).first.id,
        '3',
      );
    });
  });

  group('TaskListBloc', () {
    late MockWatchTasks watch;
    late StreamController<Either<Failure, List<TaskEntity>>> controller;

    setUpAll(() => registerFallbackValue(const TaskScope.all()));

    setUp(() {
      watch = MockWatchTasks();
      controller = StreamController();
      when(() => watch(parameters: any(named: 'parameters'))).thenAnswer((_) => controller.stream);
    });

    tearDown(() => controller.close());

    TaskListBloc build() => TaskListBloc(watchTasks: watch, scope: const TaskScope.assignedTo('e1'), clock: () => now);

    blocTest<TaskListBloc, TaskListState>(
      'streams tasks and applies the filter',
      build: build,
      act: (bloc) async {
        bloc.add(const TaskListSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        controller.add(Right([t('1', dueInDays: -1), t('2', status: TaskStatus.completed)]));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TaskListCriteriaChanged(TaskFilterCriteria(quickFilter: TaskQuickFilter.overdue)));
      },
      verify: (bloc) {
        expect(bloc.state.status, TaskListStatus.success);
        expect(bloc.state.tasks, hasLength(2));
        expect(bloc.state.visibleTasks.single.id, '1');
        verify(() => watch(parameters: const TaskScope.assignedTo('e1'))).called(1);
      },
    );

    blocTest<TaskListBloc, TaskListState>(
      'debounces search',
      build: build,
      act: (bloc) async {
        bloc.add(const TaskListSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        controller.add(Right([t('1', title: 'Alpha'), t('2', title: 'Beta')]));
        bloc
          ..add(const TaskListQueryChanged('al'))
          ..add(const TaskListQueryChanged('beta'));
      },
      wait: const Duration(milliseconds: 300),
      verify: (bloc) {
        expect(bloc.state.criteria.query, 'beta');
        expect(bloc.state.visibleTasks.single.id, '2');
      },
    );

    blocTest<TaskListBloc, TaskListState>(
      'surfaces stream failures',
      build: build,
      act: (bloc) async {
        bloc.add(const TaskListSubscriptionRequested());
        await Future<void>.delayed(Duration.zero);
        controller.add(Left(ForbiddenFailure()));
      },
      verify: (bloc) {
        expect(bloc.state.status, TaskListStatus.failure);
        expect(bloc.state.errorMessage, AppErrorMessages.forbidden);
      },
    );
  });
}
