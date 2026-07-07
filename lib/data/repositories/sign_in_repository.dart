import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/sign_in_event.dart';
import '../models/worker.dart';
import 'worker_repository.dart';

/// 签到事项 & 签到记录 仓库
class SignInRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final WorkerRepository _workerRepo = WorkerRepository();

  // ---- 签到事项 CRUD ----

  Future<int> insertEvent(SignInEvent event) async {
    final db = await _dbHelper.database;
    return await db.insert('sign_in_events', event.toMap());
  }

  Future<int> deleteEvent(int eventId) async {
    final db = await _dbHelper.database;
    // 先删除关联记录
    await db.delete('sign_in_records', where: 'event_id = ?', whereArgs: [eventId]);
    return await db.delete('sign_in_events', where: 'id = ?', whereArgs: [eventId]);
  }

  Future<List<SignInEvent>> getAllEvents() async {
    final db = await _dbHelper.database;
    final maps = await db.query('sign_in_events', orderBy: 'created_at DESC');
    return maps.map((m) => SignInEvent.fromMap(m)).toList();
  }

  Future<SignInEvent?> getEventById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('sign_in_events', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) return SignInEvent.fromMap(maps.first);
    return null;
  }

  // ---- 签到记录 CRUD ----

  /// 批量创建签到记录（为指定事项的每个参与人员创建记录）
  Future<void> createRecordsForEvent(int eventId, List<int> workerIds) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final wid in workerIds) {
      batch.insert('sign_in_records', {
        'event_id': eventId,
        'worker_id': wid,
        'signed_in': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// 切换某个人员的签到状态
  Future<void> toggleSignIn(int eventId, int workerId, bool signedIn) async {
    final db = await _dbHelper.database;
    await db.update(
      'sign_in_records',
      {
        'signed_in': signedIn ? 1 : 0,
        'signed_at': signedIn ? DateTime.now().toIso8601String() : null,
      },
      where: 'event_id = ? AND worker_id = ?',
      whereArgs: [eventId, workerId],
    );
  }

  /// 全选/取消全选
  Future<void> toggleAll(int eventId, bool signedIn) async {
    final db = await _dbHelper.database;
    await db.update(
      'sign_in_records',
      {
        'signed_in': signedIn ? 1 : 0,
        'signed_at': signedIn ? DateTime.now().toIso8601String() : null,
      },
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  /// 获取某个签到事项的所有签到记录（含人员信息）
  Future<List<SignInRecord>> getRecordsByEvent(int eventId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT r.*, w.name as worker_name, w.employee_no as employee_no
      FROM sign_in_records r
      LEFT JOIN workers w ON r.worker_id = w.id
      WHERE r.event_id = ?
      ORDER BY w.name ASC
    ''', [eventId]);
    return maps.map((m) => SignInRecord(
      id: m['id'] as int?,
      eventId: m['event_id'] as int,
      workerId: m['worker_id'] as int,
      signedIn: (m['signed_in'] as int?) == 1,
      signedAt: m['signed_at'] as String?,
      createdAt: m['created_at'] as String?,
      workerName: m['worker_name'] as String?,
      workerEmployeeNo: m['employee_no'] as String?,
    )).toList();
  }

  /// 获取签到统计
  Future<Map<String, int>> getEventStats(int eventId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN signed_in = 1 THEN 1 ELSE 0 END) as signed,
        SUM(CASE WHEN signed_in = 0 THEN 1 ELSE 0 END) as unsigned
      FROM sign_in_records WHERE event_id = ?
    ''', [eventId]);
    if (result.isEmpty) return {'total': 0, 'signed': 0, 'unsigned': 0};
    return {
      'total': (result.first['total'] as int?) ?? 0,
      'signed': (result.first['signed'] as int?) ?? 0,
      'unsigned': (result.first['unsigned'] as int?) ?? 0,
    };
  }
}
