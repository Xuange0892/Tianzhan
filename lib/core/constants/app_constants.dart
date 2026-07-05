class AppConstants {
  AppConstants._();

  static const String appName = '掘进助手';
  static const String appVersion = '1.0.0';

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

  static const List<String> departments = [
    '掘进一队',
    '掘进二队',
    '支护班',
    '机电班',
    '运输班',
  ];

  static const List<String> shiftTypes = [
    '白班',
    '夜班',
    '中班',
  ];

  static const Map<String, String> shiftTimeMap = {
    '白班': '08:00 - 16:00',
    '夜班': '16:00 - 00:00',
    '中班': '00:00 - 08:00',
  };

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
    'normal': Color(0xFF388E3C),
    'late': Color(0xFFF57C00),
    'early': Color(0xFFF57C00),
    'absent': Color(0xFFD32F2F),
    'leave': Color(0xFF1976D2),
  };

  static const Map<String, String> workerStatusLabels = {
    'active': '在职',
    'leave': '离职',
    'transfer': '调岗',
  };
}
