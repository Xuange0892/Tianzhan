import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/certificate_repository.dart';
import '../../widgets/confirm_dialog.dart';
import 'worker_form_screen.dart';

/// 人员详情
class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;
  const WorkerDetailScreen({super.key, required this.worker});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final _repo = WorkerRepository();
  final _certRepo = CertificateRepository();
  late Worker _worker;
  List<Map<String, dynamic>> _certs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _worker = widget.worker; _load(); }

  Future<void> _load() async {
    final u = await _repo.getById(_worker.id!);
    if (u != null) _worker = u;
    final c = await _certRepo.getByWorkerId(_worker.id!);
    if (mounted) setState(() {
      _certs = c.map((e) => {'id': e.id, 'name': e.name, 'number': e.number, 'expire_date': e.expireDate}).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final sl = AppConstants.workerStatusLabels[_worker.status] ?? _worker.status;
    final sc = _worker.status == 'active' ? AppColors.secondary : (_worker.status == 'leave' ? AppColors.danger : AppColors.warning);

    return Scaffold(
      appBar: AppBar(title: const Text('人员详情'), actions: [
        IconButton(icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerFormScreen(worker: _worker))).then((_) => _load())),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(_worker.name.isNotEmpty ? _worker.name[0] : '?', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))),
            const SizedBox(height: 12),
            Text(_worker.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText(isDark))),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Text(sl, style: TextStyle(fontSize: 13, color: sc, fontWeight: FontWeight.w500))),
          ])),
          const SizedBox(height: 24),
          _infoCard('基本信息', [_row('工号', _worker.employeeNo, isDark), _row('部门', _worker.department ?? '未设置', isDark), _row('工种', _worker.jobType ?? '未设置', isDark), _row('技能等级', _worker.jobLevel ?? '未设置', isDark)], isDark),
          const SizedBox(height: 16),
          _infoCard('证件信息', [_row('特种作业证号', _worker.certificateNo ?? '无', isDark),
            _row('证件到期日', _worker.certificateExpireDate ?? '未设置', isDark,
              vc: _worker.certificateExpireDate != null && AppDateUtils.daysUntilExpiry(_worker.certificateExpireDate) <= 30 ? AppColors.warning : null)], isDark),
          const SizedBox(height: 16),
          if (_certs.isNotEmpty) ...[
            _infoCard('关联证件', _certs.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
              const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary), const SizedBox(width: 8),
              Expanded(child: Text(c['name'] as String, style: TextStyle(fontSize: 14, color: AppColors.primaryText(isDark)))),
              if (c['expire_date'] != null) Text(c['expire_date'] as String, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark))),
            ]))).toList(), isDark),
            const SizedBox(height: 16),
          ],
          _infoCard('联系信息', [_row('电话', _worker.phone ?? '未设置', isDark), _row('紧急联系人', _worker.emergencyContact ?? '未设置', isDark), _row('紧急联系人电话', _worker.emergencyPhone ?? '未设置', isDark)], isDark),
          const SizedBox(height: 16),
          _infoCard('其他', [_row('入职日期', _worker.entryDate ?? '未设置', isDark), _row('备注', _worker.remark ?? '无', isDark)], isDark),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('删除人员'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger))),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    if (await ConfirmDialog.show(context, title: '确认删除', content: '确定删除 ${_worker.name}？', isDestructive: true)) {
      await _repo.delete(_worker.id!);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除'))); Navigator.pop(context, true); }
    }
  }

  Widget _infoCard(String title, List<Widget> children, bool isDark) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
      const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12), ...children,
    ])));
  }

  Widget _row(String label, String value, bool isDark, {Color? vc}) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 14, color: AppColors.secondaryText(isDark)))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: vc ?? AppColors.primaryText(isDark), fontWeight: vc != null ? FontWeight.bold : FontWeight.normal))),
    ]));
  }
}
