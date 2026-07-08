import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/repositories/app_settings_repository.dart';
import '../../../data/repositories/rest_day_repository.dart';
import '../../widgets/empty_state.dart';
import 'schedule_settings_screen.dart';
import 'manager_schedule_screen.dart';

/// 排班模块 - 根据3天轮换规则自动计算当日班组出勤
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _settingsRepo = AppSettingsRepository();
  final _restDayRepo = RestDayRepository();

  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  // 班组A配置
  Map<String, String> _groupA = {};
  // 班组B配置
  Map<String, String> _groupB = {};
  // 当月休息日列表
  List<String> _monthRestDays = [];
  // 选中日期是否为休息日
  bool _selectedIsRestDay = false;
  // 错误信息
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 根据3天轮换规则计算出勤安排
  /// 返回 {夜班, 午班, 检修} 对应的班组名
  Map<String, String> _calcDayShifts(Map<String, String> configs, DateTime date) {
    final baseDateStr = configs['base_date'];
    if (baseDateStr == null || baseDateStr.isEmpty) return {};
    final baseDate = AppDateUtils.parseDate(baseDateStr);
    if (baseDate == null) return {};

    // 计算在3天周期中的位置
    final offset = date.difference(baseDate).inDays;
    final dayInCycle = ((offset % 3) + 3) % 3;

    final prod1 = configs['prod1'] ?? '';
    final prod2 = configs['prod2'] ?? '';
    final prod3 = configs['prod3'] ?? '';
    final repair = configs['repair'] ?? '';

    switch (dayInCycle) {
      case 0:
        return {'夜班': prod1, '午班': prod2, '检修': repair};
      case 1:
        return {'夜班': prod3, '午班': prod1, '检修': repair};
      case 2:
        return {'夜班': prod2, '午班': prod3, '检修': repair};
      default:
        return {};
    }
  }

  /// 统计当月各班组出勤天数
  Map<String, int> _calcMonthStats(Map<String, String> configs) {
    final stats = <String, int>{};
    final daysInMonth = AppDateUtils.daysInMonth(_currentMonth);
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final dateStr = AppDateUtils.formatDate(date);
      // 跳过休息日
      if (_monthRestDays.contains(dateStr)) continue;

      final shifts = _calcDayShifts(configs, date);
      for (final entry in shifts.entries) {
        final name = entry.value;
        if (name.isNotEmpty) {
          stats[name] = (stats[name] ?? 0) + 1;
        }
      }
    }
    return stats;
  }

  Future<void> _load() async {
    try {
      final aConfigs = await _settingsRepo.getGroupConfigs('group_a');
      final bConfigs = await _settingsRepo.getGroupConfigs('group_b');

      // 获取当月休息日
      final monthStr =
          '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
      final restDays = await _restDayRepo.getByMonth(monthStr);

      // 检查选中日期是否为休息日
      final selectedStr = AppDateUtils.formatDate(_selectedDate);
      final isRest = await _restDayRepo.isRestDay(selectedStr);

      if (mounted) {
        setState(() {
          _groupA = aConfigs;
          _groupB = bConfigs;
          _monthRestDays = restDays.map((r) => r.date).toList();
          _selectedIsRestDay = isRest;
          _loading = false;
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = '加载排班配置失败：$e';
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _load();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _load();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('值班排班'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleSettingsScreen()),
            ).then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerScheduleScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMsg!, style: TextStyle(color: AppColors.secondaryText(isDark)), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('重试')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 月份选择器
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _prevMonth,
                            ),
                            Text(
                              '${_currentMonth.year}年${_currentMonth.month}月',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText(isDark),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 日历网格
                        _buildCalendar(isDark),
                        const SizedBox(height: 20),

                        // 选中日期标题
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppDateUtils.formatDate(_selectedDate),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText(isDark),
                              ),
                            ),
                            Text(
                              AppDateUtils.weekdayName(_selectedDate.weekday),
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 休息日提示
                        if (_selectedIsRestDay)
                          Card(
                            color: isDark ? AppColors.darkSurfaceLight : Colors.grey[100],
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.beach_access, color: AppColors.secondaryText(isDark)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '休息日，排班顺延',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondaryText(isDark),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '当日排班自动向后顺延一天执行',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.inactiveColor(isDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 班组A出勤卡片
                        if (_groupA.isNotEmpty) ...[
                          _buildGroupCard(
                            isDark: isDark,
                            configs: _groupA,
                            date: _selectedDate,
                            title: _groupA['group_name'] ?? '班组A',
                            isRest: _selectedIsRestDay,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 班组B出勤卡片
                        if (_groupB.isNotEmpty) ...[
                          _buildGroupCard(
                            isDark: isDark,
                            configs: _groupB,
                            date: _selectedDate,
                            title: _groupB['group_name'] ?? '班组B',
                            isRest: _selectedIsRestDay,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 无配置提示
                        if (_groupA.isEmpty && _groupB.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  '暂未配置排班，请先设置班组排班',
                                  style: TextStyle(
                                    color: AppColors.secondaryText(isDark),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 月统计
                        const SizedBox(height: 24),
                        Text(
                          '本月排班统计',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText(isDark),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMonthStats(isDark),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 构建班组出勤卡片
  Widget _buildGroupCard({
    required bool isDark,
    required Map<String, String> configs,
    required DateTime date,
    required String title,
    required bool isRest,
  }) {
    final shifts = _calcDayShifts(configs, date);

    // 卡片背景色：休息日时灰色
    Color cardBg = AppColors.cardColor(isDark);
    Color titleColor = AppColors.primary;
    if (isRest) {
      cardBg = isDark ? AppColors.darkSurfaceLight : Colors.grey[100]!;
      titleColor = AppColors.inactiveColor(isDark);
    }

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 班组名标题
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: titleColor.withOpacity(0.1),
                  child: Text(
                    title.isNotEmpty ? title[0] : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isRest
                        ? AppColors.secondaryText(isDark)
                        : AppColors.primaryText(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 各岗位出勤
            if (shifts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '配置不完整，无法计算排班',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText(isDark),
                  ),
                ),
              )
            else
              ...shifts.entries.map((entry) {
                // 岗位图标
                IconData icon;
                Color iconColor;
                switch (entry.key) {
                  case '夜班':
                    icon = Icons.nightlight_round;
                    iconColor = Colors.indigo;
                    break;
                  case '午班':
                    icon = Icons.wb_sunny;
                    iconColor = AppColors.warning;
                    break;
                  case '检修':
                    icon = Icons.build;
                    iconColor = AppColors.secondary;
                    break;
                  default:
                    icon = Icons.work;
                    iconColor = AppColors.primary;
                }

                final name = entry.value;
                if (isRest) iconColor = AppColors.inactiveColor(isDark);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: 10),
                      Text(
                        '${entry.key}：',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText(isDark),
                        ),
                      ),
                      Text(
                        name.isNotEmpty ? name : '未配置',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isRest
                              ? AppColors.secondaryText(isDark)
                              : AppColors.primaryText(isDark),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// 构建日历网格
  Widget _buildCalendar(bool isDark) {
    final daysInMonth = AppDateUtils.daysInMonth(_currentMonth);
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // 1号是周几 (1=周一 ... 7=周日)
    int startWeekday = firstDay.weekday;

    return Table(
      children: [
        // 表头
        TableRow(
          children: ['一', '二', '三', '四', '五', '六', '日'].map((d) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // 日期格子
        for (int row = 0; row < 6; row++) ...[
          if (row * 7 - startWeekday + 1 <= daysInMonth)
            TableRow(
              children: List.generate(7, (col) {
                final day = row * 7 + col - startWeekday + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox(height: 40);
                }
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final dateStr = AppDateUtils.formatDate(date);
                final isSelected = AppDateUtils.isSameDay(date, _selectedDate);
                final isToday = AppDateUtils.isSameDay(date, DateTime.now());
                final isRest = _monthRestDays.contains(dateStr);
                // 有排班配置且有基准日期的日期显示小圆点
                final hasSchedule =
                    _groupA.containsKey('base_date') || _groupB.containsKey('base_date');

                return GestureDetector(
                  onTap: () => _onDateSelected(date),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday
                              ? AppColors.primary.withOpacity(0.1)
                              : (isRest
                                  ? (isDark
                                      ? AppColors.darkSurfaceLight
                                      : Colors.grey[200])
                                  : null)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : (isRest
                                    ? AppColors.inactiveColor(isDark)
                                    : (isToday
                                        ? AppColors.primary
                                        : AppColors.primaryText(isDark))),
                            fontWeight:
                                isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // 排班日期标记小圆点
                        if (hasSchedule && !isRest)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ],
    );
  }

  /// 月统计
  Widget _buildMonthStats(bool isDark) {
    // 合并两个班组的统计
    final statsA = _groupA.isNotEmpty ? _calcMonthStats(_groupA) : <String, int>{};
    final statsB = _groupB.isNotEmpty ? _calcMonthStats(_groupB) : <String, int>{};

    // 去重合并
    final allStats = <String, int>{};
    for (final e in statsA.entries) {
      allStats[e.key] = (allStats[e.key] ?? 0) + e.value;
    }
    for (final e in statsB.entries) {
      allStats[e.key] = (allStats[e.key] ?? 0) + e.value;
    }

    if (allStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '本月暂无排班统计',
            style: TextStyle(color: AppColors.secondaryText(isDark)),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: allStats.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${e.key}：',
                style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark)),
              ),
              Text(
                '${e.value}天',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
