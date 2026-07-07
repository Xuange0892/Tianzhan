import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/schedule_repository.dart';
import '../workers/worker_list_screen.dart';
import '../attendance/attendance_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WorkerRepository _workerRepo = WorkerRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final ScheduleRepository _scheduleRepo = ScheduleRepository();

  int _totalWorkers = 0;
  int _todayAttendance = 0;
  int _todayAbsent = 0;
  int _todaySchedule = 0;
  List<Worker> _expiringWorkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final today = AppDateUtils.formatDate(DateTime.now());
    final workers = await _workerRepo.getAll(status: 'active');
    final todayAttendance = await _attendanceRepo.getByDate(today);
    final todaySchedules = await _scheduleRepo.getByDate(today);
    final expiring = await _workerRepo.getExpiringCertificates(30);

    final normalCount =
        todayAttendance.where((a) => a.status == 'normal').length;
    final absentCount =
        todayAttendance.where((a) => a.status == 'absent').length +
            todayAttendance.where((a) => a.status == 'late').length;

    setState(() {
      _totalWorkers = workers.length;
      _todayAttendance = normalCount;
      _todayAbsent = absentCount;
      _todaySchedule = todaySchedules.length;
      _expiringWorkers = expiring;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('掘进助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    if (_expiringWorkers.isNotEmpty) ...[
                      _buildExpiryAlerts(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppDateUtils.formatMonth(now),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppDateUtils.weekdayName(now.weekday)}  ${AppDateUtils.formatDate(now)}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          '在职人员',
          '$_totalWorkers',
          Icons.people_outline,
          AppColors.primary,
        ),
        _buildStatCard(
          '今日出勤',
          '$_todayAttendance',
          Icons.check_circle_outline,
          AppColors.secondary,
        ),
        _buildStatCard(
          '缺勤/迟到',
          '$_todayAbsent',
          Icons.warning_amber_outlined,
          AppColors.warning,
        ),
        _buildStatCard(
          '今日排班',
          '$_todaySchedule',
          Icons.calendar_today_outlined,
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷功能',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                '人员管理',
                Icons.people,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkerListScreen()),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                '考勤打卡',
                Icons.fingerprint,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AttendanceScreen()),
                ).then((_) => _loadData()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                '值班排班',
                Icons.calendar_month,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ScheduleScreen()),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                '数据统计',
                Icons.bar_chart,
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notification_important,
                color: AppColors.danger, size: 18),
            const SizedBox(width: 6),
            Text(
              '证件到期提醒 (${_expiringWorkers.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: AppColors.danger.withOpacity(0.1),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expiringWorkers.length.clamp(0, 3),
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) {
              final worker = _expiringWorkers[index];
              final days = AppDateUtils.daysUntilExpiry(
                  worker.certificateExpireDate);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.badge_outlined,
                    color: AppColors.danger, size: 20),
                title: Text(
                  worker.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                  ),
                ),
                subtitle: Text(
                  '证件号: ${worker.certificateNo ?? '无'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                trailing: Text(
                  days >= 0 ? '还有$days天' : '已过期${-days}天',
                  style: TextStyle(
                    fontSize: 12,
                    color: days >= 0 ? AppColors.warning : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
