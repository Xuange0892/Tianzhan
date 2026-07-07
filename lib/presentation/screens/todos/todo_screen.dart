import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/todo.dart';
import '../../../data/repositories/todo_repository.dart';
import '../../widgets/empty_state.dart';
import 'todo_form_screen.dart';

/// 待办事项列表
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final _repo = TodoRepository();
  List<Todo> _todos = [];
  String _filter = '';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final todos = await _repo.getAll(filter: _filter.isEmpty ? null : _filter);
    if (mounted) setState(() { _todos = todos; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final filters = <MapEntry<String, String>>[
      const MapEntry('', '全部'), const MapEntry('pending', '未完成'), const MapEntry('completed', '已完成'),
    ];
    final priorityColors = {'high': AppColors.danger, 'medium': AppColors.warning, 'low': AppColors.secondary};
    final priorityLabels = {'high': '高', 'medium': '中', 'low': '低'};

    return Scaffold(
      appBar: AppBar(title: const Text('待办事项')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'todo_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoFormScreen())).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(f.value), selected: _filter == f.key, onSelected: (_) { _filter = f.key; _load(); }),
            )).toList()),
          ),
        ),
        Expanded(
          child: _loading ? const Center(child: CircularProgressIndicator()) : _todos.isEmpty
              ? EmptyState(icon: Icons.checklist_outlined, title: '暂无待办事项', subtitle: '点击 + 添加待办')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _todos.length,
                  itemBuilder: (_, i) {
                    final t = _todos[i];
                    final pc = priorityColors[t.priority] ?? AppColors.secondary;
                    final pl = priorityLabels[t.priority] ?? '中';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: Key('todo_${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: AppColors.danger, child: const Icon(Icons.delete, color: Colors.white)),
                        onDismissed: (_) async { await _repo.delete(t.id!); _load(); },
                        child: Card(
                          child: InkWell(
                            onTap: () async {
                              await _repo.toggleCompleted(t.id!, !t.isCompleted);
                              _load();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(children: [
                                Icon(t.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: t.isCompleted ? AppColors.secondary : AppColors.inactiveColor(isDark), size: 24),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText(isDark), decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                                  if (t.description != null && t.description!.isNotEmpty)
                                    Text(t.description!, style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: pc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text(pl, style: TextStyle(fontSize: 11, color: pc, fontWeight: FontWeight.w500))),
                                  if (t.dueDate != null) ...[
                                    const SizedBox(height: 4),
                                    Text(t.dueDate!, style: TextStyle(fontSize: 12, color: AppColors.inactiveColor(isDark))),
                                  ],
                                ]),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
