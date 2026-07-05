import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Schedule schedule) async {
    final db = await _dbHelper.database;
    return await db.insert('schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Schedule schedule) async {
    final db = await _dbHelper.database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByDateAndWorker(String date, int workerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'schedules',
      where: 'date = ? AND worker_id = ?',
      whereArgs: [date, workerId],
    );
  }

  Future<Schedule?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Schedule.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Schedule>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'shift_type ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<List<Schedule>> getByDateAndShift(String date, String shiftType) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'date = ? AND shift_type = ?',
      whereArgs: [date, shiftType],
      orderBy: 'is_duty_leader DESC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<List<Schedule>> getByWorker(int workerId,
      {String? startDate, String? endDate}) async {
    final db = await _dbHelper.database;

    String? where = 'worker_id = ?';
    List<dynamic> whereArgs = [workerId];

    if (startDate != null && endDate != null) {
      where += ' AND date >= ? AND date <= ?';
      whereArgs.addAll([startDate, endDate]);
    }

    final maps = await db.query(
      'schedules',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<List<Schedule>> getByMonth(String yearMonth) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC, shift_type ASC',
    );
    return maps.map((m) => Schedule.fromMap(m)).toList();
  }

  Future<bool> hasSchedule(String date, int workerId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM schedules WHERE date = ? AND worker_id = ?',
      [date, workerId],
    );
    return (result.first['count'] as int) > 0;
  }

  Future<int> batchInsert(List<Schedule> schedules) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final s in schedules) {
        await txn.insert('schedules', s.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    });
    return count;
  }

  Future<Map<String, int>> getShiftStatsByMonth(String yearMonth) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT shift_type, COUNT(*) as count 
      FROM schedules 
      WHERE date LIKE ? 
      GROUP BY shift_type
    ''', ['$yearMonth%']);
    return {
      for (var r in result) r['shift_type'] as String: r['count'] as int
    };
  }
}
