import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/certificate.dart';
import '../../../data/repositories/certificate_repository.dart';
import '../../widgets/empty_state.dart';
import 'certificate_form_screen.dart';

/// 证件管理列表
class CertificateListScreen extends StatefulWidget {
  const CertificateListScreen({super.key});

  @override
  State<CertificateListScreen> createState() => _CertificateListScreenState();
}

class _CertificateListScreenState extends State<CertificateListScreen> {
  final _repo = CertificateRepository();
  List<Certificate> _certs = [];
  String _filter = '';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final certs = await _repo.getAll(filter: _filter.isEmpty ? null : _filter);
    if (mounted) setState(() { _certs = certs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final filters = <MapEntry<String, String>>[
      const MapEntry('', '全部'), const MapEntry('expiring', '即将到期'), const MapEntry('expired', '已过期'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('证件管理')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'cert_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificateFormScreen())).then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        // 筛选
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
          child: _loading ? const Center(child: CircularProgressIndicator()) : _certs.isEmpty
              ? EmptyState(icon: Icons.badge_outlined, title: '暂无证件信息', subtitle: '点击 + 添加证件')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _certs.length,
                  itemBuilder: (_, i) {
                    final c = _certs[i];
                    final days = c.expireDate != null ? AppDateUtils.daysUntilExpiry(c.expireDate) : -1;
                    final isExpired = days < 0;
                    final isExpiring = days >= 0 && days <= 30;
                    final color = isExpired ? AppColors.danger : (isExpiring ? AppColors.warning : AppColors.secondary);
                    final tag = isExpired ? '已过期' : (isExpiring ? '${days}天后到期' : '正常');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CertificateFormScreen(cert: c))).then((_) => _load()),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.badge_outlined, color: color, size: 22)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryText(isDark))),
                                const SizedBox(height: 2),
                                if (c.number != null) Text('编号: ${c.number}', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(isDark)), overflow: TextOverflow.ellipsis),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(tag, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500))),
                                if (c.expireDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(c.expireDate!, style: TextStyle(fontSize: 12, color: AppColors.inactiveColor(isDark))),
                                ],
                              ]),
                            ]),
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
