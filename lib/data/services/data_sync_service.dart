import 'dart:convert';
import '../database/database_helper.dart';

/// 数据导入导出统计结果
class DataSyncResult {
  final Map<String, int> counts;

  DataSyncResult(this.counts);

  int get total => counts.values.fold(0, (a, b) => a + b);

  @override
  String toString() {
    final parts = <String>[];
    counts.forEach((key, value) {
      parts.add('$key: $value');
    });
    return parts.join(', ');
  }
}

/// 数据同步服务：导出所有数据为 JSON / 从 JSON 恢复所有数据
class DataSyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 导出所有数据为单个 JSON 字符串
  /// 包含：workers、custom_fields、worker_custom_values、sign_in_events、
  /// sign_in_records、certificates、todos、schedule_config、rest_days、
  /// manager_schedules、departments
  Future<String> exportAll() async {
    final db = await _dbHelper.database;

    // 收集所有数据
    final workers = await db.query('workers');
    final customFields = await db.query('custom_fields');
    final workerCustomValues = await db.query('worker_custom_values');
    final signInEvents = await db.query('sign_in_events');
    final signInRecords = await db.query('sign_in_records');
    final certificates = await db.query('certificates');
    final todos = await db.query('todos');
    final scheduleConfig = await db.query('schedule_config');
    final restDays = await db.query('rest_days');
    final managerSchedules = await db.query('manager_schedules');
    final departments = await db.query('departments');

    final exportData = {
      'version': 2,
      'export_time': DateTime.now().toIso8601String(),
      'workers': workers,
      'custom_fields': customFields,
      'worker_custom_values': workerCustomValues,
      'sign_in_events': signInEvents,
      'sign_in_records': signInRecords,
      'certificates': certificates,
      'todos': todos,
      'schedule_config': scheduleConfig,
      'rest_days': restDays,
      'manager_schedules': managerSchedules,
      'departments': departments,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从 JSON 字符串恢复所有数据
  /// 先清空所有表，再按依赖顺序导入
  /// 返回导入结果统计
  Future<DataSyncResult> importAll(String jsonString) async {
    final db = await _dbHelper.database;
    final counts = <String, int>{};

    // 解析 JSON
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    // 关闭外键约束检查（SQLite需要手动处理）
    await db.execute('PRAGMA foreign_keys = OFF');

    // 使用事务确保原子性
    await db.transaction((txn) async {
      // 按依赖顺序清空表（子表先清空）
      final tablesToClear = [
        'sign_in_records',
        'worker_custom_values',
        'certificates',
        'workers',
        'sign_in_events',
        'todos',
        'schedule_config',
        'rest_days',
        'manager_schedules',
        'custom_fields',
        'departments',
      ];

      for (final table in tablesToClear) {
        await txn.delete(table);
      }

      // 按依赖顺序导入（父表先导入）

      // 1. 自定义字段
      if (data['custom_fields'] != null) {
        final rows = (data['custom_fields'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('custom_fields', _cleanRowForImport(row));
        }
        counts['自定义字段'] = rows.length;
      }

      // 2. 排班配置
      if (data['schedule_config'] != null) {
        final rows = (data['schedule_config'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('schedule_config', _cleanRowForImport(row));
        }
        counts['排班配置'] = rows.length;
      }

      // 3. 部门
      if (data['departments'] != null) {
        final rows = (data['departments'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('departments', _cleanRowForImport(row));
        }
        counts['部门'] = rows.length;
      }

      // 4. 签到事项
      if (data['sign_in_events'] != null) {
        final rows = (data['sign_in_events'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('sign_in_events', _cleanRowForImport(row));
        }
        counts['签到事项'] = rows.length;
      }

      // 5. 人员
      if (data['workers'] != null) {
        final rows = (data['workers'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('workers', _cleanRowForImport(row));
        }
        counts['人员'] = rows.length;
      }

      // 6. 人员自定义字段值
      if (data['worker_custom_values'] != null) {
        final rows = (data['worker_custom_values'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('worker_custom_values', _cleanRowForImport(row));
        }
        counts['自定义字段值'] = rows.length;
      }

      // 7. 签到记录
      if (data['sign_in_records'] != null) {
        final rows = (data['sign_in_records'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('sign_in_records', _cleanRowForImport(row));
        }
        counts['签到记录'] = rows.length;
      }

      // 8. 证件
      if (data['certificates'] != null) {
        final rows = (data['certificates'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('certificates', _cleanRowForImport(row));
        }
        counts['证件'] = rows.length;
      }

      // 9. 待办事项
      if (data['todos'] != null) {
        final rows = (data['todos'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('todos', _cleanRowForImport(row));
        }
        counts['待办事项'] = rows.length;
      }

      // 10. 休息日
      if (data['rest_days'] != null) {
        final rows = (data['rest_days'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('rest_days', _cleanRowForImport(row));
        }
        counts['休息日'] = rows.length;
      }

      // 11. 管理人员排班
      if (data['manager_schedules'] != null) {
        final rows = (data['manager_schedules'] as List).cast<Map<String, dynamic>>();
        for (final row in rows) {
          await txn.insert('manager_schedules', _cleanRowForImport(row));
        }
        counts['管理人员排班'] = rows.length;
      }
    });

    // 恢复外键约束
    await db.execute('PRAGMA foreign_keys = ON');

    return DataSyncResult(counts);
  }

  /// 清理导入行数据：移除 id 列以避免冲突
  Map<String, dynamic> _cleanRowForImport(Map<String, dynamic> row) {
    final cleaned = <String, dynamic>{};
    for (final entry in row.entries) {
      // 跳过自增 id 列，让数据库自动生成
      if (entry.key == 'id') continue;
      cleaned[entry.key] = entry.value;
    }
    return cleaned;
  }
}
