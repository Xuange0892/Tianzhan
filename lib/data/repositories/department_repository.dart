import '../database/database_helper.dart';

/// 部门模型
class Department {
  final int? id;
  final String name;
  final String? createdAt;

  Department({
    this.id,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}

/// 部门 Repository
class DepartmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 获取所有部门
  Future<List<Department>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'departments',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Department.fromMap(m)).toList();
  }

  /// 添加部门
  Future<int> add(String name) async {
    final db = await _dbHelper.database;
    return await db.insert('departments', {
      'name': name,
    });
  }

  /// 删除部门
  Future<int> remove(String name) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'departments',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  /// 获取某部门人数
  Future<int> getWorkerCount(String department) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM workers WHERE department = ? AND status = 'active'",
      [department],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
