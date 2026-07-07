/// 休息日模型
/// 记录排班中的休息日及原因
class RestDay {
  /// 记录ID
  final int? id;

  /// 休息日期
  final String date;

  /// 休息原因
  final String? reason;

  RestDay({
    this.id,
    required this.date,
    this.reason,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'reason': reason,
    };
  }

  /// 从数据库 Map 创建实例
  factory RestDay.fromMap(Map<String, dynamic> map) {
    return RestDay(
      id: map['id'] as int?,
      date: map['date'] as String,
      reason: map['reason'] as String?,
    );
  }

  /// 复制并替换部分字段
  RestDay copyWith({
    int? id,
    String? date,
    String? reason,
  }) {
    return RestDay(
      id: id ?? this.id,
      date: date ?? this.date,
      reason: reason ?? this.reason,
    );
  }
}
