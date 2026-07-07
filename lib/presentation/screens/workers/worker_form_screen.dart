import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';
import '../../../data/repositories/app_settings_repository.dart';

/// 人员表单（新增/编辑）
class WorkerFormScreen extends StatefulWidget {
  final Worker? worker;
  const WorkerFormScreen({super.key, this.worker});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = WorkerRepository();
  final _settingsRepo = AppSettingsRepository();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _employeeNoCtrl;
  late final TextEditingController _idCardCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _jobLevelCtrl;
  late final TextEditingController _certificateNoCtrl;
  late final TextEditingController _emergencyContactCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  late final TextEditingController _remarkCtrl;
  late final TextEditingController _deptCustomCtrl;

  String? _department;
  String? _jobType;
  DateTime? _certificateExpiry;
  DateTime? _entryDate;
  bool _isSaving = false;
  List<String> _departments = [];
  List<String> _customFields = [];
  Map<String, String> _customValues = {};

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _nameCtrl = TextEditingController(text: w?.name);
    _employeeNoCtrl = TextEditingController(text: w?.employeeNo);
    _idCardCtrl = TextEditingController(text: w?.idCard);
    _phoneCtrl = TextEditingController(text: w?.phone);
    _jobLevelCtrl = TextEditingController(text: w?.jobLevel);
    _certificateNoCtrl = TextEditingController(text: w?.certificateNo);
    _emergencyContactCtrl = TextEditingController(text: w?.emergencyContact);
    _emergencyPhoneCtrl = TextEditingController(text: w?.emergencyPhone);
    _remarkCtrl = TextEditingController(text: w?.remark);
    _deptCustomCtrl = TextEditingController();
    _department = w?.department;
    _jobType = w?.jobType;
    _certificateExpiry = AppDateUtils.parseDate(w?.certificateExpireDate);
    _entryDate = AppDateUtils.parseDate(w?.entryDate);
    _initCustomData();
  }

  Future<void> _initCustomData() async {
    final depts = await _settingsRepo.getDepartments();
    final defaults = List<String>.from(AppConstants.departments);
    final fields = await _settingsRepo.getCustomFields();
    if (mounted) setState(() {
      _departments = depts.isEmpty ? defaults : [...defaults, ...depts].toSet().toList();
      _customFields = fields;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _employeeNoCtrl.dispose(); _idCardCtrl.dispose(); _phoneCtrl.dispose();
    _jobLevelCtrl.dispose(); _certificateNoCtrl.dispose(); _emergencyContactCtrl.dispose();
    _emergencyPhoneCtrl.dispose(); _remarkCtrl.dispose(); _deptCustomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final worker = Worker(
      id: widget.worker?.id, name: _nameCtrl.text.trim(), employeeNo: _employeeNoCtrl.text.trim(),
      idCard: _idCardCtrl.text.trim().isEmpty ? null : _idCardCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      department: _department, jobType: _jobType,
      jobLevel: _jobLevelCtrl.text.trim().isEmpty ? null : _jobLevelCtrl.text.trim(),
      certificateNo: _certificateNoCtrl.text.trim().isEmpty ? null : _certificateNoCtrl.text.trim(),
      certificateExpireDate: _certificateExpiry != null ? AppDateUtils.formatDate(_certificateExpiry!) : null,
      entryDate: _entryDate != null ? AppDateUtils.formatDate(_entryDate!) : null,
      status: widget.worker?.status ?? 'active',
      emergencyContact: _emergencyContactCtrl.text.trim().isEmpty ? null : _emergencyContactCtrl.text.trim(),
      emergencyPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
    );
    try {
      if (widget.worker == null) await _repo.insert(worker); else await _repo.update(worker);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功'))); Navigator.pop(context, true); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final isEdit = widget.worker != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑人员' : '新增人员')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _section('基本信息', isDark),
            const SizedBox(height: 12),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '姓名 *'), validator: (v) => v == null || v.trim().isEmpty ? '请输入姓名' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _employeeNoCtrl, decoration: const InputDecoration(labelText: '工号 *'), validator: (v) => v == null || v.trim().isEmpty ? '请输入工号' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _departments.contains(_department) ? _department : null,
              decoration: const InputDecoration(labelText: '部门'),
              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _department = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _jobType,
              decoration: const InputDecoration(labelText: '工种'),
              items: AppConstants.jobTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _jobType = v)),
            const SizedBox(height: 12),
            TextFormField(controller: _jobLevelCtrl, decoration: const InputDecoration(labelText: '技能等级', hintText: '如：初级/中级/高级')),
            const SizedBox(height: 24),

            if (_customFields.isNotEmpty) ...[
              _section('自定义字段', isDark),
              const SizedBox(height: 12),
              ..._customFields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(initialValue: _customValues[f] ?? '', decoration: InputDecoration(labelText: f), onChanged: (v) => _customValues[f] = v),
              )),
              const SizedBox(height: 24),
            ],

            _section('证件信息', isDark),
            const SizedBox(height: 12),
            TextFormField(controller: _certificateNoCtrl, decoration: const InputDecoration(labelText: '特种作业证号')),
            const SizedBox(height: 12),
            InkWell(onTap: () => _pickDate(context, _certificateExpiry, (d) => setState(() => _certificateExpiry = d)),
              child: InputDecorator(decoration: const InputDecoration(labelText: '证件到期日'),
                child: Text(_certificateExpiry != null ? AppDateUtils.formatDate(_certificateExpiry!) : '请选择日期',
                  style: TextStyle(color: _certificateExpiry != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))))),
            const SizedBox(height: 24),

            _section('联系信息', isDark),
            const SizedBox(height: 12),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '电话'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyContactCtrl, decoration: const InputDecoration(labelText: '紧急联系人')),
            const SizedBox(height: 12),
            TextFormField(controller: _emergencyPhoneCtrl, decoration: const InputDecoration(labelText: '紧急联系人电话'), keyboardType: TextInputType.phone),
            const SizedBox(height: 24),

            _section('其他', isDark),
            const SizedBox(height: 12),
            InkWell(onTap: () => _pickDate(context, _entryDate, (d) => setState(() => _entryDate = d)),
              child: InputDecorator(decoration: const InputDecoration(labelText: '入职日期'),
                child: Text(_entryDate != null ? AppDateUtils.formatDate(_entryDate!) : '请选择日期',
                  style: TextStyle(color: _entryDate != null ? AppColors.primaryText(isDark) : AppColors.inactiveColor(isDark))))),
            const SizedBox(height: 12),
            TextFormField(controller: _remarkCtrl, decoration: const InputDecoration(labelText: '备注'), maxLines: 3),
            const SizedBox(height: 32),

            ElevatedButton(onPressed: _isSaving ? null : _save,
              child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? '保存修改' : '添加人员')),
          ],
        ),
      ),
    );
  }

  Widget _section(String t, bool isDark) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary));

  Future<void> _pickDate(BuildContext ctx, DateTime? init, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(context: ctx, initialDate: init ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) onPicked(picked);
  }
}
