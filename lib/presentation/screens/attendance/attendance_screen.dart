import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../widgets/empty_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final WorkerRepository _workerRepo = WorkerRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  DateTime _selectedDate = DateTime.now();
  List<Worker> _workers = [];
  Map<int, Attendance?> _attendanceMap = {};
  bool _isLoading = true;
  bool _batchMode = false;
  Set<int> _selectedWorkerIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final dateStr = DateUtils.formatDate(_selectedDate);
    final workers = await _workerRepo.getAll(status: 'active');
    final attendances = await _attendanceRepo.getByDate(dateStr);

    final attendanceMap = <int, Attendance?>{};
    for (final w in workers) {
      attendanceMap[w.id!] =
          attendances.where((a) => a.workerId == w.id).firstOrNull;
    }

    setState(() {
      _workers = workers;
      _attendanceMap = attendanceMap;
      _isLoading = false;
      _selectedWorkerIds.clear();
    });
  }

  Future<void> _recordAttendance(int workerId, String status) async {
    final dateStr = DateUtils.formatDate(_selectedDate);
    final now = DateTime.now();
    final timeStr = DateUtils.formatTime(now);

    final existing = _attendanceMap[workerId];
    Attendance attendance;

    if (existing != null) {
      attendance = existing.copyWith(status: status);
      if (status == 'normal' || status == 'late') {
        attendance = attendance.copyWith(checkInTime: timeStr);
      }
      await _attendanceRepo.update(attendance);
    } else {
      attendance = Attendance(
        workerId: workerId,
        date: dateStr,
        status: status,
        checkInTime: (status == 'normal' || status == 'late') ? timeStr : null,
      );
      await _attendanceRepo.insert(attendance);
    }

    _loadData();
  }

  Future<void> _batchRecord(String status) async {
    final dateStr = DateUtils.formatDate(_selectedDate);
    final now = DateTime.now();
    final timeStr = DateUtils.formatTime(now);

    final attendances = <Attendance>[];
    for (final workerId in _selectedWorkerIds) {
      attendances.add(Attendance(
        workerId: workerId,
        date: dateStr,
        status: status,
        checkInTime: (status == 'normal' || status == 'late') ? timeStr : null,
      ));
    }

    await _attendanceRepo.batchInsert(attendances);
    setState(() => _batchMode = false);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已批量标记${attendances.length}人')),
      );
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateUtils.formatDate(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('考勤管理'),
        actions: [
          if (!_batchMode)
            TextButton(
              onPressed: () => setState(() => _batchMode = true),
              child: const Text('批量'),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _batchMode = false;
                _selectedWorkerIds.clear();
              }),
              child: const Text('取消'),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${DateUtils.formatMonth(_selectedDate)} ${DateUtils.weekdayName(_selectedDate.weekday)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '今天',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDailyStats(),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _workers.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: '没有在职人员',
                        subtitle: '请先添加人员信息',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _workers.length,
                        itemBuilder: (context, index) {
                          final worker = _workers[index];
                          final attendance = _attendanceMap[worker.id];
                          return _buildAttendanceItem(worker, attendance);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _batchMode && _selectedWorkerIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _batchRecord('normal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                        child: Text('出勤 (${_selectedWorkerIds.length})'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _batchRecord('absent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        child: Text('缺勤 (${_selectedWorkerIds.length})'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _batchRecord('leave'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text('请假 (${_selectedWorkerIds.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDailyStats() {
    final stats = <String, int>{};
    for (final a in _attendanceMap.values) {
      if (a != null) {
        stats[a.status] = (stats[a.status] ?? 0) + 1;
      }
    }

    final normal = stats['normal'] ?? 0;
    final late = stats['late'] ?? 0;
    final absent = stats['absent'] ?? 0;
    final leave = stats['leave'] ?? 0;
    final total = _workers.length;
    final checked = normal + late + absent + leave;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('应到', total.toString(), AppColors.primaryText),
        _buildStatItem('出勤', '$normal', AppColors.secondary),
        _buildStatItem('迟到', '$late', AppColors.warning),
        _buildStatItem('缺勤', '$absent', AppColors.danger),
        _buildStatItem('请假', '$leave', AppColors.primary),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(Worker worker, Attendance? attendance) {
    final status = attendance?.status ?? 'unchecked';
    final statusLabel =
        AppConstants.attendanceStatusLabels[status] ?? '未打卡';
    final statusColor =
        AppConstants.attendanceStatusColors[status] ?? AppColors.inactive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _batchMode
            ? () {
                setState(() {
                  if (_selectedWorkerIds.contains(worker.id)) {
                    _selectedWorkerIds.remove(worker.id);
                  } else {
                    _selectedWorkerIds.add(worker.id!);
                  }
                });
              }
            : () => _showStatusPicker(worker),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (_batchMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _selectedWorkerIds.contains(worker.id)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _selectedWorkerIds.contains(worker.id)
                        ? AppColors.primary
                        : AppColors.inactive,
                  ),
                ),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  worker.name.isNotEmpty ? worker.name[0] : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (attendance?.checkInTime != null)
                      Text(
                        '打卡时间: ${attendance!.checkInTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(Worker worker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${worker.name} - 考勤状态',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatusButton(worker.id!, 'normal', '出勤', AppColors.secondary),
                  _buildStatusButton(worker.id!, 'late', '迟到', AppColors.warning),
                  _buildStatusButton(worker.id!, 'absent', '缺勤', AppColors.danger),
                  _buildStatusButton(worker.id!, 'leave', '请假', AppColors.primary),
                  _buildStatusButton(worker.id!, 'early', '早退', AppColors.warning),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(
      int workerId, String status, String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _recordAttendance(workerId, status);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
}
