import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('管理人员排班')),
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
