import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../widgets/empty_state.dart';
import 'schedule_settings_screen.dart';
import 'manager_schedule_screen.dart';

/// 排班模块
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _scheduleRepo = ScheduleRepository();
  final _workerRepo = WorkerRepository();
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _monthSchedules = [];
  Map<String, int> _shiftStats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final monthStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    final stats = await _scheduleRepo.getShiftStatsByMonth(monthStr);
    final selectedStr = AppDateUtils.formatDate(_selectedDate);
    final daySchedules = await _scheduleRepo.getByDate(selectedStr);
    // 关联人员名
    final allWorkers = await _workerRepo.getAll();
    final workerMap = {for (var w in allWorkers) w.id!: w};

    if (mounted) setState(() {
      _shiftStats = stats;
      _schedules = daySchedules.map((s) {
        final w = workerMap[s.workerId];
        return {'id': s.id, 'workerName': w?.name ?? '未知', 'employeeNo': w?.employeeNo ?? '', 'shift': s.shiftType, 'position': s.position};
      }).toList();
      _loading = false;
    });
  }

  void _prevMonth() { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1); _load(); }); }
  void _nextMonth() { setState(() { _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1); _load(); }); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('值班排班'), actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen())).then((_) => _load())),
        IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerScheduleScreen()))),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 月份选择器
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
              Text('${_currentMonth.year}年${_currentMonth.month}月', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
            ]),
            const SizedBox(height: 16),

            // 日历网格（简化版）
            _buildCalendar(isDark),
            const SizedBox(height: 20),

            // 选中日期的排班
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(AppDateUtils.formatDate(_selectedDate), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
              Text('${AppDateUtils.weekdayName(_selectedDate.weekday)}', style: TextStyle(fontSize: 14, color: AppColors.secondaryText(isDark))),
            ]),
            const SizedBox(height: 12),

            if (_schedules.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('当日暂无排班', style: TextStyle(color: AppColors.secondaryText(isDark))))))
            else
              ..._schedules.map((s) => Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text((s['workerName'] as String).isNotEmpty ? (s['workerName'] as String)[0] : '?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['workerName'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
                      Text(s['position'] ?? s['shift'] as String, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark))),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(s['shift'] as String, style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                  ]),
                ),
              )),

            // 月统计
            const SizedBox(height: 24),
            Text('本月排班统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _shiftStats.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${e.key}：', style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark))),
                  Text('${e.value}次', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ]),
              )).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    final daysInMonth = AppDateUtils.daysInMonth(_currentMonth);
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // 1号是周几 (1=周一 ... 7=周日)
    int startWeekday = firstDay.weekday;

    return Table(
      children: [
        // 表头
        TableRow(children: ['一', '二', '三', '四', '五', '六', '日'].map((d) => Padding(
          padding: const EdgeInsets.all(4),
          child: Center(child: Text(d, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark), fontWeight: FontWeight.w500))),
        )).toList()),
        // 日期格子
        for (int row = 0; row < 6; row++) ...[
          if (row * 7 - startWeekday + 1 <= daysInMonth)
            TableRow(children: List.generate(7, (col) {
              final day = row * 7 + col - startWeekday + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox(height: 36);
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = AppDateUtils.isSameDay(date, _selectedDate);
              final isToday = AppDateUtils.isSameDay(date, DateTime.now());
              return GestureDetector(
                onTap: () { setState(() => _selectedDate = date); _load(); },
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isToday ? AppColors.primary.withOpacity(0.1) : null),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('$day', style: TextStyle(fontSize: 14,
                      color: isSelected ? Colors.white : (isToday ? AppColors.primary : AppColors.primaryText(isDark)),
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              );
            })),
        ],
      ],
    );
  }
}
