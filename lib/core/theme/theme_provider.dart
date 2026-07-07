import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题状态管理
class ThemeProvider extends ChangeNotifier {
  static const String _keyIsDark = 'theme_is_dark';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    _load();
  }

  /// 获取 ThemeMode（兼容 app.dart）
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  /// 从本地持久化加载主题偏好
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_keyIsDark) ?? false;
    notifyListeners();
  }

  /// 切换亮暗主题
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDark, _isDark);
    notifyListeners();
  }
}
