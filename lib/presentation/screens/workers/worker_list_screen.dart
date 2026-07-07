import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/services/worker_import_service.dart';
import '../../../data/services/worker_export_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirm_dialog.dart';
import 'worker_form_screen.dart';
import 'worker_detail_screen.dart';

/// 人员管理列表
class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final WorkerRepository _repo = WorkerRepository();
  final AppSettingsRepository _settingsRepo = AppSettingsRepository();

  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  List<String> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartment;
  String _selectedStatus = 'active';
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final depts = await _settingsRepo.getDepartments();
      final defaults = List<String>.from(AppConstants.departments);
      _departments = depts.isEmpty ? defaults : [...defaults, ...depts].toSet().toList();
    } catch (_) {
      _departments = List.from(AppConstants.departments);
    }
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final workers = await _repo.getAll(
      status: _selectedStatus.isEmpty ? null : _selectedStatus,
      department: _selectedDepartment,
    );
    setState(() {
      _workers = workers;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredWorkers = List.from(_workers);
    } else {
      final keywords = _searchQuery
          .split(RegExp(r'[,，、；;\s\n\r]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      _filteredWorkers = _workers.where((w) {
        return keywords.every((k) =>
            w.name.contains(k) || w.employeeNo.contains(k) ||
            (w.phone?.contains(k) ?? false) || (w.department?.contains(k) ?? false));
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('人员管理'),
        actions: [
          if (_isImporting || _isExporting)
            const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else ...[
            IconButton(icon: const Icon(Icons.file_download_outlined), tooltip: '导出', onPressed: _showExportMenu),
            IconButton(icon: const Icon(Icons.file_upload_outlined), tooltip: '导入', onPressed: _showImportMenu),
          ],
        ],
      ),
      body: Column(children: [
        // 搜索
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (q) { _searchQuery = q; _applyFilter(); setState(() {}); },
            decoration: InputDecoration(
              hintText: '搜索姓名/工号/电话',
              prefixIcon: const Icon(Icons.search_outlined, size: 20),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () { _searchQuery = ''; _applyFilter(); setState(() {}); }) : null,
            ),
          ),
        ),
        // 状态筛选
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('全部', '', isDark),
              const SizedBox(width: 8),
              _chip('在职', 'active', isDark),
              const SizedBox(width: 8),
              _chip('离职', 'leave', isDark),
              const SizedBox(width: 8),
              _chip('调岗', 'transfer', isDark),
            ]),
          ),
        ),
        // 部门筛选
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _deptChip('全部', null, isDark),
              ..._departments.map((d) => Padding(padding: const EdgeInsets.only(right: 8), child: _deptChip(d, d, isDark))),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        // 列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredWorkers.isEmpty
                  ? EmptyState(icon: Icons.people_outline, title: '暂无人员信息', subtitle: '点击 + 添加或使用导入功能')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _filteredWorkers.length,
                      itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(_filteredWorkers[i], isDark))),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'worker_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerFormScreen())).then((_) => _loadData()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(String label, String status, bool isDark) {
    return ChoiceChip(label: Text(label), selected: _selectedStatus == status, onSelected: (_) { _selectedStatus = status; _loadWorkers(); });
  }

  Widget _deptChip(String label, String? dept, bool isDark) {
    return ChoiceChip(label: Text(label), selected: _selectedDepartment == dept, onSelected: (_) { _selectedDepartment = dept; _loadWorkers(); });
  }

  Widget _card(Worker w, bool isDark) {
    final sl = AppConstants.workerStatusLabels[w.status] ?? w.status;
    final sc = w.status == 'active' ? AppColors.secondary : (w.status == 'leave' ? AppColors.danger : AppColors.warning);
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: w))).then((_) => _loadData()),
        onLongPress: () => _showActions(w),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(w.name.isNotEmpty ? w.name[0] : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(w.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(sl, style: TextStyle(fontSize: 11, color: sc, fontWeight: FontWeight.w500))),
                ]),
                const SizedBox(height: 4),
                Text('${w.employeeNo}  ${w.jobType ?? ''}', style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark)), overflow: TextOverflow.ellipsis),
                if (w.department != null) Text(w.department!, style: TextStyle(fontSize: 12, color: AppColors.inactiveColor(isDark))),
              ]),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ]),
        ),
      ),
    );
  }

  void _showActions(Worker w) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('查看详情'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: w))); }),
        ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('编辑'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerFormScreen(worker: w))).then((_) => _loadData()); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.danger), title: const Text('删除', style: TextStyle(color: AppColors.danger)), onTap: () async { Navigator.pop(ctx); if (await ConfirmDialog.show(context, title: '确认删除', content: '确定删除 ${w.name}？', isDestructive: true)) { await _repo.delete(w.id!); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'))); _loadData(); } } }),
      ])),
    );
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.outline, borderRadius: BorderRadius.circular(2))),
          const Text('批量导入人员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _menuBtn(ctx, Icons.download_outlined, '下载导入模板', '获取CSV模板', AppColors.primary, _downloadTemplate),
          const SizedBox(height: 12),
          _menuBtn(ctx, Icons.upload_file_outlined, '选择CSV文件导入', '批量导入人员', AppColors.secondary, _importCsv),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)), child: const Text('1. 下载模板用Excel编辑\n2. 填写人员信息（姓名和工号必填）\n3. 保存为CSV格式后导入', style: TextStyle(fontSize: 12, height: 1.6))),
        ]),
      )),
    );
  }

  Widget _menuBtn(BuildContext ctx, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(ctx).colorScheme.outline, width: 0.5), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(sub, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(context.watch<ThemeProvider>().isDark)))])),
          const Icon(Icons.chevron_right, size: 20),
        ]),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final csv = await WorkerImportService.generateTemplate();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/人员导入模板.csv');
      await file.writeAsString(csv);
      if (mounted) await Share.shareXFiles([XFile(file.path)], subject: '人员导入模板');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt']);
    if (result == null || result.files.isEmpty) return;
    final fp = result.files.first.path;
    if (fp == null) return;
    setState(() => _isImporting = true);
    try {
      final ir = await WorkerImportService().importFromCsv(fp);
      if (mounted) { _showImportResult(ir); _loadData(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportResult(ImportResult r) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('导入结果'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('共处理 ${r.total} 条'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _ri('成功', r.successCount, AppColors.secondary)),
          const SizedBox(width: 8),
          Expanded(child: _ri('跳过', r.skipCount, AppColors.warning)),
          const SizedBox(width: 8),
          Expanded(child: _ri('失败', r.failCount, AppColors.danger)),
        ]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定'))],
    ));
  }

  Widget _ri(String label, int count, Color color) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)), Text(label, style: const TextStyle(fontSize: 12))]));
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.outline, borderRadius: BorderRadius.circular(2))),
          Text('导出 ${_filteredWorkers.length} 人', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _menuBtn(ctx, Icons.file_download_outlined, '导出全部字段', '', AppColors.secondary, () { Navigator.pop(ctx); _doExport(ExportField.all); }),
          const SizedBox(height: 12),
          _menuBtn(ctx, Icons.tune, '导出常用字段', '', AppColors.primary, () { Navigator.pop(ctx); _doExport(ExportField.defaults); }),
        ]),
      )),
    );
  }

  Future<void> _doExport(List<ExportField> fields) async {
    if (_filteredWorkers.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有可导出的人员'))); return; }
    setState(() => _isExporting = true);
    try {
      final fp = await WorkerExportService().exportToFile(_filteredWorkers, fields);
      if (mounted) await Share.shareXFiles([XFile(fp)], subject: '人员信息导出');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
