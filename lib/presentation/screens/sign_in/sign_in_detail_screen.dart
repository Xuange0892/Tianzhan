import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/sign_in_event.dart';
import '../../../data/models/sign_in_record.dart';
import '../../../data/repositories/sign_in_repository.dart';
import '../../widgets/confirm_dialog.dart';

/// 签到详情页
class SignInDetailScreen extends StatefulWidget {
  final SignInEvent event;
  const SignInDetailScreen({super.key, required this.event});

  @override
  State<SignInDetailScreen> createState() => _SignInDetailScreenState();
}

class _SignInDetailScreenState extends State<SignInDetailScreen> {
  final _repo = SignInRepository();
  List<SignInRecord> _records = [];
  Map<String, int> _stats = {'total': 0, 'signed': 0, 'unsigned': 0};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final records = await _repo.getRecordsByEvent(widget.event.id!);
    final stats = await _repo.getEventStats(widget.event.id!);
    if (mounted) setState(() { _records = records; _stats = stats; _loading = false; });
  }

  Future<void> _toggle(int workerId, bool current) async {
    await _repo.toggleSignIn(widget.event.id!, workerId, !current);
    _load();
  }

  Future<void> _toggleAll(bool signed) async {
    await _repo.toggleAll(widget.event.id!, signed);
    _load();
  }

  Future<void> _delete() async {
    if (await ConfirmDialog.show(context, title: '确认删除', content: '确定删除此签到事项？', isDestructive: true)) {
      await _repo.deleteEvent(widget.event.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _exportReport() async {
    final signed = _records.where((r) => r.signedIn).map((r) => '${r.workerName ?? r.workerId.toString()}').toList();
    final unsigned = _records.where((r) => !r.signedIn).map((r) => '${r.workerName ?? r.workerId.toString()}').toList();
    final report = StringBuffer();
    report.writeln('签到报告：${widget.event.title}');
    report.writeln('导出时间：${DateTime.now().toIso8601String().substring(0, 16)}');
    report.writeln('');
    report.writeln('已签到（${signed.length}人）：');
    signed.forEach((n) => report.writeln('  - $n'));
    report.writeln('');
    report.writeln('未签到（${unsigned.length}人）：');
    unsigned.forEach((n) => report.writeln('  - $n'));

    try {
      final dir = await Directory('/data/user/work').create(temp: true);
      final file = File('${dir.path}/签到报告_${widget.event.title}.txt');
      await file.writeAsString(report.toString());
      if (mounted) await Share.shareXFiles([XFile(file.path)], subject: '签到报告：${widget.event.title}');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('签到详情'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _exportReport),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        // 顶部信息
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.event.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText(isDark))),
            if (widget.event.description != null) ...[
              const SizedBox(height: 4),
              Text(widget.event.description!, style: TextStyle(fontSize: 14, color: AppColors.secondaryText(isDark))),
            ],
            const SizedBox(height: 16),
            // 统计
            Row(children: [
              _statBox('${_stats['total']}', '总人数', AppColors.primary, isDark),
              const SizedBox(width: 12),
              _statBox('${_stats['signed']}', '已签到', AppColors.secondary, isDark),
              const SizedBox(width: 12),
              _statBox('${_stats['unsigned']}', '未签到', AppColors.warning, isDark),
            ]),
          ]),
        ),
        // 全选按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            TextButton.icon(onPressed: () => _toggleAll(true), icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('全选签到')),
            TextButton.icon(onPressed: () => _toggleAll(false), icon: const Icon(Icons.radio_button_unchecked, size: 18), label: const Text('取消全选')),
          ]),
        ),
        const Divider(),
        // 人员列表
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _records.length,
          itemBuilder: (_, i) {
            final r = _records[i];
            return Card(
              child: InkWell(
                onTap: () => _toggle(r.workerId, r.signedIn),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Icon(r.signedIn ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: r.signedIn ? AppColors.secondary : AppColors.inactiveColor(isDark), size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r.workerName ?? '未知', style: TextStyle(fontSize: 15, color: AppColors.primaryText(isDark)))),
                    Text(r.signedIn ? '已签到' : '未签到', style: TextStyle(fontSize: 13, color: r.signedIn ? AppColors.secondary : AppColors.inactiveColor(isDark))),
                  ]),
                ),
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark))),
        ]),
      ),
    );
  }
}
