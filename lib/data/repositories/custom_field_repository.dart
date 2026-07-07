import '../database/database_helper.dart';

/// 自定义字段模型
class CustomField {
  final int? id;
  final String name;
  final String type; // text, number, date, select 等
  final int sortOrder;
  final String? createdAt;

  CustomField({
    this.id,
    required this.name,
    this.type = 'text',
    this.sortOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String? ?? 'text',
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }
}

/// 人员自定义字段值模型
class WorkerCustomValue {
  final int? id;
  final int workerId;
  final int fieldId;
  final String? value;

  WorkerCustomValue({
    this.id,
    required this.workerId,
    required this.fieldId,
    this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'field_id': fieldId,
      'value': value,
    };
  }

  factory WorkerCustomValue.fromMap(Map<String, dynamic> map) {
    return WorkerCustomValue(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      fieldId: map['field_id'] as int,
      value: map['value'] as String?,
    );
  }
}

/// 自定义字段 Repository
class CustomFieldRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取所有自定义字段（按排序字段升序）
  Future<List<CustomField>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'custom_fields',
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((m) => CustomField.fromMap(m)).toList();
  }

  /// 添加自定义字段
  Future<int> insert(String name, String type) async {
    final db = await _dbHelper.database;
    // 获取当前最大排序号
    final result = await db.rawQuery(
      'SELECT MAX(sort_order) as max_order FROM custom_fields',
    );
    final maxOrder = (result.first['max_order'] as int?) ?? -1;

    return await db.insert('custom_fields', {
      'name': name,
      'type': type,
      'sort_order': maxOrder + 1,
    });
  }

  /// 更新自定义字段
  Future<int> update(int id, String name, String type) async {
    final db = await _dbHelper.database;
    return await db.update(
      'custom_fields',
      {'name': name, 'type': type},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除自定义字段（关联的 worker_custom_values 会因 CASCADE 自动删除）
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'custom_fields',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

/// 人员自定义字段值 Repository
class WorkerCustomValueRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取某人员的所有自定义字段值
  Future<List<WorkerCustomValue>> getByWorker(int workerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'worker_custom_values',
      where: 'worker_id = ?',
      whereArgs: [workerId],
    );
    return maps.map((m) => WorkerCustomValue.fromMap(m)).toList();
  }

  /// 获取某人员的自定义字段值，返回 fieldId -> value 的映射
  Future<Map<int, String>> getMapByWorker(int workerId) async {
    final values = await getByWorker(workerId);
    final map = <int, String>{};
    for (final v in values) {
      if (v.value != null && v.value!.isNotEmpty) {
        map[v.fieldId] = v.value!;
      }
    }
    return map;
  }

  /// 插入或更新自定义字段值（使用 REPLACE 实现 Upsert）
  Future<void> upsert(int workerId, int fieldId, String value) async {
    final db = await _dbHelper.database;
    await db.execute(
      'INSERT OR REPLACE INTO worker_custom_values (worker_id, field_id, value) VALUES (?, ?, ?)',
      [workerId, fieldId, value],
    );
  }

  /// 删除某人员的所有自定义值
  Future<int> deleteByWorker(int workerId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'worker_custom_values',
      where: 'worker_id = ?',
      whereArgs: [workerId],
    );
  }
}
