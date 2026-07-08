import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/manager_schedule.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/manager_schedule_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../widgets/empty_state.dart';

/// 管理人员排班
class ManagerScheduleScreen extends StatefulWidget {
  const ManagerScheduleScreen({super.key});

  @override
  State<ManagerScheduleScreen> createState() => _ManagerScheduleScreenState();
}

class _ManagerScheduleScreenState extends State<ManagerScheduleScreen> {
  final _repo = ManagerScheduleRepository();
  final _workerRepo = WorkerRepository();

  List<Worker> _activeWorkers = [];
  List<ManagerSchedule> _schedules = [];
  Map<int, Worker> _workerMap = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final workers = await _workerRepo.getAll(status: 'active');
    final now = DateTime.now();
    final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final schedules = await _repo.getByMonth(monthStr);
    final workerMap = {for (var w in workers) w.id!: w};
    if (mounted) setState(() { _activeWorkers = workers; _schedules = schedules; _workerMap = workerMap; _loading = false; });
  }

  Future<void> _addSchedule() async {
    final dateCtrl = TextEditingController(text: AppDateUtils.formatDate(DateTime.now()));
    final posCtrl = TextEditingController();
    int? selectedWorkerId;

    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialog) => AlertDialog(
        title: const Text('添加管理人员排班'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: dateCtrl, decoration: const InputDecoration(labelText: '日期'), readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) dateCtrl.text = AppDateUtils.formatDate(picked);
            }),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: '人员'),
            items: _activeWorkers.map((w) => DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.employeeNo})'))).toList(),
            onChanged: (v) => setDialog(() => selectedWorkerId = v),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: posCtrl, decoration: const InputDecoration(labelText: '岗位')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            if (selectedWorkerId == null || dateCtrl.text.isEmpty) return;
            Navigator.pop(ctx, true);
          }, child: const Text('添加')),
        ],
      ),
    ));

    if (result == true && selectedWorkerId != null) {
      await _repo.insert(ManagerSchedule(workerId: selectedWorkerId!, date: dateCtrl.text, position: posCtrl.text.trim().isEmpty ? null : posCtrl.text.trim()));
      _load();
    }
  }

  /// CSV导入功能
  Future<void> _importCsv() async {
    // 选择CSV文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.first.path;
    if (filePath == null) return;

    try {
      // 读取文件内容
      final file = File(filePath);
      final csvContent = await file.readAsString();

      // 解析CSV
      final rows = const CsvToListConverter().convert(csvContent);
      if (rows.isEmpty) {
        if (mounted) _showSnackBar('CSV文件为空', isError: true);
        return;
      }

      // 验证表头：姓名,工号,日期,岗位
      final header = rows[0].map((e) => e.toString().trim()).toList();
      if (header.length < 4 ||
          header[0] != '姓名' ||
          header[1] != '工号' ||
          header[2] != '日期' ||
          header[3] != '岗位') {
        if (mounted) _showSnackBar('CSV格式错误，表头须为：姓名,工号,日期,岗位', isError: true);
        return;
      }

      // 获取所有人员列表用于匹配
      final allWorkers = await _workerRepo.getAll();

      // 按工号建立索引
      final empNoMap = <String, Worker>{};
      for (final w in allWorkers) {
        if (w.employeeNo != null && w.employeeNo!.isNotEmpty) {
          empNoMap[w.employeeNo!] = w;
        }
      }

      // 按姓名建立索引
      final nameMap = <String, List<Worker>>{};
      for (final w in allWorkers) {
        if (w.name.isNotEmpty) {
          nameMap.putIfAbsent(w.name, () => []).add(w);
        }
      }

      // 解析数据行
      final records = <ManagerSchedule>[];
      int failCount = 0;
      final errors = <String>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) {
          failCount++;
          errors.add('第${i + 1}行：列数不足');
          continue;
        }

        final name = row[0].toString().trim();
        final empNo = row[1].toString().trim();
        final dateStr = row[2].toString().trim();
        final position = row[3].toString().trim();

        // 校验日期格式
        final parsedDate = AppDateUtils.parseDate(dateStr);
        if (parsedDate == null) {
          failCount++;
          errors.add('第${i + 1}行：日期格式错误($dateStr)');
          continue;
        }

        // 匹配worker_id：优先按工号+姓名匹配，其次按工号匹配，最后按姓名匹配
        int? workerId;
        final workerByEmpNo = empNoMap[empNo];
        if (workerByEmpNo != null) {
          // 工号存在，进一步校验姓名
          if (workerByEmpNo.name == name) {
            workerId = workerByEmpNo.id;
          } else {
            failCount++;
            errors.add('第${i + 1}行：工号$empNo对应姓名不匹配(期望${workerByEmpNo.name}，实际$name)');
            continue;
          }
        } else if (name.isNotEmpty && nameMap.containsKey(name)) {
          // 工号不存在，尝试按姓名匹配
          final candidates = nameMap[name]!;
          if (candidates.length == 1) {
            workerId = candidates.first.id;
          } else {
            failCount++;
            errors.add('第${i + 1}行：同名人员${candidates.length}人，无法匹配');
            continue;
          }
        } else {
          failCount++;
          errors.add('第${i + 1}行：未找到人员($name,$empNo)');
          continue;
        }

        records.add(ManagerSchedule(
          workerId: workerId!,
          date: AppDateUtils.formatDate(parsedDate),
          position: position.isEmpty ? null : position,
        ));
      }

      // 批量导入
      if (records.isNotEmpty) {
        final successCount = await _repo.batchImport(records);
        if (mounted) {
          final msg = '导入完成：成功${successCount}条' +
              (failCount > 0 ? '，失败${failCount}条' : '');
          _showSnackBar(msg, isError: failCount > 0);

          // 如果有错误，弹窗显示详情
          if (errors.isNotEmpty) {
            _showErrorDetailDialog(errors);
          }
        }
      } else {
        if (mounted) _showSnackBar('无有效记录可导入', isError: true);
      }

      // 刷新列表
      _load();
    } catch (e) {
      if (mounted) _showSnackBar('导入失败：$e', isError: true);
    }
  }

  /// 显示导入结果弹窗
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  /// 显示导入错误详情
  void _showErrorDetailDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入错误详情'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                errors[i],
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理人员排班'),
        actions: [
          // CSV导入按钮
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入CSV',
            onPressed: _importCsv,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'mgr_schedule_fab',
        onPressed: _addSchedule,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? EmptyState(icon: Icons.calendar_today_outlined, title: '暂无管理人员排班')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _schedules.length,
                  itemBuilder: (_, i) {
                    final s = _schedules[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Dismissible(
                          key: Key('mgr_${s.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: AppColors.danger, child: const Icon(Icons.delete, color: Colors.white)),
                          onDismissed: (_) async { await _repo.delete(s.id!); _load(); },
                          child: ListTile(
                            leading: const Icon(Icons.person_outline, color: AppColors.primary),
                            title: Text(_workerMap[s.workerId]?.name ?? '未知', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
                            subtitle: Text('${s.date}  ${s.position ?? ''}', style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
