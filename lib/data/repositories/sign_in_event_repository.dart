import '../database/database_helper.dart';

/// 签到事项模型
class SignInEvent {
  final int? id;
  final String title;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  SignInEvent({
    this.id,
    required this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory SignInEvent.fromMap(Map<String, dynamic> map) {
    return SignInEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}

/// 签到事项统计信息
class SignInEventStats {
  final SignInEvent event;
  final int signedCount;
  final int unsignedCount;
  final int totalCount;

  SignInEventStats({
    required this.event,
    required this.signedCount,
    required this.unsignedCount,
    required this.totalCount,
  });
}

/// 签到事项 Repository
class SignInEventRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取所有签到事项（按创建时间降序）
  Future<List<SignInEvent>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sign_in_events',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SignInEvent.fromMap(m)).toList();
  }

  /// 获取单个签到事项
  Future<SignInEvent?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sign_in_events',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return SignInEvent.fromMap(maps.first);
    }
    return null;
  }

  /// 创建签到事项
  Future<int> insert(SignInEvent event) async {
    final db = await _dbHelper.database;
    return await db.insert('sign_in_events', {
      'title': event.title,
      'description': event.description,
    });
  }

  /// 删除签到事项（关联的签到记录因 CASCADE 自动删除）
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'sign_in_events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取签到事项及其统计（已签到/未签到人数）
  Future<SignInEventStats?> getWithStats(int eventId) async {
    final event = await getById(eventId);
    if (event == null) return null;

    final db = await _dbHelper.database;

    // 总在职人数
    final totalResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM workers WHERE status = 'active'",
    );
    final totalCount = totalResult.first['count'] as int;

    // 已签到人数
    final signedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sign_in_records WHERE event_id = ?',
      [eventId],
    );
    final signedCount = signedResult.first['count'] as int;

    return SignInEventStats(
      event: event,
      signedCount: signedCount,
      unsignedCount: totalCount - signedCount,
      totalCount: totalCount,
    );
  }
}

/// 签到记录模型
class SignInRecord {
  final int? id;
  final int eventId;
  final int workerId;
  final String? signedAt;

  SignInRecord({
    this.id,
    required this.eventId,
    required this.workerId,
    this.signedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'worker_id': workerId,
      'signed_at': signedAt,
    };
  }

  factory SignInRecord.fromMap(Map<String, dynamic> map) {
    return SignInRecord(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      workerId: map['worker_id'] as int,
      signedAt: map['signed_at'] as String?,
    );
  }
}

/// 签到记录 Repository
class SignInRecordRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取某签到事项的所有签到记录
  Future<List<SignInRecord>> getByEvent(int eventId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sign_in_records',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'signed_at DESC',
    );
    return maps.map((m) => SignInRecord.fromMap(m)).toList();
  }

  /// 切换签到状态：已签到则取消，未签到则签到
  Future<bool> toggleSign(int eventId, int workerId) async {
    final db = await _dbHelper.database;

    // 检查是否已签到
    final existing = await db.query(
      'sign_in_records',
      where: 'event_id = ? AND worker_id = ?',
      whereArgs: [eventId, workerId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 已签到，取消签到
      await db.delete(
        'sign_in_records',
        where: 'event_id = ? AND worker_id = ?',
        whereArgs: [eventId, workerId],
      );
      return false;
    } else {
      // 未签到，执行签到
      await db.insert('sign_in_records', {
        'event_id': eventId,
        'worker_id': workerId,
      });
      return true;
    }
  }

  /// 批量签到
  Future<int> batchSign(int eventId, List<int> workerIds) async {
    final db = await _dbHelper.database;
    int count = 0;

    for (final workerId in workerIds) {
      await db.execute(
        'INSERT OR IGNORE INTO sign_in_records (event_id, worker_id) VALUES (?, ?)',
        [eventId, workerId],
      );
      count++;
    }
    return count;
  }

  /// 获取已签到人员 ID 列表
  Future<List<int>> getSignedWorkers(int eventId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sign_in_records',
      columns: ['worker_id'],
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return maps.map((m) => m['worker_id'] as int).toList();
  }

  /// 获取未签到人员 ID 列表
  Future<List<int>> getUnsignedWorkers(int eventId) async {
    final db = await _dbHelper.database;

    final maps = await db.rawQuery('''
      SELECT w.id FROM workers w
      WHERE w.status = 'active'
      AND w.id NOT IN (
        SELECT worker_id FROM sign_in_records WHERE event_id = ?
      )
    ''', [eventId]);

    return maps.map((m) => m['id'] as int).toList();
  }
}
