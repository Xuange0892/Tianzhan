import '../database/database_helper.dart';

/// 休息日模型
class RestDay {
  final int? id;
  final String date;
  final String? reason;
  final String? createdAt;

  RestDay({
    this.id,
    required this.date,
    this.reason,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory RestDay.fromMap(Map<String, dynamic> map) {
    return RestDay(
      id: map['id'] as int?,
      date: map['date'] as String,
      reason: map['reason'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

/// 休息日 Repository
class RestDayRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取所有休息日
  Future<List<RestDay>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rest_days',
      orderBy: 'date ASC',
    );
    return maps.map((m) => RestDay.fromMap(m)).toList();
  }

  /// 获取某日休息日记录
  Future<RestDay?> getByDate(String date) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rest_days',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return RestDay.fromMap(maps.first);
    }
    return null;
  }

  /// 获取某月所有休息日
  /// [yearMonth] 格式如 "2024-01"
  Future<List<RestDay>> getByMonth(String yearMonth) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'rest_days',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC',
    );
    return maps.map((m) => RestDay.fromMap(m)).toList();
  }

  /// 添加休息日
  Future<int> add(String date, String? reason) async {
    final db = await _dbHelper.database;
    return await db.insert('rest_days', {
      'date': date,
      'reason': reason,
    });
  }

  /// 删除休息日
  Future<int> remove(String date) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'rest_days',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  /// 判断某日是否为休息日
  Future<bool> isRestDay(String date) async {
    final result = await getByDate(date);
    return result != null;
  }
}
