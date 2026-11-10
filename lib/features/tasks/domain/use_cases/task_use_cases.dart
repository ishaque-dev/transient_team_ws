import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/common_failures.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/usecase/use_case.dart';
import 'package:transient_team_ws/core/utils/date_time_utils.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_activity_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_filter.dart';
import 'package:transient_team_ws/features/tasks/domain/repository/i_task_repo.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_change_builder.dart';
import 'package:uuid/uuid.dart';

Failure _forbidden() =>
    ForbiddenFailure(message: 'Only admins can perform this action.');

class WatchTasksUseCase implements UseCaseStream<List<TaskEntity>, TaskScope> {
  WatchTasksUseCase(this.repository);
  final ITaskRepo repository;

  @override
  Stream<Either<Failure, List<TaskEntity>>> call({
    required TaskScope parameters,
  }) {
    return repository.watchTasks(parameters);
  }
}

class WatchTaskActivityUseCase
    implements UseCaseStream<List<TaskActivityEntity>, String> {
  WatchTaskActivityUseCase(this.repository);
  final ITaskRepo repository;

  @override
  Stream<Either<Failure, List<TaskActivityEntity>>> call({
    required String parameters,
  }) {
    return repository.watchActivity(parameters);
  }
}

class CreateTaskParams extends Equatable {
  const CreateTaskParams({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.actor,
    this.assignee,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final UserEntity? assignee;
  final UserEntity actor;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    dueDate,
    assignee,
    actor,
  ];
}

class CreateTaskUseCase implements UseCase<TaskEntity, CreateTaskParams> {
  CreateTaskUseCase(this.repository, {this.uuid = const Uuid()});
  final ITaskRepo repository;
  final Uuid uuid;

  @override
  Future<Either<Failure, TaskEntity>> call({
    required CreateTaskParams parameters,
  }) async {
    final p = parameters;
    if (!p.actor.isAdmin) return Left(_forbidden());
    final title = p.title.trim();
    if (title.isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a task title.'));
    }

    final change = TaskChangeBuilder(actor: p.actor, uuid: uuid);
    final task = TaskEntity(
      id: uuid.v4(),
      title: title,
      description: p.description.trim(),
      priority: p.priority,
      status: TaskStatus.todo,
      dueDate: dateOnly(p.dueDate),
      assigneeId: p.assignee?.id,
      assigneeName: p.assignee?.displayName,
      createdById: p.actor.id,
      createdByName: p.actor.displayName,
      createdAt: change.now,
      updatedAt: change.now,
    );

    final assignee = p.assignee;
    final result = await repository.createTask(
      task,
      activities: [
        change.activity(
          TaskActivityType.created,
          assignee == null
              ? 'created this task'
              : 'created this task and assigned it to ${assignee.displayName}',
        ),
      ],
      notifications: change.notify(
        task,
        NotificationType.taskAssigned,
        'assigned you ${quoted(title)}',
      ),
    );
    return result.map((_) => task);
  }
}

class UpdateTaskParams extends Equatable {
  const UpdateTaskParams({
    required this.original,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.actor,
    this.assignee,
  });

  final TaskEntity original;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final UserEntity? assignee;
  final UserEntity actor;

  @override
  List<Object?> get props => [
    original,
    title,
    description,
    priority,
    status,
    dueDate,
    assignee,
    actor,
  ];
}

class UpdateTaskUseCase implements UseCase<TaskEntity, UpdateTaskParams> {
  UpdateTaskUseCase(this.repository, {this.uuid = const Uuid()});
  final ITaskRepo repository;
  final Uuid uuid;

