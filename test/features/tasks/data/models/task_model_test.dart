import 'package:flutter_test/flutter_test.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_enum_model.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';

void main() {
  final tDateTime = DateTime(2023, 10, 27, 12, 30);
  final tTaskEntity = TaskEntity(
    id: 'uuid-1',
    title: 'Test Task',
    description: 'Test Description',
    priority: TaskPriority.high,
    dueDate: tDateTime,
    status: TaskStatus.pending,
    assignedUserId: 'user123',
  );

  final tTaskModel = TaskModel(
    id: 'uuid-1',
    title: 'Test Task',
    description: 'Test Description',
    priority: TaskPriorityModel.high,
    dueDate: tDateTime.toIso8601String(),
    status: TaskStatusModel.pending,
    assignedUserId: 'user123',
  );

  group('toEntity', () {
    test('should return a valid TaskEntity from TaskModel', () {
      // act
      final result = tTaskModel.toEntity();
      // assert
      expect(result, tTaskEntity);
    });
  });

  group('fromEntity', () {
    test('should return a valid TaskModel from TaskEntity', () {
      // act
      final result = TaskModel.fromEntity(tTaskEntity);
      // assert
      expect(result.id, tTaskModel.id);
      expect(result.title, tTaskModel.title);
      expect(result.priority, tTaskModel.priority);
      expect(result.status, tTaskModel.status);
    });
  });

  group('fromJson / toJson', () {
    test('should return a valid model from JSON', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'uuid-1',
        'title': 'Test Task',
        'description': 'Test Description',
        'priority': 'high',
        'dueDate': tDateTime.toIso8601String(),
        'status': 'pending',
        'assignedUserId': 'user123',
      };
      final result = TaskModel.fromJson(jsonMap);
      expect(result.title, 'Test Task');
      expect(result.priority, TaskPriorityModel.high);
    });

    test('should return a JSON map containing proper data', () {
      final result = tTaskModel.toJson();
      expect(result['id'], 'uuid-1');
      expect(result['priority'], 'high');
    });
  });

  group('Enum Mappers', () {
    test('TaskPriorityModel from/to Domain', () {
      expect(
        TaskPriorityModel.fromDomain(TaskPriority.low),
        TaskPriorityModel.low,
      );
      expect(TaskPriorityModel.low.toDomain(), TaskPriority.low);
    });

    test('TaskStatusModel from/to Domain', () {
      expect(
        TaskStatusModel.fromDomain(TaskStatus.completed),
        TaskStatusModel.completed,
      );
      expect(TaskStatusModel.completed.toDomain(), TaskStatus.completed);
    });
  });
}
