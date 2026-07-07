/// 待办事项模型
/// 管理日常工作中的待办任务
class Todo {
  /// 待办ID
  final int? id;

  /// 待办标题
  final String title;

  /// 待办描述
  final String? description;

  /// 截止日期
  final String? dueDate;

  /// 是否已完成
  final bool isCompleted;

  /// 优先级（low, medium, high）
  final String priority;

  /// 创建时间
  final String? createdAt;

  /// 更新时间
  final String? updatedAt;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    this.priority = 'medium',
    this.createdAt,
    this.updatedAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: map['due_date'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      priority: map['priority'] as String? ?? 'medium',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    bool? isCompleted,
    String? priority,
    String? createdAt,
    String? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
