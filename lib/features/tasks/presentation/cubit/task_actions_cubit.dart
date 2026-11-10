import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:transient_team_ws/core/error/failure.dart';
import 'package:transient_team_ws/core/utils/action_feedback.dart';
import 'package:transient_team_ws/features/auth/domain/entities/user_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/entities/task_entity.dart';
import 'package:transient_team_ws/features/tasks/domain/use_cases/task_use_cases.dart';

/// Task mutations for the signed-in user. Each method resolves to `true` on
/// success so screens can close themselves; outcomes are also emitted as
/// [ActionFeedback] for a single snackbar listener.
class TaskActionsCubit extends Cubit<ActionFeedback?> {
  TaskActionsCubit({
    required this.actor,
    required this._createTask,
    required this._updateTask,
    required this._changeStatus,
    required this._rateTask,
    required this._addComment,
    required this._deleteTask,
  }) : super(null);

  final UserEntity actor;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final ChangeTaskStatusUseCase _changeStatus;
  final RateTaskUseCase _rateTask;
  final AddTaskCommentUseCase _addComment;
  final DeleteTaskUseCase _deleteTask;
  int _serial = 0;

  Future<bool> create({
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    UserEntity? assignee,
  }) {
    return _handle(
      _createTask(
        parameters: CreateTaskParams(
          title: title,
          description: description,
          priority: priority,
          dueDate: dueDate,
          assignee: assignee,
          actor: actor,
        ),
      ),
      success: 'Task created',
    );
  }

  Future<bool> update({
    required TaskEntity original,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
    required DateTime dueDate,
    UserEntity? assignee,
  }) {
    return _handle(
      _updateTask(
        parameters: UpdateTaskParams(
          original: original,
          title: title,
          description: description,
          priority: priority,
          status: status,
          dueDate: dueDate,
          assignee: assignee,
          actor: actor,
        ),
      ),
      success: 'Task updated',
    );
  }

  Future<bool> changeStatus(TaskEntity task, TaskStatus status) {
    return _handle(
      _changeStatus(
        parameters: ChangeTaskStatusParams(
          task: task,
          status: status,
          actor: actor,
        ),
      ),
      success: status == TaskStatus.completed
          ? 'Marked “${task.title}” as completed'
          : 'Moved to ${status.label}',
    );
  }

  Future<bool> rate(
    TaskEntity task, {
    required int quality,
    required int timeliness,
    String? note,
  }) {
    return _handle(
      _rateTask(
        parameters: RateTaskParams(
          task: task,
          quality: quality,
          timeliness: timeliness,
          note: note,
          actor: actor,
        ),
      ),
      success: 'Rating saved',
    );
  }

  Future<bool> comment(TaskEntity task, String message) {
    return _handle(
      _addComment(
        parameters: AddTaskCommentParams(
          task: task,
          message: message,
          actor: actor,
        ),
      ),
    );
  }

  Future<bool> delete(TaskEntity task) {
    return _handle(
      _deleteTask(
        parameters: DeleteTaskParams(taskId: task.id, actor: actor),
      ),
      success: 'Task deleted',
    );
  }

  Future<bool> _handle<T>(
    Future<Either<Failure, T>> call, {
    String? success,
  }) async {
    final result = await call;
    if (isClosed) return result.isRight();
    return result.fold(
      (failure) {
        emit(ActionFeedback(failure.message, isError: true, serial: ++_serial));
        return false;
      },
      (_) {
        if (success != null) {
          emit(ActionFeedback(success, serial: ++_serial));
        }
        return true;
      },
    );
  }
}
