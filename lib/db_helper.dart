import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:task_rq/task.dart';

class TasksDBHelper {
  static const String _databaseName = 'tasks.db';
  static const String _tableName = 'tasks';

  static Future<Database> getDatabase() async {
    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, _databaseName);

    return await openDatabase(
      fullPath,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            date TEXT NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }

  static Future<void> insertTask(Task task) async {
    final db = await getDatabase();
    await db.insert(_tableName, task.toMap());
  }

  static Future<List<Task>> getTasks() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<int> updateTask(Task task) async {
    final db = await getDatabase();
    return await db.update(
      _tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<void> deleteTask(Task task) async {
    final db = await getDatabase();
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }
}