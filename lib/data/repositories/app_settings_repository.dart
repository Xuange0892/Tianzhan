import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

/// 应用设置 & 自定义字段仓库
class AppSettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ---- 通用设置 ----

  Future<String?> get(String key) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['value'] as String?;
    return null;
  }

  Future<void> set(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String key) async {
    final db = await _dbHelper.database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  // ---- 部门管理（使用 settings 表存储 JSON 列表） ----

  Future<List<String>> getDepartments() async {
    final json = await get('departments');
    if (json == null || json.isEmpty) return [];
    // 简单解析 JSON 数组字符串
    final cleaned = json.trim();
    if (!cleaned.startsWith('[')) return [];
    return cleaned
        .substring(1, cleaned.length - 1)
        .split(',')
        .map((s) => s.trim().replaceAll('"', '').replaceAll("'", '').isEmpty ? null : s.trim().replaceAll('"', '').replaceAll("'", ''))
        .where((s) => s != null && s.isNotEmpty)
        .map((s) => s!)
        .toList();
  }

  Future<void> saveDepartments(List<String> departments) async {
    final buffer = StringBuffer('[');
    for (int i = 0; i < departments.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write('"${departments[i]}"');
    }
    buffer.write(']');
    await set('departments', buffer.toString());
  }

  // ---- 自定义字段 ----

  Future<List<String>> getCustomFields() async {
    final db = await _dbHelper.database;
    final maps = await db.query('custom_fields', orderBy: 'sort_order ASC, id ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<int> addCustomField(String fieldName) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT MAX(sort_order) as max_order FROM custom_fields');
    final maxOrder = (result.first['max_order'] as int?) ?? -1;
    return await db.insert('custom_fields', {'name': fieldName, 'type': 'text', 'sort_order': maxOrder + 1});
  }

  Future<int> removeCustomField(String fieldName) async {
    final db = await _dbHelper.database;
    return await db.delete('custom_fields', where: 'name = ?', whereArgs: [fieldName]);
  }

  // ---- 排班配置 ----

  Future<String?> getScheduleConfig(String groupName, String configKey) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'schedule_configs',
      where: 'group_name = ? AND config_key = ?',
      whereArgs: [groupName, configKey],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['config_value'] as String?;
    return null;
  }

  Future<void> setScheduleConfig(String groupName, String configKey, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'schedule_configs',
      {'group_name': groupName, 'config_key': configKey, 'config_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取某个班组的所有配置
  Future<Map<String, String>> getGroupConfigs(String groupName) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedule_configs',
      where: 'group_name = ?',
      whereArgs: [groupName],
    );
    return {for (var m in maps) m['config_key'] as String: m['config_value'] as String};
  }

  /// 批量保存班组配置
  Future<void> saveGroupConfigs(String groupName, Map<String, String> configs) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final entry in configs.entries) {
      batch.insert(
        'schedule_configs',
        {'group_name': groupName, 'config_key': entry.key, 'config_value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
