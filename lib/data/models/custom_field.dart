/// 自定义字段模型
/// 用于管理用户自定义的人员信息字段
class CustomField {
  /// 字段ID
  final int? id;

  /// 字段名称
  final String fieldName;

  /// 字段类型（text, number, date, select）
  final String fieldType;

  /// 创建时间
  final String? createdAt;

  CustomField({
    this.id,
    required this.fieldName,
    required this.fieldType,
    this.createdAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'field_name': fieldName,
      'field_type': fieldType,
      'created_at': createdAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      id: map['id'] as int?,
      fieldName: map['field_name'] as String,
      fieldType: map['field_type'] as String,
      createdAt: map['created_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  CustomField copyWith({
    int? id,
    String? fieldName,
    String? fieldType,
    String? createdAt,
  }) {
    return CustomField(
      id: id ?? this.id,
      fieldName: fieldName ?? this.fieldName,
      fieldType: fieldType ?? this.fieldType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
