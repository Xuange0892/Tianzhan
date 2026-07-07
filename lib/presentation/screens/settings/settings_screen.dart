import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  Future<void> _exportDatabase() async {
    setState(() => _isExporting = true);

    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File('$dbPath/tunnelmate.db');

      if (!await dbFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('数据库文件不存在')),
          );
        }
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File(
        '${appDir.path}/tunnelmate_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: '掘进助手数据备份',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('危险操作'),
        content: const Text(
            '确定要清空所有数据吗？此操作不可恢复，所有人员、考勤、排班记录将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = await DatabaseHelper().database;
    await db.delete('workers');
    await db.delete('attendance');
    await db.delete('schedules');
    await db.delete('measure_docs');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空所有数据')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('数据管理'),
          _buildSettingTile(
            icon: Icons.backup_outlined,
            title: '数据备份',
            subtitle: '导出数据库文件，可分享给他人恢复',
            onTap: _isExporting ? null : _exportDatabase,
            trailing: _isExporting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, color: AppColors.inactive),
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingTile(
            icon: Icons.delete_forever_outlined,
            title: '清空所有数据',
            subtitle: '删除所有记录，不可恢复',
            iconColor: AppColors.danger,
            titleColor: AppColors.danger,
            onTap: _clearAllData,
          ),
          _buildSectionTitle('关于'),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: '应用名称',
            subtitle: AppConstants.appName,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingTile(
            icon: Icons.tag,
            title: '版本号',
            subtitle: AppConstants.appVersion,
          ),
          const Divider(height: 1, indent: 56),
          _buildSettingTile(
            icon: Icons.offline_bolt_outlined,
            title: '运行模式',
            subtitle: '完全离线，数据仅存储在本地',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryText,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: titleColor ?? AppColors.primaryText,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.inactive)
              : null),
      onTap: onTap,
    );
  }
}
