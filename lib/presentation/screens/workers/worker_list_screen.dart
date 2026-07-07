import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/services/worker_import_service.dart';
import '../../../data/services/worker_export_service.dart';
import '../../widgets/empty_state.dart';
import 'worker_form_screen.dart';
import 'worker_detail_screen.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final WorkerRepository _repo = WorkerRepository();
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedDepartment;
  String _selectedStatus = 'active';
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _isLoading = true);
    final workers = await _repo.getAll(
      status: _selectedStatus,
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
      // 支持多种分隔符：逗号、中文逗号、空格、顿号、分号、换行等
      final keywords = _searchQuery
          .split(RegExp(r'[,，、；;\s\n\r]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      _filteredWorkers = _workers.where((w) {
        // 每个关键词都匹配任意字段才算命中
        return keywords.every((keyword) =>
            w.name.contains(keyword) ||
            w.employeeNo.contains(keyword) ||
            (w.phone?.contains(keyword) ?? false));
      }).toList();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  Future<void> _importFromCsv() async {
    // 先选择文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    setState(() => _isImporting = true);

    try {
      final service = WorkerImportService();
      final importResult = await service.importFromCsv(filePath);

      if (mounted) {
        _showImportResult(importResult);
        _loadWorkers(); // 刷新列表
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportResult(ImportResult result) {
    if (result.total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.isNotEmpty
              ? '导入失败: ${result.errors.first}'
              : '没有可导入的数据'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('导入结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '共处理 ${result.total} 条记录',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildResultItem('成功', result.successCount, AppColors.secondary),
                const SizedBox(width: 16),
                _buildResultItem('跳过', result.skipCount, AppColors.warning),
                const SizedBox(width: 16),
                _buildResultItem('失败', result.failCount, AppColors.danger),
              ],
            ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                '详细:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.errors
                        .take(10)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                e,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              if (result.errors.length > 10)
                Text(
                  '...共 ${result.errors.length} 条提示',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inactive,
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final csvContent = WorkerImportService.generateTemplate();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, '人员导入模板.csv'));
      await file.writeAsString(csvContent);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '掘进助手 - 人员导入模板',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出模板失败: $e')),
        );
      }
    }
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '批量导入人员',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                icon: Icons.download_outlined,
                title: '下载导入模板',
                subtitle: '获取CSV模板文件，用Excel或WPS编辑后导入',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _downloadTemplate();
                },
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                icon: Icons.upload_file_outlined,
                title: '选择CSV文件导入',
                subtitle: '选择编辑好的CSV文件，批量导入人员信息',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _importFromCsv();
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '使用说明',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. 先下载模板，用WPS/Excel打开编辑\n'
                      '2. 填写人员信息（姓名和工号必填）\n'
                      '3. 保存为CSV格式（.csv）\n'
                      '4. 回到此页面点击"选择CSV文件导入"\n\n'
                      '支持中英文表头，工号重复会自动跳过',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inactive),
          ],
        ),
      ),
    );
  }

  // ==================== 导出功能 ====================

  /// 显示导出选项菜单
  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '导出人员信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '当前筛选：${_filteredWorkers.length} 人${_searchQuery.isNotEmpty ? '（搜索: "$_searchQuery"）' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              _buildExportButton(
                icon: Icons.file_download_outlined,
                title: '导出当前筛选结果',
                subtitle: '导出当前列表中 $_filteredWorkers 个人员的全部字段',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  _doExport(_filteredWorkers, ExportField.all);
                },
              ),
              const SizedBox(height: 12),
              _buildExportButton(
                icon: Icons.tune,
                title: '自定义导出',
                subtitle: '选择导出哪些字段，可导出部分信息',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showFieldPicker();
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '提示',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '导出的CSV文件可用WPS/Excel打开查看和编辑。'
                      '先使用搜索或筛选功能缩小范围，再导出即可获取特定人员的信息。',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 字段选择弹窗
  void _showFieldPicker() {
    // 默认选中常用字段
    final selectedKeys = <String>{
      for (final f in ExportField.defaults) f.key,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('选择导出字段'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedKeys.clear();
                          for (final f in ExportField.all) {
                            selectedKeys.add(f.key);
                          }
                        });
                      },
                      child: const Text('全选'),
                    ),
                    TextButton(
                      onPressed: () {
                        setDialogState(() {
                          selectedKeys.clear();
                          for (final f in ExportField.defaults) {
                            selectedKeys.add(f.key);
                          }
                        });
                      },
                      child: const Text('常用'),
                    ),
                    TextButton(
                      onPressed: () => setDialogState(() => selectedKeys.clear()),
                      child: const Text('清空'),
                    ),
                    const Spacer(),
                    Text(
                      '已选 ${selectedKeys.length}/${ExportField.all.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExportField.all.map((field) {
                    final isSelected = selectedKeys.contains(field.key);
                    return FilterChip(
                      label: Text(field.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedKeys.add(field.key);
                          } else {
                            selectedKeys.remove(field.key);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (selectedKeys.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请至少选择一个字段')),
                  );
                  return;
                }
                final fields = ExportField.all
                    .where((f) => selectedKeys.contains(f.key))
                    .toList();
                _doExport(_filteredWorkers, fields);
              },
              child: Text('导出 ${_filteredWorkers.length} 人'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行导出
  Future<void> _doExport(List<Worker> workers, List<ExportField> fields) async {
    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可导出的人员')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final service = WorkerExportService();
      final filePath = await service.exportToFile(workers, fields);

      if (mounted) {
        final fieldNames = fields.map((f) => f.label).join('、');
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: '掘进助手 - 人员信息导出',
          text: '共导出 ${workers.length} 人，包含字段：$fieldNames',
        );
      }
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

  Widget _buildExportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inactive),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人员管理'),
        actions: [
          IconButton(
            icon: _isImporting || _isExporting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: '导出',
            onPressed: (_isImporting || _isExporting) ? null : _showExportMenu,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '批量导入',
            onPressed: _isImporting ? null : _showImportMenu,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == '全部') {
                  _selectedDepartment = null;
                } else {
                  _selectedDepartment = value;
                }
              });
              _loadWorkers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '全部', child: Text('全部班组')),
              ...AppConstants.departments.map(
                (d) => PopupMenuItem(value: d, child: Text(d)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '搜索姓名/工号/电话（多人用逗号或空格隔开）',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _onSearch(''),
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('在职', 'active'),
                  const SizedBox(width: 8),
                  _buildStatusChip('离职', 'leave'),
                  const SizedBox(width: 8),
                  _buildStatusChip('调岗', 'transfer'),
                  const SizedBox(width: 8),
                  _buildStatusChip('全部', null),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkers.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: '暂无人员信息',
                        subtitle: '点击右上角导入按钮批量添加，或点击+手动添加',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredWorkers.length,
                        itemBuilder: (context, index) {
                          final worker = _filteredWorkers[index];
                          return _buildWorkerCard(worker);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkerFormScreen(),
          ),
        ).then((_) => _loadWorkers()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? status) {
    final isSelected = _selectedStatus == (status ?? '');
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatus = status ?? '');
        _loadWorkers();
      },
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    final statusLabel =
        AppConstants.workerStatusLabels[worker.status] ?? worker.status;
    final statusColor = worker.status == 'active'
        ? AppColors.secondary
        : worker.status == 'leave'
            ? AppColors.danger
            : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerDetailScreen(worker: worker),
          ),
        ).then((_) => _loadWorkers()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0] : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${worker.employeeNo}  ${worker.jobType ?? '未设置工种'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (worker.department != null)
                      Text(
                        worker.department!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inactive,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.inactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
