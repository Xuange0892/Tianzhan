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

  /// 亮色背景
  static const Color lightBackground = Color(0xFFFAFAFA);

  /// 亮色卡片/表面
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// 亮色次级表面（输入框背景等）
  static const Color lightSurfaceLight = Color(0xFFF5F5F5);

  /// 亮色主文字
  static const Color lightPrimaryText = Color(0xFF333333);

  /// 亮色次文字
  static const Color lightSecondaryText = Color(0xFF757575);

  /// 亮色分隔线
  static const Color lightDivider = Color(0xFFEEEEEE);

  /// 亮色禁用/占位文字
  static const Color lightInactive = Color(0xFFBDBDBD);

  // ==================== 深色主题颜色 ====================

  /// 深色背景
  static const Color darkBackground = Color(0xFF121212);

  /// 深色卡片/表面
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// 深色次级表面
  static const Color darkSurfaceLight = Color(0xFF2C2C2C);

  /// 深色主文字
  static const Color darkPrimaryText = Color(0xFFFFFFFF);

  /// 深色次文字
  static const Color darkSecondaryText = Color(0xFFB0B0B0);

  /// 深色分隔线
  static const Color darkDivider = Color(0xFF2C2C2C);

  /// 深色禁用/占位文字
  static const Color darkInactive = Color(0xFF616161);

  // ==================== 语义化快捷方法 ====================
  // 根据当前主题（isDark）动态返回对应颜色
  // 新代码推荐使用这些方法

  /// 根据当前主题获取背景色
  static Color bgColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  /// 根据当前主题获取表面/卡片色
  static Color cardColor(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  /// 根据当前主题获取次级表面色
  static Color surfaceVariantColor(bool isDark) =>
      isDark ? darkSurfaceLight : lightSurfaceLight;

  /// 根据当前主题获取主文字色
  static Color textPrimary(bool isDark) =>
      isDark ? darkPrimaryText : lightPrimaryText;

  /// 根据当前主题获取次文字色
  static Color textSecondary(bool isDark) =>
      isDark ? darkSecondaryText : lightSecondaryText;

  /// 根据当前主题获取分隔线色
  static Color dividerColor(bool isDark) =>
      isDark ? darkDivider : lightDivider;

  /// 根据当前主题获取禁用色
  static Color inactiveColor(bool isDark) =>
      isDark ? darkInactive : lightInactive;

  // ==================== 亮色主题额外颜色 ====================

  /// 亮色次级表面变体
  static const Color lightSurfaceVariant = Color(0xFFE8E8E8);

  /// 亮色占位/提示文字
  static const Color lightHintText = Color(0xFF999999);

  // ==================== 深色主题额外颜色 ====================

  /// 深色次级表面变体
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  // ==================== 向后兼容属性 ====================
  // 保持与旧版 UI 代码的兼容性
  // 旧代码中直接使用 AppColors.primaryText 等无参属性
  // 这些属性返回深色主题值（旧版仅有深色主题）

  /// 背景（旧版兼容，返回深色背景）
  static const Color background = darkBackground;

  /// 表面/卡片（旧版兼容，返回深色表面）
  static const Color surface = darkSurface;

  /// 次级表面（旧版兼容，返回深色次级表面）
  static const Color surfaceLight = darkSurfaceLight;

  /// 主文字（旧版兼容，返回深色主文字）
  /// 同时支持方法调用 AppColors.primaryText(isDark)
  static const Color primaryText = darkPrimaryText;

  /// 次文字（旧版兼容，返回深色次文字）
  static const Color secondaryText = darkSecondaryText;

  /// 分隔线（旧版兼容，返回深色分隔线）
  static const Color divider = darkDivider;

  /// 禁用色（旧版兼容，返回深色禁用色）
  static const Color inactive = darkInactive;

  // ==================== 与旧版属性同名的方法（支持 isDark 参数） ====================
  // 屏幕文件中大量使用 AppColors.primaryText(isDark) 调用形式

  /// 根据主题获取主文字色
  static Color primaryText(bool isDark) =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF333333);

  /// 根据主题获取次文字色
  static Color secondaryText(bool isDark) =>
      isDark ? const Color(0xFFB0B0B0) : const Color(0xFF666666);

  /// 根据主题获取禁用/占位色
  static Color inactiveColor(bool isDark) =>
      isDark ? const Color(0xFF616161) : const Color(0xFF999999);
}
