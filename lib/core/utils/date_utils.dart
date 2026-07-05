import 'package:intl/intl.dart';

class DateUtils {
  DateUtils._();

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _monthFormat = DateFormat('yyyy年MM月');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatTime(DateTime time) => _timeFormat.format(time);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);
  static String formatMonth(DateTime date) => _monthFormat.format(date);

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return _dateFormat.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  static String weekdayName(int weekday) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday - 1];
  }

  static String relativeDate(DateTime date) {
    final now = today();
    final target = DateTime(date.year, date.month, date.day);
    final diff = daysBetween(now, target);

    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    if (diff > 1 && diff < 7) return '$diff天后';
    if (diff < -1 && diff > -7) return '${-diff}天前';
    return formatDate(date);
  }

  static int daysUntilExpiry(String? expiryDateStr) {
    if (expiryDateStr == null || expiryDateStr.isEmpty) return -1;
    final expiry = parseDate(expiryDateStr);
    if (expiry == null) return -1;
    return daysBetween(today(), expiry);
  }
}
