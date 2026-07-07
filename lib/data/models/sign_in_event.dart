/// 签到事项模型
/// 定义一个需要人员签到的活动/事项
class SignInEvent {
  /// 事项ID
  final int? id;

  /// 事项标题
  final String title;

  /// 事项描述
  final String? description;

  /// 创建时间
  final String? createdAt;

  SignInEvent({
    this.id,
    required this.title,
    this.description,
    this.createdAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': createdAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory SignInEvent.fromMap(Map<String, dynamic> map) {
    return SignInEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  SignInEvent copyWith({
    int? id,
    String? title,
    String? description,
    String? createdAt,
  }) {
    return SignInEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
