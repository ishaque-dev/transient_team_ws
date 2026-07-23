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
        // Create tasks table
        await db.execute('''CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          priority TEXT NOT NULL,
          dueDate TEXT NOT NULL,
          status TEXT NOT NULL,
          assignedUserId TEXT
        )''');

        // Add index for status and priority for faster filtering
        await db.execute(
          '''CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);''',
        );
        await db.execute(
          '''CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);''',
        );
      },
    );
  }
}
