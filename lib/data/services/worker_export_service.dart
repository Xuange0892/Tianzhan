import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/worker.dart';
import '../repositories/worker_repository.dart';
import '../repositories/custom_field_repository.dart';
import '../repositories/worker_custom_value_repository.dart';

/// 导出字段定义
class ExportField {
  final String key;       // Worker对象的属性名
  final String label;     // CSV表头（中文）
  final String? getter;   // 可选的自定义getter路径名

  const ExportField({
    required this.key,
    required this.label,
    this.getter,
  });

  /// 所有可导出字段
  static const List<ExportField> all = [
    ExportField(key: 'name', label: '姓名'),
    ExportField(key: 'employeeNo', label: '工号'),
    ExportField(key: 'idCard', label: '身份证号'),
    ExportField(key: 'phone', label: '电话'),
    ExportField(key: 'department', label: '班组'),
    ExportField(key: 'jobType', label: '工种'),
    ExportField(key: 'jobLevel', label: '技能等级'),
    ExportField(key: 'certificateNo', label: '特种作业证号'),
    ExportField(key: 'certificateExpireDate', label: '证件到期日'),
    ExportField(key: 'entryDate', label: '入职日期'),
    ExportField(key: 'status', label: '状态'),
    ExportField(key: 'emergencyContact', label: '紧急联系人'),
    ExportField(key: 'emergencyPhone', label: '紧急联系人电话'),
    ExportField(key: 'remark', label: '备注'),
  ];

  /// 常用导出字段子集（默认勾选）
  static const List<ExportField> defaults = [
    ExportField(key: 'name', label: '姓名'),
    ExportField(key: 'employeeNo', label: '工号'),
    ExportField(key: 'phone', label: '电话'),
    ExportField(key: 'department', label: '班组'),
    ExportField(key: 'jobType', label: '工种'),
  ];
}

class WorkerExportService {
  final CustomFieldRepository _customFieldRepo = CustomFieldRepository();
  final WorkerCustomValueRepository _customValueRepo = WorkerCustomValueRepository();

  /// 将人员列表导出为CSV字符串
  /// [workers] 人员列表
  /// [fields] 要导出的标准字段
  /// [includeCustomFields] 是否包含自定义字段列
  Future<String> exportToCsv(
    List<Worker> workers,
    List<ExportField> fields, {
    bool includeCustomFields = true,
  }) async {
    // 获取自定义字段定义
    List<CustomField> customFields = [];
    if (includeCustomFields) {
      customFields = await _customFieldRepo.getAll();
    }

    // 表头
    final header = fields.map((f) => f.label).toList();
    if (includeCustomFields) {
      for (final cf in customFields) {
        header.add('自定义_${cf.name}');
      }
    }

    // 数据行
    final rows = <List<dynamic>>[];
    for (final w in workers) {
      final row = fields.map((f) {
        final value = _getFieldValue(w, f.key);
        // 状态字段转中文
        if (f.key == 'status') {
          const labels = {
            'active': '在职',
            'leave': '离职',
            'transfer': '调岗',
          };
          return labels[value] ?? value;
        }
        return value;
      }).toList();

      // 追加自定义字段值
      if (includeCustomFields && w.customFieldValues.isNotEmpty) {
        for (final cf in customFields) {
          row.add(w.customFieldValues[cf.id] ?? '');
        }
      } else if (includeCustomFields) {
        // 为每个人员加载自定义字段值（如果没有预加载的话）
        for (final cf in customFields) {
          row.add('');
        }
      }

      rows.add(row);
    }

    final allRows = <List<dynamic>>[header, ...rows];
    return const ListToCsvConverter(eol: '\n').convert(allRows);
  }

  /// 将人员列表导出为CSV字符串，并为每个人物预加载自定义字段值
  Future<String> exportToCsvWithCustomValues(
    List<Worker> workers,
    List<ExportField> fields, {
    bool includeCustomFields = true,
  }) async {
    // 获取自定义字段定义
    List<CustomField> customFields = [];
    if (includeCustomFields) {
      customFields = await _customFieldRepo.getAll();
    }

    // 为每个人员预加载自定义字段值
    final workerCustomValues = <int, Map<int, String>>{};
    if (includeCustomFields) {
      for (final w in workers) {
        if (w.id != null) {
          workerCustomValues[w.id!] = await _customValueRepo.getMapByWorker(w.id!);
        }
      }
    }

    // 表头
    final header = fields.map((f) => f.label).toList();
    if (includeCustomFields) {
      for (final cf in customFields) {
        header.add('自定义_${cf.name}');
      }
    }

    // 数据行
    final rows = <List<dynamic>>[];
    for (final w in workers) {
      final row = fields.map((f) {
        final value = _getFieldValue(w, f.key);
        if (f.key == 'status') {
          const labels = {
            'active': '在职',
            'leave': '离职',
            'transfer': '调岗',
          };
          return labels[value] ?? value;
        }
        return value;
      }).toList();

      // 追加自定义字段值
      if (includeCustomFields) {
        final values = w.id != null ? (workerCustomValues[w.id!] ?? {}) : <int, String>{};
        for (final cf in customFields) {
          row.add(values[cf.id] ?? w.customFieldValues[cf.id] ?? '');
        }
      }

      rows.add(row);
    }

    final allRows = <List<dynamic>>[header, ...rows];
    return const ListToCsvConverter(eol: '\n').convert(allRows);
  }

  /// 导出并保存为CSV文件，返回文件路径
  Future<String> exportToFile(
    List<Worker> workers,
    List<ExportField> fields, {
    String? fileName,
    bool includeCustomFields = true,
  }) async {
    final csvContent = await exportToCsvWithCustomValues(
      workers, fields,
      includeCustomFields: includeCustomFields,
    );

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName ?? '人员信息_$timestamp.csv';
    final filePath = '${dir.path}/$name';

    final file = File(filePath);
    await file.writeAsString(csvContent);

    return filePath;
  }

  /// 读取Worker对象的字段值
  String _getFieldValue(Worker w, String key) {
    switch (key) {
      case 'name': return w.name;
      case 'employeeNo': return w.employeeNo;
      case 'idCard': return w.idCard ?? '';
      case 'phone': return w.phone ?? '';
      case 'department': return w.department ?? '';
      case 'jobType': return w.jobType ?? '';
      case 'jobLevel': return w.jobLevel ?? '';
      case 'certificateNo': return w.certificateNo ?? '';
      case 'certificateExpireDate': return w.certificateExpireDate ?? '';
      case 'entryDate': return w.entryDate ?? '';
      case 'status': return w.status;
      case 'emergencyContact': return w.emergencyContact ?? '';
      case 'emergencyPhone': return w.emergencyPhone ?? '';
      case 'remark': return w.remark ?? '';
      default: return '';
    }
  }
}
