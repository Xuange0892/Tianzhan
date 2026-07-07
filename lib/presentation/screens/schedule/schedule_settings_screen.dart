import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/repositories/app_settings_repository.dart';

/// 排班设置
class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  final _repo = AppSettingsRepository();

  // 班组A
  final _aGroupName = TextEditingController();
  final _aRepair = TextEditingController();
  final _aProd1 = TextEditingController();
  final _aProd2 = TextEditingController();
  final _aProd3 = TextEditingController();
  final _aBaseDate = TextEditingController();

  // 班组B
  final _bGroupName = TextEditingController();
  final _bRepair = TextEditingController();
  final _bProd1 = TextEditingController();
  final _bProd2 = TextEditingController();
  final _bProd3 = TextEditingController();
  final _bBaseDate = TextEditingController();

  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final aConfigs = await _repo.getGroupConfigs('group_a');
    final bConfigs = await _repo.getGroupConfigs('group_b');
    if (mounted) setState(() {
      _aGroupName.text = aConfigs['group_name'] ?? '班组A';
      _aRepair.text = aConfigs['repair'] ?? '检修班';
      _aProd1.text = aConfigs['prod1'] ?? '生产一班';
      _aProd2.text = aConfigs['prod2'] ?? '生产二班';
      _aProd3.text = aConfigs['prod3'] ?? '生产三班';
      _aBaseDate.text = aConfigs['base_date'] ?? '';
      _bGroupName.text = bConfigs['group_name'] ?? '班组B';
      _bRepair.text = bConfigs['repair'] ?? '检修班';
      _bProd1.text = bConfigs['prod1'] ?? '生产一班';
      _bProd2.text = bConfigs['prod2'] ?? '生产二班';
      _bProd3.text = bConfigs['prod3'] ?? '生产三班';
      _bBaseDate.text = bConfigs['base_date'] ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repo.saveGroupConfigs('group_a', {
      'group_name': _aGroupName.text.trim(), 'repair': _aRepair.text.trim(),
      'prod1': _aProd1.text.trim(), 'prod2': _aProd2.text.trim(), 'prod3': _aProd3.text.trim(),
      'base_date': _aBaseDate.text.trim(),
    });
    await _repo.saveGroupConfigs('group_b', {
      'group_name': _bGroupName.text.trim(), 'repair': _bRepair.text.trim(),
      'prod1': _bProd1.text.trim(), 'prod2': _bProd2.text.trim(), 'prod3': _bProd3.text.trim(),
      'base_date': _bBaseDate.text.trim(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
  }

  @override
  void dispose() {
    _aGroupName.dispose(); _aRepair.dispose(); _aProd1.dispose(); _aProd2.dispose(); _aProd3.dispose(); _aBaseDate.dispose();
    _bGroupName.dispose(); _bRepair.dispose(); _bProd1.dispose(); _bProd2.dispose(); _bProd3.dispose(); _bBaseDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('排班设置')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _groupSection('班组A', _aGroupName, _aRepair, _aProd1, _aProd2, _aProd3, _aBaseDate, AppColors.primary, isDark),
          const SizedBox(height: 24),
          _groupSection('班组B', _bGroupName, _bRepair, _bProd1, _bProd2, _bProd3, _bBaseDate, AppColors.secondary, isDark),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _save, child: const Text('保存设置')),
        ],
      ),
    );
  }

  Widget _groupSection(String title, TextEditingController groupCtrl, TextEditingController repairCtrl, TextEditingController p1, TextEditingController p2, TextEditingController p3, TextEditingController baseCtrl, Color color, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 16),
          _field('大组名', groupCtrl),
          const SizedBox(height: 12),
          _field('检修班名', repairCtrl),
          const SizedBox(height: 12),
          _field('生产一班名', p1),
          const SizedBox(height: 12),
          _field('生产二班名', p2),
          const SizedBox(height: 12),
          _field('生产三班名', p3),
          const SizedBox(height: 12),
          _field('基准起始日期', baseCtrl, hint: '格式: 2024-01-01'),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label, hintText: hint));
  }
}
