import '../database/database_helper.dart';

/// 排班配置模型
class ScheduleConfig {
  final int? id;
  final String name;
  final String? shiftPattern;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  ScheduleConfig({
    this.id,
    required this.name,
    this.shiftPattern,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shift_pattern': shiftPattern,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ScheduleConfig.fromMap(Map<String, dynamic> map) {
    return ScheduleConfig(
      id: map['id'] as int?,
      name: map['name'] as String,
      shiftPattern: map['shift_pattern'] as String?,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}

/// 排班配置 Repository
class ScheduleConfigRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取所有排班配置（应返回2个：班组A和班组B）
  Future<List<ScheduleConfig>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_config',
      orderBy: 'id ASC',
    );
    return maps.map((m) => ScheduleConfig.fromMap(m)).toList();
  }

  /// 更新配置
  Future<int> update(ScheduleConfig config) async {
    final db = await _dbHelper.database;
    return await db.update(
      'schedule_config',
      {
        'name': config.name,
        'shift_pattern': config.shiftPattern,
        'description': config.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  /// 获取单个配置
  Future<ScheduleConfig?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_config',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ScheduleConfig.fromMap(maps.first);
    }
    return null;
  }
}
