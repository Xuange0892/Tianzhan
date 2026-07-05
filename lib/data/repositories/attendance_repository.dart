import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Attendance attendance) async {
    final db = await _dbHelper.database;
    return await db.insert('attendance', attendance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Attendance attendance) async {
    final db = await _dbHelper.database;
    return await db.update(
      'attendance',
      attendance.toMap(),
      where: 'id = ?',
      whereArgs: [attendance.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Attendance?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Attendance.fromMap(maps.first);
    }
    return null;
  }

  Future<Attendance?> getByWorkerAndDate(int workerId, String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'attendance',
      where: 'worker_id = ? AND date = ?',
      whereArgs: [workerId, date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Attendance.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Attendance>> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Attendance.fromMap(m)).toList();
  }

  Future<List<Attendance>> getByWorker(int workerId,
      {String? startDate, String? endDate}) async {
    final db = await _dbHelper.database;

    String? where = 'worker_id = ?';
    List<dynamic> whereArgs = [workerId];

    if (startDate != null && endDate != null) {
      where += ' AND date >= ? AND date <= ?';
      whereArgs.addAll([startDate, endDate]);
    }

    final maps = await db.query(
      'attendance',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((m) => Attendance.fromMap(m)).toList();
  }

  Future<List<Attendance>> getByDateRange(String startDate, String endDate,
      {String? status}) async {
    final db = await _dbHelper.database;

    String? where = 'date >= ? AND date <= ?';
    List<dynamic> whereArgs = [startDate, endDate];

    if (status != null) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query(
      'attendance',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => Attendance.fromMap(m)).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyStats(String date) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM attendance 
      WHERE date = ? 
      GROUP BY status
    ''', [date]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(
      String year, String month) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT worker_id, 
        COUNT(*) as total_days,
        SUM(CASE WHEN status = 'normal' THEN 1 ELSE 0 END) as normal_days,
        SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late_days,
        SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_days,
        SUM(CASE WHEN status = 'leave' THEN 1 ELSE 0 END) as leave_days,
        SUM(work_hours) as total_hours
      FROM attendance 
      WHERE date LIKE ? 
      GROUP BY worker_id
    ''', ['$year-$month%']);
    return result;
  }

  Future<int> batchInsert(List<Attendance> attendances) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final a in attendances) {
        await txn.insert('attendance', a.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    });
    return count;
  }
}
