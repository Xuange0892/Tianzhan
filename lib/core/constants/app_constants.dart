import 'package:flutter/material.dart';

/// 应用全局常量
/// 包含基础枚举类型、签到相关常量等
class AppConstants {
  AppConstants._();

  // ==================== 应用信息 ====================

  static const String appName = 'TunnelMate';
  static const String appVersion = '2.0.0';

  // ==================== 部门列表 ====================

  /// 部门列表（空列表，由用户自行管理）
  static const List<String> departments = [];

  // ==================== 岗位类型 ====================

  static const List<String> jobTypes = [
    '掘进工',
    '支护工',
    '爆破工',
    '电工',
    '瓦斯检查工',
    '输送机司机',
    '机电维修工',
    '班组长',
    '技术员',
  ];

  // ==================== 班次类型 ====================

  static const List<String> shiftTypes = [
    '白班',
    '夜班',
    '中班',
  ];

  /// 班次对应时间段
  static const Map<String, String> shiftTimeMap = {
    '白班': '08:00 - 16:00',
    '夜班': '16:00 - 00:00',
    '中班': '00:00 - 08:00',
  };

  // ==================== 考勤状态 ====================

  static const List<String> attendanceStatuses = [
    'normal',
    'late',
    'early',
    'absent',
    'leave',
  ];

  static const Map<String, String> attendanceStatusLabels = {
    'normal': '正常',
    'late': '迟到',
    'early': '早退',
    'absent': '缺勤',
    'leave': '请假',
  };

  static const Map<String, Color> attendanceStatusColors = {
    'normal': Color(0xFF66BB6A),
    'late': Color(0xFFFFA726),
    'early': Color(0xFFFFA726),
    'absent': Color(0xFFEF5350),
    'leave': Color(0xFF26A69A),
  };

  // ==================== 人员状态 ====================

  static const Map<String, String> workerStatusLabels = {
    'active': '在职',
    'leave': '离职',
    'transfer': '调岗',
  };

  // ==================== 签到相关常量 ====================

  /// 待办优先级
  static const List<String> todoPriorities = [
    'low',
    'medium',
    'high',
  ];

  /// 待办优先级标签
  static const Map<String, String> todoPriorityLabels = {
    'low': '低',
    'medium': '中',
    'high': '高',
  };

  /// 待办优先级颜色
  static const Map<String, Color> todoPriorityColors = {
    'low': Color(0xFF66BB6A),
    'medium': Color(0xFFFFA726),
    'high': Color(0xFFEF5350),
  };

  /// 自定义字段类型
  static const List<String> customFieldTypes = [
    'text',
    'number',
    'date',
    'select',
  ];

  /// 自定义字段类型标签
  static const Map<String, String> customFieldTypeLabels = {
    'text': '文本',
    'number': '数字',
    'date': '日期',
    'select': '选择',
  };

  /// 数据库相关常量
  static const String databaseName = 'tunnelmate.db';
  static const int databaseVersion = 2;
}
