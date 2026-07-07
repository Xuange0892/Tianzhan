import '../database/database_helper.dart';

/// 管理人员排班模型
class ManagerSchedule {
  final int? id;
  final String date;
  final String managerName;
  final String? position;
  final String? shiftType;
  final String? remark;
  final String? createdAt;

  ManagerSchedule({
    this.id,
    required this.date,
    required this.managerName,
    this.position,
    this.shiftType,
    this.remark,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'manager_name': managerName,
      'position': position,
      'shift_type': shiftType,
      'remark': remark,
      'created_at': createdAt,
    };
  }

  factory ManagerSchedule.fromMap(Map<String, dynamic> map) {
    return ManagerSchedule(
      id: map['id'] as int?,
      date: map['date'] as String,
      managerName: map['manager_name'] as String,
      position: map['position'] as String?,
      shiftType: map['shift_type'] as String?,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }
}

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
      orderBy: 'manager_name ASC',
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
      orderBy: 'date ASC, manager_name ASC',
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
