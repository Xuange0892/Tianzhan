import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/todo.dart';

/// 待办事项仓库
class TodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.insert('todos', todo.toMap());
  }

  Future<int> update(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  /// 切换完成状态
  Future<void> toggleCompleted(int id, bool completed) async {
    final db = await _dbHelper.database;
    await db.update(
      'todos',
      {
        'is_completed': completed ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取待办列表（可筛选）
  Future<List<Todo>> getAll({String? filter}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;

    if (filter == 'pending') {
      where = 'is_completed = 0';
    } else if (filter == 'completed') {
      where = 'is_completed = 1';
    }

    final maps = await db.query(
      'todos',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'is_completed ASC, due_date ASC, created_at DESC',
    );
    return maps.map((m) => Todo.fromMap(m)).toList();
  }

  /// 获取未完成且即将到期的待办数量
  Future<int> getPendingCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE is_completed = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// 获取未完成的前N条待办（按截止日期排序）
  Future<List<Todo>> getPendingTop(int limit) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todos',
      where: 'is_completed = 0',
      orderBy: 'due_date ASC, created_at DESC',
      limit: limit,
    );
    return maps.map((m) => Todo.fromMap(m)).toList();
  }
}