  @override
  Future<Either<Failure, TaskEntity>> call({
    required UpdateTaskParams parameters,
  }) async {
    final p = parameters;
    final original = p.original;
    if (!p.actor.isAdmin) return Left(_forbidden());
    final title = p.title.trim();
    if (title.isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a task title.'));
    }

    final change = TaskChangeBuilder(actor: p.actor, uuid: uuid);
    final dueDate = dateOnly(p.dueDate);
    final description = p.description.trim();
    final statusChanged = p.status != original.status;
    final assigneeChanged = p.assignee?.id != original.assigneeId;

    final edited = <String>[
      if (title != original.title) 'title',
      if (description != original.description) 'description',
      if (p.priority != original.priority) 'priority',
      if (calendarDaysBetween(original.dueDate, dueDate) != 0) 'due date',
    ];
    if (edited.isEmpty && !statusChanged && !assigneeChanged) {
      return Right(original);
    }

    final updated = original.copyWith(
      title: title,
      description: description,
      priority: p.priority,
      status: p.status,
      dueDate: dueDate,
      assigneeId: () => p.assignee?.id,
      assigneeName: () => p.assignee?.displayName,
      updatedAt: change.now,
      completedAt: () => !statusChanged
          ? original.completedAt
          : (p.status == TaskStatus.completed ? change.now : null),
    );

    final activities = <TaskActivityEntity>[
      if (assigneeChanged)
        change.activity(
          TaskActivityType.assigned,
          p.assignee == null
              ? 'removed the assignee'
              : 'assigned this task to ${p.assignee!.displayName}',
        ),
      if (statusChanged)
        change.activity(
          TaskActivityType.statusChanged,
          'changed the status to ${p.status.label}',
          toStatus: p.status,
        ),
      if (edited.isNotEmpty)
        change.activity(
          TaskActivityType.edited,
          'updated the ${_joinFields(edited)}',
        ),
    ];

    final notifications = <AppNotificationEntity>[
      if (assigneeChanged && p.assignee != null)
        ...change.notify(
          updated,
          NotificationType.taskAssigned,
          'assigned you ${quoted(title)}',
          recipient: p.assignee!.id,
        )
      else if (!assigneeChanged)
        ...change.notify(
          updated,
          statusChanged
              ? NotificationType.statusChanged
              : NotificationType.taskUpdated,
          statusChanged
              ? 'moved ${quoted(title)} to ${p.status.label}'
              : 'updated the ${_joinFields(edited)} of ${quoted(title)}',
        ),
    ];

    final result = await repository.updateTask(
      updated,
      activities: activities,
      notifications: notifications,
    );
    return result.map((_) => updated);
  }

  static String _joinFields(List<String> fields) {
    if (fields.length == 1) return fields.first;
    return '${fields.sublist(0, fields.length - 1).join(', ')} and ${fields.last}';
  }
}

class ChangeTaskStatusParams extends Equatable {
  const ChangeTaskStatusParams({
    required this.task,
    required this.status,
    required this.actor,
  });

  final TaskEntity task;
  final TaskStatus status;
  final UserEntity actor;

  @override
  List<Object?> get props => [task, status, actor];
}

class ChangeTaskStatusUseCase implements UseCase<Unit, ChangeTaskStatusParams> {
  ChangeTaskStatusUseCase(this.repository, {this.uuid = const Uuid()});
  final ITaskRepo repository;
  final Uuid uuid;

  @override
  Future<Either<Failure, Unit>> call({
    required ChangeTaskStatusParams parameters,
  }) async {
    final p = parameters;
    if (p.status == p.task.status) return const Right(unit);
    if (!p.actor.isAdmin && p.task.assigneeId != p.actor.id) {
      return Left(
        ForbiddenFailure(message: 'You can only update tasks assigned to you.'),
      );
    }

    final change = TaskChangeBuilder(actor: p.actor, uuid: uuid);
    final done = p.status == TaskStatus.completed;
    return repository.updateStatus(
      p.task.id,
      p.status,
      activities: [
        change.activity(
          TaskActivityType.statusChanged,
          done
              ? 'marked this task as completed'
              : 'changed the status to ${p.status.label}',
          toStatus: p.status,
        ),
      ],
      notifications: change.notify(
        p.task,
        NotificationType.statusChanged,
        done
            ? 'completed ${quoted(p.task.title)}'
            : 'moved ${quoted(p.task.title)} to ${p.status.label}',
      ),
    );
  }
}

class RateTaskParams extends Equatable {
  const RateTaskParams({
    required this.task,
    required this.quality,
    required this.timeliness,
    required this.actor,
    this.note,
  });

