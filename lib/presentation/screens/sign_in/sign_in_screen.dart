import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/sign_in_event.dart';
import '../../../data/repositories/sign_in_repository.dart';
import '../../widgets/empty_state.dart';
import 'sign_in_form_screen.dart';
import 'sign_in_detail_screen.dart';

/// 签到统计列表
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _repo = SignInRepository();
  List<SignInEvent> _events = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final events = await _repo.getAllEvents();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('签到统计')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'signin_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInFormScreen())).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? EmptyState(icon: Icons.task_outlined, title: '暂无签到事项', subtitle: '点击右下角 + 创建新的签到事项')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _events.length,
                    itemBuilder: (_, i) {
                      final e = _events[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignInDetailScreen(event: e))).then((_) => _load()),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(e.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark)), overflow: TextOverflow.ellipsis),
                                      if (e.description != null && e.description!.isNotEmpty)
                                        Text(e.description!, style: TextStyle(fontSize: 13, color: AppColors.secondaryText(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('创建于 ${e.createdAt?.substring(0, 16) ?? ''}', style: TextStyle(fontSize: 12, color: AppColors.inactiveColor(isDark))),
                                    ]),
                                  ),
                                  const Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
