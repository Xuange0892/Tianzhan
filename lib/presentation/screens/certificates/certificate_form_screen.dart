import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/certificate.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/certificate_repository.dart';
import '../../../data/repositories/worker_repository.dart';

/// 证件表单（新增/编辑）
class CertificateFormScreen extends StatefulWidget {
  final Certificate? cert;
  const CertificateFormScreen({super.key, this.cert});

  @override
  State<CertificateFormScreen> createState() => _CertificateFormScreenState();
}

class _CertificateFormScreenState extends State<CertificateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CertificateRepository();
  final _workerRepo = WorkerRepository();

  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  String? _imagePath;
  DateTime? _issueDate;
  DateTime? _expireDate;

  List<Worker> _workers = [];
  int? _selectedWorkerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.cert;
    _nameCtrl.text = c?.name ?? '';
    _numberCtrl.text = c?.number ?? '';
    _remarkCtrl.text = c?.remark ?? '';
    _imagePath = c?.imagePath;
    _issueDate = AppDateUtils.parseDate(c?.issueDate);
    _expireDate = AppDateUtils.parseDate(c?.expireDate);
    _selectedWorkerId = c?.workerId;
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final workers = await _workerRepo.getAll(status: 'active');
    if (mounted) setState(() => _workers = workers);
  }

  Future<void> _pickImage() async {
    // 使用 image_picker（预留接口）
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片选择功能需要 image_picker 插件配置')));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWorkerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择人员')));
      return;
    }
    setState(() => _saving = true);

    final cert = Certificate(
      id: widget.cert?.id,
      workerId: _selectedWorkerId!,
      certName: _nameCtrl.text.trim(),
      certNo: _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
      certPhotoPath: _imagePath,
      issueDate: _issueDate != null ? AppDateUtils.formatDate(_issueDate!) : null,
      expireDate: _expireDate != null ? AppDateUtils.formatDate(_expireDate!) : null,
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
    );

    try {
      if (widget.cert == null) await _repo.insert(cert); else await _repo.update(cert);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功'))); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); _numberCtrl.dispose(); _remarkCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isEdit = widget.cert != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑证件' : '添加证件')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            DropdownButtonFormField<int>(
              value: _workers.any((w) => w.id == _selectedWorkerId) ? _selectedWorkerId : null,
              decoration: const InputDecoration(labelText: '所属人员 *'),
              items: _workers.map((w) => DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.employeeNo})'))).toList(),
              onChanged: (v) => setState(() => _selectedWorkerId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '证件名称 *'), validator: (v) => v == null || v.trim().isEmpty ? '请输入证件名称' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _numberCtrl, decoration: const InputDecoration(labelText: '证件号码')),
            const SizedBox(height: 12),
            // 图片
            InkWell(onTap: _pickImage, borderRadius: BorderRadius.circular(16),
              child: InputDecorator(decoration: const InputDecoration(labelText: '证件照片'),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_imagePath != null ? '已选择照片' : '点击选择照片', style: TextStyle(color: _imagePath != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))),
                  const Icon(Icons.photo_camera_outlined, size: 20),
                ]))),
            const SizedBox(height: 12),
            InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _issueDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setState(() => _issueDate = d); },
              child: InputDecorator(decoration: const InputDecoration(labelText: '发证日期'),
                child: Text(_issueDate != null ? AppDateUtils.formatDate(_issueDate!) : '请选择', style: TextStyle(color: _issueDate != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))))),
            const SizedBox(height: 12),
            InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: _expireDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setState(() => _expireDate = d); },
              child: InputDecorator(decoration: const InputDecoration(labelText: '到期日期'),
                child: Text(_expireDate != null ? AppDateUtils.formatDate(_expireDate!) : '请选择', style: TextStyle(color: _expireDate != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))))),
            const SizedBox(height: 12),
            TextFormField(controller: _remarkCtrl, decoration: const InputDecoration(labelText: '备注'), maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? '保存修改' : '添加证件')),
          ],
        ),
      ),
    );
  }
}
