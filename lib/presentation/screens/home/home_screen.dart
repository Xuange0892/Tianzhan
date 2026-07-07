import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../../data/repositories/certificate_repository.dart';
import '../../../data/repositories/sign_in_repository.dart';
import '../../widgets/stat_card.dart';
import '../todos/todo_screen.dart';
import '../certificates/certificate_list_screen.dart';
import '../workers/worker_list_screen.dart';
import '../sign_in/sign_in_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WorkerRepository _workerRepo = WorkerRepository();
  final TodoRepository _todoRepo = TodoRepository();
  final CertificateRepository _certRepo = CertificateRepository();
  final SignInRepository _signInRepo = SignInRepository();

  int _activeWorkerCount = 0;
  int _pendingTodoCount = 0;
  int _expiringCertCount = 0;
  int _signInEventCount = 0;
  List<Map<String, dynamic>> _pendingTodos = [];
  List<Map<String, dynamic>> _expiringCerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activeCount = await _workerRepo.getCount(status: 'active');
      final pendingCount = await _todoRepo.getPendingCount();
      final expiringCount = await _certRepo.getExpiringCount(30);
      final pendingTodos = await _todoRepo.getPendingTop(5);
      final expiringWorkers = await _workerRepo.getExpiringCertificates(30);
      final signInEvents = await _signInRepo.getAllEvents();

      if (!mounted) return;
      setState(() {
        _activeWorkerCount = activeCount;
        _pendingTodoCount = pendingCount;
        _expiringCertCount = expiringCount + expiringWorkers.length;
        _signInEventCount = signInEvents.length;
        _pendingTodos = pendingTodos.map((t) => {'id': t.id, 'title': t.title, 'due_date': t.dueDate, 'priority': t.priority}).toList();
        _expiringCerts = expiringWorkers.take(3).map((w) => {'name': w.name, 'certificate_no': w.certificateNo, 'expire_date': w.certificateExpireDate}).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 24),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildQuickActions(isDark),
                    const SizedBox(height: 28),
                    if (_pendingTodos.isNotEmpty) ...[
                      _buildSectionHeader('待办事项', Icons.task_outlined, isDark, onTap: () => _nav(const TodoScreen())),
                      const SizedBox(height: 12),
                      ..._pendingTodos.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildTodoItem(t, isDark))),
                      const SizedBox(height: 24),
                    ],
                    if (_expiringCerts.isNotEmpty) ...[
                      _buildSectionHeader('证件到期提醒', Icons.notification_important_outlined, isDark, onTap: () => _nav(const CertificateListScreen())),
                      const SizedBox(height: 12),
                      ..._expiringCerts.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildExpiryItem(c, isDark))),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _nav(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _buildHeader(bool isDark) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppDateUtils.formatMonth(now), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText(isDark))),
            const SizedBox(height: 2),
            Text('${AppDateUtils.weekdayName(now.weekday)}  ${AppDateUtils.formatDate(now)}', style: TextStyle(fontSize: 14, color: AppColors.secondaryText(isDark))),
          ],
        ),
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: AppColors.primaryText(isDark)),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          tooltip: '切换主题',
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
      childAspectRatio: 1.3,
      children: [
        StatCard(label: '在职人数', value: '$_activeWorkerCount', icon: Icons.people_outline, color: AppColors.primary),
        StatCard(label: '今日待办', value: '$_pendingTodoCount', icon: Icons.task_alt_outlined, color: AppColors.secondary),
        StatCard(label: '证件将到期', value: '$_expiringCertCount', icon: Icons.badge_outlined, color: AppColors.warning),
        StatCard(label: '签到事项', value: '$_signInEventCount', icon: Icons.fact_check_outlined, color: AppColors.primaryLight),
      ],
    );
  }

  Widget _buildQuickActions(bool isDark) {
    final actions = <_Action>[
      _Action('人员管理', Icons.people_outline, const WorkerListScreen()),
      _Action('签到统计', Icons.fact_check_outlined, const SignInScreen()),
      _Action('值班排班', Icons.calendar_month_outlined, const ScheduleScreen()),
      _Action('证件管理', Icons.badge_outlined, const CertificateListScreen()),
      _Action('待办事项', Icons.checklist_outlined, const TodoScreen()),
      _Action('系统设置', Icons.settings_outlined, const SettingsScreen()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷功能', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: actions.map((a) => _buildActionTile(a, isDark)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionTile(_Action a, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _nav(a.page),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(a.icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(a.label, style: TextStyle(fontSize: 12, color: AppColors.primaryText(isDark)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [Icon(icon, color: AppColors.primary, size: 18), const SizedBox(width: 6), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark)))]),
        if (onTap != null) TextButton(onPressed: onTap, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: const Text('查看全部', style: TextStyle(fontSize: 13, color: AppColors.primary))),
      ],
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> todo, bool isDark) {
    final colors = {'high': AppColors.danger, 'medium': AppColors.warning, 'low': AppColors.secondary};
    final labels = {'high': '高', 'medium': '中', 'low': '低'};
    final pColor = colors[todo['priority']] ?? AppColors.secondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(Icons.radio_button_unchecked, color: AppColors.inactiveColor(isDark), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(todo['title'] as String, style: TextStyle(fontSize: 14, color: AppColors.primaryText(isDark)), overflow: TextOverflow.ellipsis)),
          if (todo['due_date'] != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(todo['due_date'] as String, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark)))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(labels[todo['priority']] ?? '中', style: TextStyle(fontSize: 11, color: pColor, fontWeight: FontWeight.w500))),
        ]),
      ),
    );
  }

  Widget _buildExpiryItem(Map<String, dynamic> cert, bool isDark) {
    final days = AppDateUtils.daysUntilExpiry(cert['expire_date'] as String?);
    final isExpired = days < 0;
    final color = isExpired ? AppColors.danger : (days <= 7 ? AppColors.warning : AppColors.secondary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(Icons.warning_amber_outlined, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(cert['name'] as String, style: TextStyle(fontSize: 14, color: AppColors.primaryText(isDark)))),
          Text(isExpired ? '已过期${-days}天' : '还有$days天', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Widget page;
  _Action(this.label, this.icon, this.page);
}
