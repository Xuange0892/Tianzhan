import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/schedule.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../widgets/empty_state.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final WorkerRepository _workerRepo = WorkerRepository();
  final ScheduleRepository _scheduleRepo = ScheduleRepository();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String _selectedShift = '白班';
  List<Worker> _workers = [];
  List<Schedule> _monthSchedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final yearMonth =
        '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}';
    final workers = await _workerRepo.getAll(status: 'active');
    final schedules = await _scheduleRepo.getByMonth(yearMonth);

    setState(() {
      _workers = workers;
      _monthSchedules = schedules;
      _isLoading = false;
    });
  }

  Future<void> _addSchedule(int workerId) async {
    if (_selectedDate == null) return;

    final dateStr = DateUtils.formatDate(_selectedDate!);

    final hasConflict =
        await _scheduleRepo.hasSchedule(dateStr, workerId);
    if (hasConflict) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该人员当天已有排班')),
        );
      }
      return;
    }

    final schedule = Schedule(
      workerId: workerId,
      date: dateStr,
      shiftType: _selectedShift,
    );

    await _scheduleRepo.insert(schedule);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('排班成功')),
      );
    }
  }

  Future<void> _removeSchedule(int scheduleId) async {
    await _scheduleRepo.delete(scheduleId);
    _loadData();
  }

  List<Schedule> _getSchedulesForDate(DateTime date) {
    final dateStr = DateUtils.formatDate(date);
    return _monthSchedules.where((s) => s.date == dateStr).toList();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('值班排班'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendarHeader(),
                _buildCalendarGrid(),
                const Divider(height: 1),
                Expanded(
                  child: _buildDailyDetail(),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            DateUtils.formatMonth(_focusedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateUtils.firstDayOfMonth(_focusedMonth);
    final daysInMonth = DateUtils.daysInMonth(_focusedMonth);
    final startWeekday = firstDay.weekday % 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();

              final day = index - startWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = _selectedDate != null &&
                  DateUtils.isSameDay(date, _selectedDate!);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final schedules = _getSchedulesForDate(date);
              final hasSchedule = schedules.isNotEmpty;

              return InkWell(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : isToday
                            ? AppColors.primary.withOpacity(0.15)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? AppColors.primary : AppColors.primaryText,
                        ),
                      ),
                      if (hasSchedule)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDetail() {
    if (_selectedDate == null) {
      return const Center(
        child: Text('请选择日期', style: TextStyle(color: AppColors.secondaryText)),
      );
    }

    final dateStr = DateUtils.formatDate(_selectedDate!);
    final dateSchedules = _monthSchedules.where((s) => s.date == dateStr).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${DateUtils.formatDate(_selectedDate!)} ${DateUtils.weekdayName(_selectedDate!.weekday)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: AppConstants.shiftTypes
                    .map((s) => ButtonSegment(value: s, label: Text(s)))
                    .toList(),
                selected: {_selectedShift},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    setState(() => _selectedShift = set.first);
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppColors.primary;
                    }
                    return null;
                  }),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dateSchedules.isEmpty
              ? const EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: '当日暂无排班',
                  subtitle: '点击下方按钮添加',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: dateSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = dateSchedules[index];
                    final worker = _workers.firstWhere(
                      (w) => w.id == schedule.workerId,
                      orElse: () => Worker(name: '未知', employeeNo: ''),
                    );
                    return _buildScheduleItem(schedule, worker);
                  },
                ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddScheduleDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加排班'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule schedule, Worker worker) {
    final shiftTime = AppConstants.shiftTimeMap[schedule.shiftType] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            worker.name.isNotEmpty ? worker.name[0] : '?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          worker.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        subtitle: Text(
          '${schedule.shiftType} $shiftTime',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondaryText,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: () => _removeSchedule(schedule.id!),
        ),
      ),
    );
  }

  void _showAddScheduleDialog() {
    if (_selectedDate == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '选择人员 - ${_selectedShift}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _workers.length,
                    itemBuilder: (context, index) {
                      final worker = _workers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.2),
                            child: Text(
                              worker.name.isNotEmpty ? worker.name[0] : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            worker.name,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                            ),
                          ),
                          subtitle: Text(
                            '${worker.employeeNo} ${worker.jobType ?? ''}',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: AppColors.primary),
                          onTap: () {
                            Navigator.pop(context);
                            _addSchedule(worker.id!);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
