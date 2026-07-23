import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transient_team_ws/core/constants/app_strings.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDb();
    return _database!;
  }

  Future<Database> _openDb() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, AppStrings.dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Create tasks table with TEXT primary key for UUIDs
    await db.execute('''CREATE TABLE tasks(
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      priority TEXT NOT NULL,
      dueDate TEXT NOT NULL,
      status TEXT NOT NULL,
      assignedUserId TEXT
    )''');

    // Add indices for performance
    await db.execute(
      '''CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);''',
    );
    await db.execute(
      '''CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);''',
    );
    await db.execute(
      '''CREATE INDEX IF NOT EXISTS idx_tasks_title ON tasks(title);''',
    );
  }
}
