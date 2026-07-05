import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/worker.dart';

class WorkerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Worker worker) async {
    final db = await _dbHelper.database;
    return await db.insert('workers', worker.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Worker worker) async {
    final db = await _dbHelper.database;
    return await db.update(
      'workers',
      worker.toMap(),
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Worker?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<Worker?> getByEmployeeNo(String employeeNo) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'employee_no = ?',
      whereArgs: [employeeNo],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Worker.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Worker>> getAll({String? status, String? department}) async {
    final db = await _dbHelper.database;

    String? where;
    List<dynamic>? whereArgs;

    if (status != null && department != null) {
      where = 'status = ? AND department = ?';
      whereArgs = [status, department];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    } else if (department != null) {
      where = 'department = ?';
      whereArgs = [department];
    }

    final maps = await db.query(
      'workers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => Worker.fromMap(m)).toList();
  }

  Future<List<Worker>> search(String keyword) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'workers',
      where: 'name LIKE ? OR employee_no LIKE ? OR phone LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Worker.fromMap(m)).toList();
  }

  Future<List<Worker>> getExpiringCertificates(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final futureStr =
        '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';

    final maps = await db.query(
      'workers',
      where:
          'certificate_expire_date IS NOT NULL AND certificate_expire_date <= ? AND status = ?',
      whereArgs: [futureStr, 'active'],
      orderBy: 'certificate_expire_date ASC',
    );
    return maps.map((m) => Worker.fromMap(m)).toList();
  }

  Future<int> getCount({String? status}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workers${status != null ? ' WHERE status = ?' : ''}',
      status != null ? [status] : null,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, int>> getStatsByDepartment() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT department, COUNT(*) as count FROM workers WHERE status = ? GROUP BY department',
      ['active'],
    );
    return {for (var r in result) r['department'] as String: r['count'] as int};
  }

  Future<Map<String, int>> getStatsByJobType() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT job_type, COUNT(*) as count FROM workers WHERE status = ? GROUP BY job_type',
      ['active'],
    );
    return {for (var r in result) r['job_type'] as String: r['count'] as int};
  }
}
