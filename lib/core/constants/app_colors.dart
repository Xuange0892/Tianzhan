import 'package:flutter/material.dart';

/// 应用配色方案
/// 包含亮色和深色两套主题颜色
class AppColors {
  AppColors._();

  // ==================== 通用颜色（不区分亮暗） ====================

  /// 主色 - 清新蓝绿
  static const Color primary = Color(0xFF26A69A);

  /// 主色深色变体
  static const Color primaryDark = Color(0xFF00897B);

  /// 主色浅色变体
  static const Color primaryLight = Color(0xFF80CBC4);

  /// 辅助色 - 柔和绿
  static const Color secondary = Color(0xFF66BB6A);

  /// 警告色 - 温暖橙
  static const Color warning = Color(0xFFFFA726);

  /// 危险色 - 柔和红
  static const Color danger = Color(0xFFEF5350);

  // ==================== 亮色主题颜色 ====================

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF5F5F5);
  static const Color lightPrimaryText = Color(0xFF333333);
  static const Color lightSecondaryText = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightInactive = Color(0xFFBDBDBD);
  static const Color lightSurfaceVariant = Color(0xFFE8E8E8);
  static const Color lightHintText = Color(0xFF999999);

  // ==================== 深色主题颜色 ====================

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceLight = Color(0xFF2C2C2C);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkInactive = Color(0xFF616161);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  // ==================== 语义化方法（根据 isDark 动态取色） ====================

  static Color bgColor(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color cardColor(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color surfaceVariantColor(bool isDark) => isDark ? darkSurfaceVariant : lightSurfaceVariant;
  static Color dividerColor(bool isDark) => isDark ? darkDivider : lightDivider;

  /// 主文字色
  static Color primaryText(bool isDark) => isDark ? darkPrimaryText : lightPrimaryText;

  /// 次文字色
  static Color secondaryText(bool isDark) => isDark ? darkSecondaryText : lightSecondaryText;

  /// 禁用/占位色
  static Color inactiveColor(bool isDark) => isDark ? darkInactive : lightInactive;
}
