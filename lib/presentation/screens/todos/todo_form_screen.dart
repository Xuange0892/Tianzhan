import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';

/// 待办事项表单
class TodoFormScreen extends StatefulWidget {
  final Todo? todo;
  const TodoFormScreen({super.key, this.todo});

  @override
  State<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends State<TodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TodoRepository();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _dueDate;
  String _priority = 'medium';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtrl.text = t?.title ?? '';
    _descCtrl.text = t?.description ?? '';
    _dueDate = AppDateUtils.parseDate(t?.dueDate);
    _priority = t?.priority ?? 'medium';
  }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final todo = Todo(
      id: widget.todo?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueDate: _dueDate != null ? AppDateUtils.formatDate(_dueDate!) : null,
      priority: _priority,
      isCompleted: widget.todo?.isCompleted ?? false,
    );
    try {
      if (widget.todo == null) await _repo.insert(todo); else await _repo.update(todo);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功'))); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.todo != null ? '编辑待办' : '新建待办')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: '标题 *'), validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: '描述（可选）'), maxLines: 3),
            const SizedBox(height: 12),
            // 截止日期
            InkWell(
              onTap: () async { final d = await showDatePicker(context: context, initialDate: _dueDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100)); if (d != null) setState(() => _dueDate = d); },
              child: InputDecorator(decoration: const InputDecoration(labelText: '截止日期'),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_dueDate != null ? AppDateUtils.formatDate(_dueDate!) : '请选择', style: TextStyle(color: _dueDate != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))),
                  const Icon(Icons.calendar_today_outlined, size: 20),
                ]))),
            const SizedBox(height: 16),
            // 优先级
            Text('优先级', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primaryText(isDark))),
            const SizedBox(height: 8),
            Row(children: [
              _priorityChip('高', 'high', AppColors.danger, isDark),
              const SizedBox(width: 12),
              _priorityChip('中', 'medium', AppColors.warning, isDark),
              const SizedBox(width: 12),
              _priorityChip('低', 'low', AppColors.secondary, isDark),
            ]),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.todo != null ? '保存修改' : '添加待办')),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: _priority == value,
        selectedColor: color.withOpacity(0.15),
        onSelected: (_) => setState(() => _priority = value),
      ),
    );
  }
}
