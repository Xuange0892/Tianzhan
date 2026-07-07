import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/sign_in_event.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/sign_in_repository.dart';
import '../../../data/repositories/worker_repository.dart';

/// 创建签到事项表单
class SignInFormScreen extends StatefulWidget {
  const SignInFormScreen({super.key});

  @override
  State<SignInFormScreen> createState() => _SignInFormScreenState();
}

class _SignInFormScreenState extends State<SignInFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _eventRepo = SignInRepository();
  final _workerRepo = WorkerRepository();

  List<Worker> _activeWorkers = [];
  Set<int> _selectedWorkerIds = {};
  bool _saving = false;

  @override
  void initState() { super.initState(); _loadWorkers(); }

  Future<void> _loadWorkers() async {
    final workers = await _workerRepo.getAll(status: 'active');
    if (mounted) setState(() => _activeWorkers = workers);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请至少选择一个参与人员')));
      return;
    }
    setState(() => _saving = true);
    try {
      final event = SignInEvent(title: _titleCtrl.text.trim(), description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim());
      final id = await _eventRepo.insertEvent(event);
      await _eventRepo.createRecordsForEvent(id, _selectedWorkerIds.toList());
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('创建成功'))); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('创建签到事项')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: '标题 *'), validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: '描述（可选）'), maxLines: 3),
            const SizedBox(height: 20),

            // 选择人员
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('选择参与人员 (${_selectedWorkerIds.length}/${_activeWorkers.length})',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
              TextButton(onPressed: () {
                setState(() {
                  if (_selectedWorkerIds.length == _activeWorkers.length) {
                    _selectedWorkerIds.clear();
                  } else {
                    _selectedWorkerIds = _activeWorkers.map((w) => w.id!).toSet();
                  }
                });
              }, child: Text(_selectedWorkerIds.length == _activeWorkers.length ? '取消全选' : '全选')),
            ]),
            const SizedBox(height: 12),

            if (_activeWorkers.isEmpty)
              const Center(child: Text('暂无在职人员'))
            else
              ..._activeWorkers.map((w) {
                final selected = _selectedWorkerIds.contains(w.id);
                return Card(
                  child: InkWell(
                    onTap: () => setState(() {
                      if (selected) _selectedWorkerIds.remove(w.id!); else _selectedWorkerIds.add(w.id!);
                    }),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: selected ? AppColors.secondary : AppColors.inactiveColor(isDark), size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text(w.name, style: TextStyle(fontSize: 15, color: AppColors.primaryText(isDark)))),
                        Text(w.department ?? '', style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark))),
                      ]),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('创建签到事项'),
            ),
          ],
        ),
      ),
    );
  }
}
