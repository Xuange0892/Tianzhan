import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/worker.dart';
import '../../../data/repositories/worker_repository.dart';

class WorkerFormScreen extends StatefulWidget {
  final Worker? worker;

  const WorkerFormScreen({super.key, this.worker});

  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = WorkerRepository();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _employeeNoCtrl;
  late final TextEditingController _idCardCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _jobLevelCtrl;
  late final TextEditingController _certificateNoCtrl;
  late final TextEditingController _emergencyContactCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  late final TextEditingController _remarkCtrl;

  String? _department;
  String? _jobType;
  DateTime? _certificateExpiry;
  DateTime? _entryDate;
  bool _isSaving = false;

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
    _department = w?.department;
    _jobType = w?.jobType;
    _certificateExpiry = AppDateUtils.parseDate(w?.certificateExpireDate);
    _entryDate = AppDateUtils.parseDate(w?.entryDate);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _employeeNoCtrl.dispose();
    _idCardCtrl.dispose();
    _phoneCtrl.dispose();
    _jobLevelCtrl.dispose();
    _certificateNoCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DateTime? initial,
      ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final worker = Worker(
      id: widget.worker?.id,
      name: _nameCtrl.text.trim(),
      employeeNo: _employeeNoCtrl.text.trim(),
      idCard: _idCardCtrl.text.trim().isEmpty ? null : _idCardCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      department: _department,
      jobType: _jobType,
      jobLevel:
          _jobLevelCtrl.text.trim().isEmpty ? null : _jobLevelCtrl.text.trim(),
      certificateNo: _certificateNoCtrl.text.trim().isEmpty
          ? null
          : _certificateNoCtrl.text.trim(),
      certificateExpireDate: _certificateExpiry != null
          ? AppDateUtils.formatDate(_certificateExpiry!)
          : null,
      entryDate: _entryDate != null ? AppDateUtils.formatDate(_entryDate!) : null,
      status: widget.worker?.status ?? 'active',
      emergencyContact: _emergencyContactCtrl.text.trim().isEmpty
          ? null
          : _emergencyContactCtrl.text.trim(),
      emergencyPhone: _emergencyPhoneCtrl.text.trim().isEmpty
          ? null
          : _emergencyPhoneCtrl.text.trim(),
      remark:
          _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
    );

    try {
      if (widget.worker == null) {
        await _repo.insert(worker);
      } else {
        await _repo.update(worker);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.worker != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '编辑人员' : '新增人员'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '姓名 *',
                hintText: '请输入姓名',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入姓名' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _employeeNoCtrl,
              decoration: const InputDecoration(
                labelText: '工号 *',
                hintText: '请输入工号',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入工号' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _department,
              decoration: const InputDecoration(
                labelText: '所属班组',
              ),
              items: AppConstants.departments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _department = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _jobType,
              decoration: const InputDecoration(
                labelText: '工种',
              ),
              items: AppConstants.jobTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _jobType = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobLevelCtrl,
              decoration: const InputDecoration(
                labelText: '技能等级',
                hintText: '如：初级/中级/高级',
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('证件信息'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _certificateNoCtrl,
              decoration: const InputDecoration(
                labelText: '特种作业证号',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _certificateExpiry, (date) {
                setState(() => _certificateExpiry = date);
              }),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '证件到期日',
                ),
                child: Text(
                  _certificateExpiry != null
                      ? AppDateUtils.formatDate(_certificateExpiry!)
                      : '请选择日期',
                  style: TextStyle(
                    color: _certificateExpiry != null
                        ? AppColors.primaryText
                        : AppColors.inactive,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('联系信息'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: '联系电话',
                hintText: '请输入手机号',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyContactCtrl,
              decoration: const InputDecoration(
                labelText: '紧急联系人',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyPhoneCtrl,
              decoration: const InputDecoration(
                labelText: '紧急联系人电话',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('其他'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(context, _entryDate, (date) {
                setState(() => _entryDate = date);
              }),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '入职日期',
                ),
                child: Text(
                  _entryDate != null
                      ? AppDateUtils.formatDate(_entryDate!)
                      : '请选择日期',
                  style: TextStyle(
                    color: _entryDate != null
                        ? AppColors.primaryText
                        : AppColors.inactive,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '其他需要记录的信息',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? '保存修改' : '添加人员'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
