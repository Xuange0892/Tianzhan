import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../models/worker.dart';
import '../repositories/worker_repository.dart';

/// CSV批量导入结果
class ImportResult {
  final int successCount;
  final int skipCount;
  final int failCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.skipCount,
    required this.failCount,
    required this.errors,
  });

  int get total => successCount + skipCount + failCount;
}

class WorkerImportService {
  final WorkerRepository _repo = WorkerRepository();

  /// 从CSV文件批量导入人员
  ///
  /// CSV表头字段（中英文都支持，不区分大小写）：
  /// 姓名/name, 工号/employee_no, 身份证号/id_card, 电话/phone,
  /// 班组/department, 工种/job_type, 技能等级/job_level,
  /// 证件号/certificate_no, 证件到期日/certificate_expire_date,
  /// 入职日期/entry_date, 紧急联系人/emergency_contact,
  /// 紧急联系人电话/emergency_phone, 备注/remark
  ///
  /// 只有"姓名"和"工号"是必填，其余可选。
  /// 如果CSV没有表头行，也支持自动按列顺序匹配。
  Future<ImportResult> importFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ImportResult(
        successCount: 0,
        skipCount: 0,
        failCount: 0,
        errors: ['文件不存在: $filePath'],
      );
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return ImportResult(
        successCount: 0,
        skipCount: 0,
        failCount: 0,
        errors: ['文件内容为空'],
      );
    }

    // 解析CSV
    final rows = const CsvToListConverter(
      allowInvalid: true,
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.isEmpty) {
      return ImportResult(
        successCount: 0,
        skipCount: 0,
        failCount: 0,
        errors: ['文件中没有数据行'],
      );
    }

    int successCount = 0;
    int skipCount = 0;
    int failCount = 0;
    final errors = <String>[];

    // 字段名到列索引的映射
    Map<String, int> headerMap = {};
    List<dynamic>? dataRows;

    // 检测第一行是否是表头
    final firstRow = rows[0].map((e) => e.toString().trim()).toList();
    if (_isHeaderRow(firstRow)) {
      headerMap = _buildHeaderMap(firstRow);
      dataRows = rows.sublist(1);
    } else {
      // 没有表头，按固定列顺序: 姓名,工号,电话,班组,工种,技能等级,证件号,证件到期日,入职日期,紧急联系人,紧急联系人电话,备注
      headerMap = _defaultColumnMap(firstRow.length);
      dataRows = rows;
    }

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows![i];

      // 跳过空行
      if (row.isEmpty ||
          row.every((e) => e.toString().trim().isEmpty)) {
        continue;
      }

      try {
        final worker = _parseRowToWorker(row, headerMap, i + 1);

        if (worker.name.isEmpty || worker.employeeNo.isEmpty) {
          skipCount++;
          errors.add('第${i + 2}行: 姓名或工号为空，已跳过');
          continue;
        }

        // 检查工号是否已存在
        final existing = await _repo.getByEmployeeNo(worker.employeeNo);
        if (existing != null) {
          skipCount++;
          errors.add('第${i + 2}行: 工号 ${worker.employeeNo} 已存在，已跳过');
          continue;
        }

        await _repo.insert(worker);
        successCount++;
      } catch (e) {
        failCount++;
        errors.add('第${i + 2}行: 解析失败 - $e');
      }
    }

    return ImportResult(
      successCount: successCount,
      skipCount: skipCount,
      failCount: failCount,
      errors: errors,
    );
  }

  /// 生成CSV导入模板
  static String generateTemplate() {
    const header = [
      '姓名', '工号', '身份证号', '电话', '班组', '工种',
      '技能等级', '证件号', '证件到期日', '入职日期',
      '紧急联系人', '紧急联系人电话', '备注',
    ];

    // 示例行
    const example = [
      '张三', 'JJ001', '', '13800138001', '掘进一队', '掘进工',
      '中级', '', '', '2024-01-15', '', '', '示例人员',
    ];
    const example2 = [
      '李四', 'JJ002', '', '13800138002', '支护班', '支护工',
      '高级', 'CERT001', '2025-12-31', '2023-06-01', '王五', '13900139001', '',
    ];

    const converter = CsvToListConverter();
    final List<List<dynamic>> rows = [
      header,
      example,
      example2,
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// 检测第一行是否为表头（包含"姓名"或"name"等关键字）
  bool _isHeaderRow(List<String> row) {
    final lower = row.map((e) => e.toLowerCase()).toSet();
    const headerKeywords = {'姓名', '工号', 'name', 'employee_no', 'employee'};
    for (final keyword in headerKeywords) {
      for (final cell in lower) {
        if (cell.contains(keyword.toLowerCase())) return true;
      }
    }
    return false;
  }

  /// 根据表头行构建字段名→列索引映射
  Map<String, int> _buildHeaderMap(List<String> headers) {
    final map = <String, int>{};

    // 支持的中英文表头映射
    const fieldAliases = {
      '姓名': 'name',
      'name': 'name',
      '名字': 'name',
      '工号': 'employee_no',
      'employee_no': 'employee_no',
      'employee': 'employee_no',
      '员工编号': 'employee_no',
      '编号': 'employee_no',
      '身份证号': 'id_card',
      '身份证': 'id_card',
      'id_card': 'id_card',
      '电话': 'phone',
      '手机': 'phone',
      'phone': 'phone',
      '手机号': 'phone',
      '联系电话': 'phone',
      '班组': 'department',
      '部门': 'department',
      'department': 'department',
      '队别': 'department',
      '工种': 'job_type',
      'job_type': 'job_type',
      '岗位': 'job_type',
      '技能等级': 'job_level',
      '等级': 'job_level',
      'job_level': 'job_level',
      '证件号': 'certificate_no',
      '特种作业证号': 'certificate_no',
      'certificate_no': 'certificate_no',
      '证件到期日': 'certificate_expire_date',
      '到期日': 'certificate_expire_date',
      'certificate_expire_date': 'certificate_expire_date',
      '入职日期': 'entry_date',
      'entry_date': 'entry_date',
      '入职时间': 'entry_date',
      '紧急联系人': 'emergency_contact',
      'emergency_contact': 'emergency_contact',
      '紧急联系人电话': 'emergency_phone',
      'emergency_phone': 'emergency_phone',
      '备注': 'remark',
      '说明': 'remark',
      'remark': 'remark',
    };

    for (int i = 0; i < headers.length; i++) {
      final cell = headers[i].trim().toLowerCase();
      for (final entry in fieldAliases.entries) {
        if (entry.key.toLowerCase() == cell) {
          map[entry.value] = i;
          break;
        }
      }
    }

    return map;
  }

  /// 无表头时的默认列顺序映射
  Map<String, int> _defaultColumnMap(int columnCount) {
    final order = [
      'name', 'employee_no', 'id_card', 'phone', 'department',
      'job_type', 'job_level', 'certificate_no', 'certificate_expire_date',
      'entry_date', 'emergency_contact', 'emergency_phone', 'remark',
    ];
    final map = <String, int>{};
    for (int i = 0; i < columnCount && i < order.length; i++) {
      map[order[i]] = i;
    }
    return map;
  }

  /// 从一行数据解析为Worker对象
  Worker _parseRowToWorker(
      List<dynamic> row, Map<String, int> headerMap, int rowNum) {
    String getVal(String field) {
      final idx = headerMap[field];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    return Worker(
      name: getVal('name'),
      employeeNo: getVal('employee_no'),
      idCard: getVal('id_card').isEmpty ? null : getVal('id_card'),
      phone: getVal('phone').isEmpty ? null : getVal('phone'),
      department:
          getVal('department').isEmpty ? null : getVal('department'),
      jobType: getVal('job_type').isEmpty ? null : getVal('job_type'),
      jobLevel: getVal('job_level').isEmpty ? null : getVal('job_level'),
      certificateNo:
          getVal('certificate_no').isEmpty ? null : getVal('certificate_no'),
      certificateExpireDate:
          getVal('certificate_expire_date').isEmpty ? null : _normalizeDate(getVal('certificate_expire_date')),
      entryDate:
          getVal('entry_date').isEmpty ? null : _normalizeDate(getVal('entry_date')),
      status: 'active',
      emergencyContact:
          getVal('emergency_contact').isEmpty ? null : getVal('emergency_contact'),
      emergencyPhone:
          getVal('emergency_phone').isEmpty ? null : getVal('emergency_phone'),
      remark: getVal('remark').isEmpty ? null : getVal('remark'),
    );
  }

  /// 日期格式标准化：支持 2024-01-15、2024/01/15、20240115 等格式
  String? _normalizeDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // 尝试直接返回标准格式
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return dateStr;
    }

    // 处理 2024/01/15 格式
    final slash = dateStr.replaceAll('/', '-');
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(slash)) {
      return slash;
    }

    // 处理 20240115 格式（8位纯数字）
    if (RegExp(r'^\d{8}$').hasMatch(dateStr) && dateStr.length == 8) {
      return '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
    }

    // 处理 Excel 日期序列号（如 45292）
    final numVal = int.tryParse(dateStr);
    if (numVal != null && numVal > 40000 && numVal < 60000) {
      // Excel日期序列号：从1899-12-30开始的天数
      final base = DateTime(1899, 12, 30);
      final date = base.add(Duration(days: numVal));
      return date.toIso8601String().substring(0, 10);
    }

    return dateStr; // 原样返回，让数据库处理
  }
}
