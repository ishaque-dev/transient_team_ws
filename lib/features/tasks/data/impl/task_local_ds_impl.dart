import 'package:sqflite/sqflite.dart';
import 'package:transient_team_ws/core/database/db.dart';
import 'package:transient_team_ws/features/tasks/data/data_sources/i_task_local_ds.dart';
import 'package:transient_team_ws/features/tasks/data/models/task_model.dart';

class TaskLocalDsImpl implements ITaskLocalDs {
  final DatabaseHelper _dbHelper;

  TaskLocalDsImpl(this._dbHelper);

  @override
  Future<List<TaskModel>> getTasks({
    int offset = 0,
    int limit = 10,
    String? query,
    String? status,
    String? priority,
  }) async {
    final db = await _dbHelper.database;
    
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClauses.add('title LIKE ?');
      whereArgs.add('%$query%');
    }

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    if (priority != null) {
      whereClauses.add('priority = ?');
      whereArgs.add(priority);
    }

    final String? where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'dueDate ASC',
    );

    return List.generate(maps.length, (i) {
      return TaskModel.fromJson(maps[i]);
    });
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return TaskModel.fromJson(maps.first);
  }

  @override
  Future<void> insertTask(TaskModel task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final db = await _dbHelper.database;
    await db.update(
      'tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert(
        'tasks',
        task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
