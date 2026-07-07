import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';


import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../widgets/confirm_dialog.dart';

/// 系统设置
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = AppSettingsRepository();
  final _dbHelper = DatabaseHelper();

  List<String> _departments = [];
  List<String> _customFields = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final depts = await _settingsRepo.getDepartments();
    final defaults = List<String>.from(AppConstants.departments);
    final fields = await _settingsRepo.getCustomFields();
    if (mounted) setState(() {
      _departments = depts.isEmpty ? defaults : [...defaults, ...depts].toSet().toList();
      _customFields = fields;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 主题切换
          _buildSection('外观', isDark),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
              activeColor: AppColors.primary,
            ),
          ),

          const Divider(),

          // 部门管理
          _buildSection('部门管理', isDark),
          ..._departments.asMap().entries.map((e) => ListTile(
            title: Text(e.value),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeDept(e.value)),
          )),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            title: const Text('添加部门'),
            onTap: () => _addDeptDialog(),
          ),

          const Divider(),

          // 自定义字段管理
          _buildSection('自定义字段', isDark),
          ..._customFields.asMap().entries.map((e) => ListTile(
            title: Text(e.value),
            trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeCustomField(e.value)),
          )),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            title: const Text('添加自定义字段'),
            onTap: () => _addCustomFieldDialog(),
          ),

          const Divider(),

          // 数据管理
          _buildSection('数据管理', isDark),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: AppColors.secondary),
            title: const Text('备份导出'),
            subtitle: const Text('导出全部数据为JSON文件'),
            onTap: _backupData,
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined, color: AppColors.warning),
            title: const Text('恢复导入'),
            subtitle: const Text('从JSON备份文件恢复数据'),
            onTap: _restoreData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
            title: const Text('清空所有数据', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('删除全部数据，不可恢复'),
            onTap: _clearAllData,
          ),

          const Divider(),

          // 关于
          _buildSection('关于', isDark),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(AppConstants.appName),
            subtitle: Text('版本 ${AppConstants.appVersion}'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.secondaryText(isDark))),
    );
  }

  Future<void> _addDeptDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加部门'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '部门名称'), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim()); }, child: const Text('添加'))],
    ));
    if (result != null) {
      final newDepts = [..._departments, result];
      await _settingsRepo.saveDepartments(newDepts);
      _load();
    }
  }

  Future<void> _removeDept(String dept) async {
    final newDepts = _departments.where((d) => d != dept).toList();
    await _settingsRepo.saveDepartments(newDepts);
    _load();
  }

  Future<void> _addCustomFieldDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加自定义字段'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '字段名称'), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, ctrl.text.trim()); }, child: const Text('添加'))],
    ));
    if (result != null) {
      await _settingsRepo.addCustomField(result);
      _load();
    }
  }

  Future<void> _removeCustomField(String field) async {
    await _settingsRepo.removeCustomField(field);
    _load();
  }

  Future<void> _backupData() async {
    try {
      final db = await _dbHelper.database;
      final tables = ['workers', 'attendance', 'schedules', 'sign_in_events', 'sign_in_records', 'certificates', 'todos', 'custom_fields', 'app_settings', 'manager_schedules', 'schedule_configs', 'measure_docs'];
      final backup = <String, List<Map<String, dynamic>>>{};
      for (final table in tables) {
        try { backup[table] = await db.query(table); } catch (_) {}
      }
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/tunnelmate_backup_$timestamp.json');
      await file.writeAsString(jsonStr);
      if (mounted) await Share.shareXFiles([XFile(file.path)], subject: 'Tianzhan 数据备份');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e')));
    }
  }

  Future<void> _restoreData() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return;
    final fp = result.files.first.path;
    if (fp == null) return;

    final confirmed = await ConfirmDialog.show(context,
      title: '确认恢复',
      content: '恢复数据会覆盖当前所有数据，确定继续吗？',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      final file = File(fp);
      final jsonStr = await file.readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        for (final entry in data.entries) {
          final table = entry.key;
          final rows = (entry.value as List).cast<Map<String, dynamic>>();
          for (final row in rows) {
            try { await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace); } catch (_) {}
          }
        }
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据恢复成功，请重启应用')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await ConfirmDialog.show(context,
      title: '清空所有数据',
      content: '此操作将删除所有人员、考勤、排班、证件、待办等数据，不可恢复！确定继续吗？',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      final db = await _dbHelper.database;
      final tables = ['workers', 'attendance', 'schedules', 'sign_in_events', 'sign_in_records', 'certificates', 'todos', 'custom_fields', 'app_settings', 'manager_schedules', 'schedule_configs', 'measure_docs'];
      for (final table in tables) {
        try { await db.delete(table); } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空所有数据')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('清空失败: $e')));
    }
  }
}
