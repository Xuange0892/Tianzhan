import '../database/database_helper.dart';
import '../models/manager_schedule.dart';

/// 管理人员排班 Repository
class ManagerScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取某日管理人员排班
  Future<List<ManagerSchedule>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'manager_schedules',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ManagerSchedule.fromMap(m)).toList();
  }

  /// 获取日期范围内排班
  Future<List<ManagerSchedule>> getByDateRange(String start, String end) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'manager_schedules',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ManagerSchedule.fromMap(m)).toList();
  }

  /// 按月份获取排班记录
  Future<List<ManagerSchedule>> getByMonth(String yearMonth) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'manager_schedules',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ManagerSchedule.fromMap(m)).toList();
  }

  /// 添加排班记录
  Future<int> insert(ManagerSchedule schedule) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'manager_schedules',
      schedule.toMap(),
    );
  }

  /// 删除排班记录
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'manager_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量导入排班记录
  /// 返回成功导入的记录数
  Future<int> batchImport(List<ManagerSchedule> records) async {
    final db = await _dbHelper.database;
    int count = 0;

    for (final record in records) {
      try {
        await db.insert(
          'manager_schedules',
          record.toMap(),
        );
        count++;
      } catch (_) {
        // 跳过重复记录（UNIQUE 约束）
      }
    }

    return count;
  }
}
