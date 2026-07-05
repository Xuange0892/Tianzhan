import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/worker.dart';

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
  /// 将人员列表导出为CSV字符串
  String exportToCsv(List<Worker> workers, List<ExportField> fields) {
    // 表头
    final header = fields.map((f) => f.label).toList();

    // 数据行
    final rows = workers.map((w) {
      return fields.map((f) {
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
    }).toList();

    final allRows = <List<dynamic>>[header, ...rows];
    return const ListToCsvConverter(eol: '\n').convert(allRows);
  }

  /// 导出并保存为CSV文件，返回文件路径
  Future<String> exportToFile(
    List<Worker> workers,
    List<ExportField> fields, {
    String? fileName,
  }) async {
    final csvContent = exportToCsv(workers, fields);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName ?? '人员信息_$timestamp.csv';
    final filePath = p.join(dir.path, name);

    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: const Utf8Codec(withBom: true));

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
