/// 排班配置模型
/// 定义排班分组及其各班次负责人
class ScheduleConfig {
  /// 配置ID
  final int? id;

  /// 分组名称（如：甲组）
  final String groupName;

  /// 维修班负责人
  final String? maintenanceName;

  /// 生产一班负责人
  final String? production1Name;

  /// 生产二班负责人
  final String? production2Name;

  /// 生产三班负责人
  final String? production3Name;

  /// 基准日期（排班计算的起始日期）
  final String baseDate;

  ScheduleConfig({
    this.id,
    required this.groupName,
    this.maintenanceName,
    this.production1Name,
    this.production2Name,
    this.production3Name,
    required this.baseDate,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_name': groupName,
      'maintenance_name': maintenanceName,
      'production1_name': production1Name,
      'production2_name': production2Name,
      'production3_name': production3Name,
      'base_date': baseDate,
    };
  }

  /// 从数据库 Map 创建实例
  factory ScheduleConfig.fromMap(Map<String, dynamic> map) {
    return ScheduleConfig(
      id: map['id'] as int?,
      groupName: map['group_name'] as String,
      maintenanceName: map['maintenance_name'] as String?,
      production1Name: map['production1_name'] as String?,
      production2Name: map['production2_name'] as String?,
      production3Name: map['production3_name'] as String?,
      baseDate: map['base_date'] as String,
    );
  }

  /// 复制并替换部分字段
  ScheduleConfig copyWith({
    int? id,
    String? groupName,
    String? maintenanceName,
    String? production1Name,
    String? production2Name,
    String? production3Name,
    String? baseDate,
  }) {
    return ScheduleConfig(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      maintenanceName: maintenanceName ?? this.maintenanceName,
      production1Name: production1Name ?? this.production1Name,
      production2Name: production2Name ?? this.production2Name,
      production3Name: production3Name ?? this.production3Name,
      baseDate: baseDate ?? this.baseDate,
    );
  }
}