  final TaskEntity task;
  final int quality;
  final int timeliness;
  final String? note;
  final UserEntity actor;

  @override
  List<Object?> get props => [task, quality, timeliness, note, actor];
}

class RateTaskUseCase implements UseCase<TaskRating, RateTaskParams> {
  RateTaskUseCase(this.repository, {this.uuid = const Uuid()});
  final ITaskRepo repository;
  final Uuid uuid;

  @override
  Future<Either<Failure, TaskRating>> call({
    required RateTaskParams parameters,
  }) async {
    final p = parameters;
    if (!p.actor.isAdmin) return Left(_forbidden());
    if (!p.task.isCompleted) {
      return Left(
        ValidationFailure(message: 'Only completed tasks can be rated.'),
      );
    }
    bool inRange(int value) => value >= 1 && value <= 5;
    if (!inRange(p.quality) || !inRange(p.timeliness)) {
      return Left(ValidationFailure(message: 'Ratings must be 1 to 5 stars.'));
    }

    final change = TaskChangeBuilder(actor: p.actor, uuid: uuid);
    final note = p.note?.trim();
    final rating = TaskRating(
      quality: p.quality,
      timeliness: p.timeliness,
      note: (note == null || note.isEmpty) ? null : note,
      ratedById: p.actor.id,
      ratedByName: p.actor.displayName,
      ratedAt: change.now,
    );
    final stars = rating.overall.toStringAsFixed(1);
    final result = await repository.rateTask(
      p.task.id,
      rating,
      activities: [
        change.activity(
          TaskActivityType.rated,
          'rated this work $stars★ '
          '(quality ${p.quality}/5, deadline ${p.timeliness}/5)',
        ),
      ],
      notifications: change.notify(
        p.task,
        NotificationType.rated,
        'rated your work on ${quoted(p.task.title)} $stars★',
      ),
    );
    return result.map((_) => rating);
  }
}

class AddTaskCommentParams extends Equatable {
  const AddTaskCommentParams({
    required this.task,
    required this.message,
    required this.actor,
  });

  final TaskEntity task;
  final String message;
  final UserEntity actor;

  @override
  List<Object?> get props => [task, message, actor];
}

class AddTaskCommentUseCase implements UseCase<Unit, AddTaskCommentParams> {
  AddTaskCommentUseCase(this.repository, {this.uuid = const Uuid()});
  final ITaskRepo repository;
  final Uuid uuid;

  @override
  Future<Either<Failure, Unit>> call({
    required AddTaskCommentParams parameters,
  }) async {
    final p = parameters;
    final text = p.message.trim();
    if (text.isEmpty) {
      return Left(ValidationFailure(message: 'Write a comment first.'));
    }
    final change = TaskChangeBuilder(actor: p.actor, uuid: uuid);
    final preview = text.length > 80 ? '${text.substring(0, 77)}…' : text;
    return repository.addComment(
      p.task.id,
      comment: change.activity(TaskActivityType.comment, text),
      notifications: change.notify(
        p.task,
        NotificationType.comment,
        'commented on ${quoted(p.task.title)}: $preview',
      ),
    );
  }
}

class DeleteTaskParams extends Equatable {
  const DeleteTaskParams({required this.taskId, required this.actor});

  final String taskId;
  final UserEntity actor;

  @override
  List<Object?> get props => [taskId, actor];
}

class DeleteTaskUseCase implements UseCase<Unit, DeleteTaskParams> {
  DeleteTaskUseCase(this.repository);
  final ITaskRepo repository;

  @override
  Future<Either<Failure, Unit>> call({required DeleteTaskParams parameters}) {
    if (!parameters.actor.isAdmin) return Future.value(Left(_forbidden()));
    return repository.deleteTask(parameters.taskId);
  }
}
