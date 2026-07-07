import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/certificate.dart';

/// 证件仓库
class CertificateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Certificate cert) async {
    final db = await _dbHelper.database;
    return await db.insert('certificates', cert.toMap());
  }

  Future<int> update(Certificate cert) async {
    final db = await _dbHelper.database;
    return await db.update('certificates', cert.toMap(), where: 'id = ?', whereArgs: [cert.id]);
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('certificates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Certificate>> getAll({String? filter}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String? where;
    List<dynamic>? whereArgs;

    if (filter == 'expiring') {
      final future = now.add(const Duration(days: 30));
      final futureStr = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      where = 'expire_date IS NOT NULL AND expire_date >= ? AND expire_date <= ?';
      whereArgs = [nowStr, futureStr];
    } else if (filter == 'expired') {
      where = 'expire_date IS NOT NULL AND expire_date < ?';
      whereArgs = [nowStr];
    }

    final maps = await db.query(
      'certificates',
      where: where,
      whereArgs: whereArgs,
      orderBy: filter == null ? 'created_at DESC' : 'expire_date ASC',
    );
    return maps.map((m) => Certificate.fromMap(m)).toList();
  }

  /// 按人员获取证件
  Future<List<Certificate>> getByWorkerId(int workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'certificates',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'expire_date ASC',
    );
    return maps.map((m) => Certificate.fromMap(m)).toList();
  }

  /// 获取即将到期的证件数量
  Future<int> getExpiringCount(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final futureStr = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM certificates WHERE expire_date IS NOT NULL AND expire_date >= ? AND expire_date <= ?',
      [nowStr, futureStr],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
