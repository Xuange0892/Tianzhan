/// 人员自定义字段值模型
/// 存储某个人员在某个自定义字段上填写的值
class WorkerCustomValue {
  /// 记录ID
  final int? id;

  /// 人员ID
  final int workerId;

  /// 自定义字段ID
  final int fieldId;

  /// 填写的值
  final String? value;

  WorkerCustomValue({
    this.id,
    required this.workerId,
    required this.fieldId,
    this.value,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'field_id': fieldId,
      'value': value,
    };
  }

  /// 从数据库 Map 创建实例
  factory WorkerCustomValue.fromMap(Map<String, dynamic> map) {
    return WorkerCustomValue(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      fieldId: map['field_id'] as int,
      value: map['value'] as String?,
    );
  }

  /// 复制并替换部分字段
  WorkerCustomValue copyWith({
    int? id,
    int? workerId,
    int? fieldId,
    String? value,
  }) {
    return WorkerCustomValue(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      fieldId: fieldId ?? this.fieldId,
      value: value ?? this.value,
    );
  }
}
