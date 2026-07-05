import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import 'worker_form_screen.dart';

class WorkerDetailScreen extends StatefulWidget {
  final Worker worker;

  const WorkerDetailScreen({super.key, required this.worker});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  final _repo = WorkerRepository();
  late Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = widget.worker;
  }

  Future<void> _refresh() async {
    final updated = await _repo.getById(_worker.id!);
    if (updated != null && mounted) {
      setState(() => _worker = updated);
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(
          '确定要将 ${_worker.name} 标记为"${AppConstants.workerStatusLabels[newStatus]}"吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = _worker.copyWith(status: newStatus);
    await _repo.update(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('状态更新成功')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${_worker.name} 的信息吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _repo.delete(_worker.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        AppConstants.workerStatusLabels[_worker.status] ?? _worker.status;
    final statusColor = _worker.status == 'active'
        ? AppColors.secondary
        : _worker.status == 'leave'
            ? AppColors.danger
            : AppColors.warning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('人员详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorkerFormScreen(worker: _worker),
              ),
            ).then((_) => _refresh()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    _worker.name.isNotEmpty ? _worker.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _worker.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard('基本信息', [
            _buildInfoRow('工号', _worker.employeeNo),
            _buildInfoRow('班组', _worker.department ?? '未设置'),
            _buildInfoRow('工种', _worker.jobType ?? '未设置'),
            _buildInfoRow('技能等级', _worker.jobLevel ?? '未设置'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('证件信息', [
            _buildInfoRow('特种作业证号', _worker.certificateNo ?? '无'),
            _buildInfoRow(
              '证件到期日',
              _worker.certificateExpireDate ?? '未设置',
              valueColor: DateUtils.daysUntilExpiry(
                          _worker.certificateExpireDate) >= 0 &&
                      DateUtils.daysUntilExpiry(
                              _worker.certificateExpireDate) <=
                          30
                  ? AppColors.warning
                  : null,
            ),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('联系信息', [
            _buildInfoRow('联系电话', _worker.phone ?? '未设置'),
            _buildInfoRow('紧急联系人', _worker.emergencyContact ?? '未设置'),
            _buildInfoRow('紧急联系人电话', _worker.emergencyPhone ?? '未设置'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('其他', [
            _buildInfoRow('入职日期', _worker.entryDate ?? '未设置'),
            _buildInfoRow('备注', _worker.remark ?? '无'),
          ]),
          const SizedBox(height: 24),
          if (_worker.status == 'active') ...[
            OutlinedButton(
              onPressed: () => _changeStatus('leave'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              child: const Text('标记为离职'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            child: const Text('删除人员'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? AppColors.primaryText,
                fontWeight:
                    valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
