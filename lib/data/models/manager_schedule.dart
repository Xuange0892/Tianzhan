/// 管理人员排班模型
/// 管理岗位人员的排班记录
class ManagerSchedule {
  /// 记录ID
  final int? id;

  /// 人员ID
  final int workerId;

  /// 排班日期
  final String date;

  /// 岗位/职务
  final String? position;

  /// 备注
  final String? remark;

  /// 创建时间
  final String? createdAt;

  ManagerSchedule({
    this.id,
    required this.workerId,
    required this.date,
    this.position,
    this.remark,
    this.createdAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'position': position,
      'remark': remark,
      'created_at': createdAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory ManagerSchedule.fromMap(Map<String, dynamic> map) {
    return ManagerSchedule(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      date: map['date'] as String,
      position: map['position'] as String?,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  ManagerSchedule copyWith({
    int? id,
    int? workerId,
    String? date,
    String? position,
    String? remark,
    String? createdAt,
  }) {
    return ManagerSchedule(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      position: position ?? this.position,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
