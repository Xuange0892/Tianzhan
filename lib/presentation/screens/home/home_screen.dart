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
        _pendingTodos = pendingTodos.map((t) => {
          'id': t.id,
          'title': t.title,
          'due_date': t.dueDate,
          'priority': t.priority,
        }).toList();
        _expiringCerts = expiringWorkers.take(3).map((w) => {
          'name': w.name,
          'certificate_no': w.certificateNo,
          'expire_date': w.certificateExpireDate,
        }).toList();
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
                    // 待办事项区域（醒目位置）
                    _buildTodoSection(isDark),
                    const SizedBox(height: 24),
                    // 统计卡片
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    // 快捷功能按钮
                    _buildQuickActions(isDark),
                    const SizedBox(height: 28),
                    // 证件到期提醒
                    if (_expiringCerts.isNotEmpty) ...[
                      _buildSectionHeader('证件到期提醒', Icons.notification_important_outlined, isDark,
                          onTap: () => _nav(const CertificateListScreen())),
                      const SizedBox(height: 12),
                      ..._expiringCerts.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildExpiryItem(c, isDark))),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  void _nav(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  /// 顶部日期标题 + 主题切换按钮
  Widget _buildHeader(bool isDark) {
    final now = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppDateUtils.formatMonth(now),
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(isDark))),
            const SizedBox(height: 2),
            Text('${AppDateUtils.weekdayName(now.weekday)}  ${AppDateUtils.formatDate(now)}',
                style: TextStyle(
                    fontSize: 14, color: AppColors.secondaryText(isDark))),
          ],
        ),
        IconButton(
          icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.primaryText(isDark)),
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          tooltip: '切换主题',
        ),
      ],
    );
  }

  /// 待办事项醒目区域
  Widget _buildTodoSection(bool isDark) {
    // 优先级颜色映射
    final priorityColors = {
      'high': AppColors.danger,
      'medium': AppColors.warning,
      'low': AppColors.secondary,
    };
    final priorityLabels = {'high': '高', 'medium': '中', 'low': '低'};

    return Container(
      // 浅色卡片背景
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行：图标 + "待办事项" + 未完成数量 badge + 查看全部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // 主色图标
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  // 醒目标题
                  Text(
                    '待办事项',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText(isDark),
                    ),
                  ),
                  // 未完成数量 badge
                  if (_pendingTodoCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_pendingTodoCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // 查看全部链接
              GestureDetector(
                onTap: () => _nav(const TodoScreen()),
                child: Row(
                  children: const [
                    Text(
                      '查看全部',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 待办列表或空状态
          if (_pendingTodos.isEmpty)
            // 空状态提示
            _buildTodoEmptyState(isDark)
          else ...[
            // 逐条显示待办
            ..._pendingTodos.map((todo) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildTodoCard(todo, isDark, priorityColors, priorityLabels),
                )),
            // 超出显示 "查看更多" 链接（当总数大于5时）
            if (_pendingTodoCount > 5)
              Center(
                child: GestureDetector(
                  onTap: () => _nav(const TodoScreen()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '还有 ${_pendingTodoCount - 5} 项待办，查看更多',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward,
                          color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// 待办空状态
  Widget _buildTodoEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.secondary.withOpacity(0.6),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              '暂无待办事项',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText(isDark),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '所有任务已完成，继续保持！',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.inactiveColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 单条待办卡片（带左侧优先级色条）
  Widget _buildTodoCard(
    Map<String, dynamic> todo,
    bool isDark,
    Map<String, Color> priorityColors,
    Map<String, String> priorityLabels,
  ) {
    final priority = todo['priority'] as String? ?? 'medium';
    final pColor = priorityColors[priority] ?? AppColors.secondary;
    final pLabel = priorityLabels[priority] ?? '中';
    final dueDate = todo['due_date'] as String?;

    // 判断是否快到期或已过期
    final bool isUrgent = dueDate != null && _isUrgentDueDate(dueDate);

    return GestureDetector(
      // 点击跳转到待办事项列表页
      onTap: () => _nav(const TodoScreen()),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor(isDark).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // 左侧优先级色条
            Container(
              width: 4,
              height: 56,
              color: pColor,
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // 标题
                    Expanded(
                      child: Text(
                        todo['title'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText(isDark),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 截止日期（快到期/已过期显示红色）
                    if (dueDate != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? AppColors.danger.withOpacity(0.08)
                              : AppColors.inactiveColor(isDark).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDueDate(dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: isUrgent
                                ? AppColors.danger
                                : AppColors.secondaryText(isDark),
                            fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    // 优先级标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: pColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 判断截止日期是否快到期（3天内）或已过期
  bool _isUrgentDueDate(String dueDateStr) {
    try {
      // dueDate 格式可能是 "2025-01-15" 或 ISO8601
      final due = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      // 忽略时间部分，只比较日期
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;
      // 已过期或3天内到期
      return diff <= 3;
    } catch (_) {
      return false;
    }
  }

  /// 格式化截止日期显示（只显示月-日）
  String _formatDueDate(String dueDateStr) {
    try {
      final due = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;

      if (diff < 0) {
        return '已过期${-diff}天';
      } else if (diff == 0) {
        return '今天到期';
      } else if (diff == 1) {
        return '明天到期';
      } else if (diff <= 3) {
        return '${diff}天后到期';
      } else {
        // 显示日期
        return '${due.month}/${due.day}';
      }
    } catch (_) {
      return dueDateStr;
    }
  }

  /// 统计卡片网格（4个）
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
            label: '在职人数',
            value: '$_activeWorkerCount',
            icon: Icons.people_outline,
            color: AppColors.primary),
        StatCard(
            label: '今日待办',
            value: '$_pendingTodoCount',
            icon: Icons.task_alt_outlined,
            color: AppColors.secondary),
        StatCard(
            label: '证件将到期',
            value: '$_expiringCertCount',
            icon: Icons.badge_outlined,
            color: AppColors.warning),
        StatCard(
            label: '签到事项',
            value: '$_signInEventCount',
            icon: Icons.fact_check_outlined,
            color: AppColors.primaryLight),
      ],
    );
  }

  /// 快捷功能按钮（6个）
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
        Text('快捷功能',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(isDark))),
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
          border: Border.all(
              color: Theme.of(context).colorScheme.outline, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(a.icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(a.label,
                style: TextStyle(
                    fontSize: 12, color: AppColors.primaryText(isDark)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// 通用 section 标题
  Widget _buildSectionHeader(String title, IconData icon, bool isDark,
      {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText(isDark))),
          ],
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('查看全部',
                style:
                    TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
      ],
    );
  }

  /// 证件到期提醒项
  Widget _buildExpiryItem(Map<String, dynamic> cert, bool isDark) {
    final days = AppDateUtils.daysUntilExpiry(cert['expire_date'] as String?);
    final isExpired = days < 0;
    final color = isExpired
        ? AppColors.danger
        : (days <= 7 ? AppColors.warning : AppColors.secondary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(cert['name'] as String,
                    style: TextStyle(
                        fontSize: 14, color: AppColors.primaryText(isDark)))),
            Text(
              isExpired ? '已过期${-days}天' : '还有$days天',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
