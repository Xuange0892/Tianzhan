import 'dart:io';
import 'package:csv/csv.dart';
import '../repositories/certificate_repository.dart';
import '../repositories/worker_repository.dart';

/// 证件CSV批量导入结果
class CertificateImportResult {
  final int successCount;
  final int skipCount;
  final int failCount;
  final List<String> errors;

  CertificateImportResult({
    required this.successCount,
    required this.skipCount,
    required this.failCount,
    required this.errors,
  });

  int get total => successCount + skipCount + failCount;
}

/// 证件批量导入服务
class CertificateImportService {
  final CertificateRepository _certRepo = CertificateRepository();
  final WorkerRepository _workerRepo = WorkerRepository();

  /// 从CSV文件批量导入证件信息
  ///
  /// CSV表头字段（中英文都支持，不区分大小写）：
  /// 姓名/name, 工号/employee_no, 证件名称/cert_name,
  /// 证件号码/cert_number, 发证日期/issue_date, 到期日期/expire_date
  ///
  /// 根据姓名+工号匹配人员，如果匹配不到则跳过该行
  Future<CertificateImportResult> importFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return CertificateImportResult(
        successCount: 0,
        skipCount: 0,
        failCount: 0,
        errors: ['文件不存在: $filePath'],
      );
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return CertificateImportResult(
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
      return CertificateImportResult(
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
      // 没有表头，按固定列顺序：姓名,工号,证件名称,证件号码,发证日期,到期日期
      headerMap = _defaultColumnMap(firstRow.length);
      dataRows = rows;
    }

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows![i];

      // 跳过空行
      if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) {
        continue;
      }

      try {
        String getVal(String field) {
          final idx = headerMap[field];
          if (idx == null || idx >= row.length) return '';
          return row[idx].toString().trim();
        }

        final name = getVal('name');
        final employeeNo = getVal('employee_no');
        final certName = getVal('cert_name');
        final certNumber = getVal('cert_number');
        final issueDate = getVal('issue_date');
        final expireDate = getVal('expire_date');

        // 姓名和工号是匹配人员的必要条件
        if (name.isEmpty || employeeNo.isEmpty) {
          skipCount++;
          errors.add('第${i + 2}行: 姓名或工号为空，无法匹配人员，已跳过');
          continue;
        }

        // 根据姓名+工号匹配人员
        final worker = await _workerRepo.getByEmployeeNo(employeeNo);
        if (worker == null) {
          skipCount++;
          errors.add('第${i + 2}行: 工号 $employeeNo 不存在，已跳过');
          continue;
        }

        // 证件名称为空则跳过
        if (certName.isEmpty) {
          skipCount++;
          errors.add('第${i + 2}行: 证件名称为空，已跳过');
          continue;
        }

        // 创建证件记录
        final cert = Certificate(
          workerId: worker.id!,
          name: certName,
          number: certNumber.isEmpty ? null : certNumber,
          issueDate: issueDate.isEmpty ? null : _normalizeDate(issueDate),
          expireDate: expireDate.isEmpty ? null : _normalizeDate(expireDate),
        );

        await _certRepo.insert(cert);
        successCount++;
      } catch (e) {
        failCount++;
        errors.add('第${i + 2}行: 解析失败 - $e');
      }
    }

    return CertificateImportResult(
      successCount: successCount,
      skipCount: skipCount,
      failCount: failCount,
      errors: errors,
    );
  }

  /// 生成CSV导入模板
  static String generateTemplate() {
    const header = ['姓名', '工号', '证件名称', '证件号码', '发证日期', '到期日期'];

    // 示例行
    const example = ['张三', 'JJ001', '特种作业操作证', 'CERT001', '2020-01-01', '2026-01-01'];
    const example2 = ['李四', 'JJ002', '安全资格证', 'CERT002', '2021-06-15', '2027-06-15'];

    const converter = CsvToListConverter();
    final List<List<dynamic>> rows = [
      header,
      example,
      example2,
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// 检测第一行是否为表头
  bool _isHeaderRow(List<String> row) {
    final lower = row.map((e) => e.toLowerCase()).toSet();
    const headerKeywords = {
      '姓名', 'name', '工号', 'employee_no',
      '证件名称', 'cert_name', '证件', 'certificate',
    };
    for (final keyword in headerKeywords) {
      for (final cell in lower) {
        if (cell.contains(keyword.toLowerCase())) return true;
      }
    }
    return false;
  }

  /// 根据表头行构建字段名到列索引的映射
  Map<String, int> _buildHeaderMap(List<String> headers) {
    final map = <String, int>{};

    const fieldAliases = {
      '姓名': 'name',
      'name': 'name',
      '名字': 'name',
      '工号': 'employee_no',
      'employee_no': 'employee_no',
      '员工编号': 'employee_no',
      '证件名称': 'cert_name',
      'cert_name': 'cert_name',
      '证书名称': 'cert_name',
      '证件': 'cert_name',
      'certificate': 'cert_name',
      '证件类型': 'cert_name',
      '证件号码': 'cert_number',
      'cert_number': 'cert_number',
      '证书号码': 'cert_number',
      '证号': 'cert_number',
      'number': 'cert_number',
      '发证日期': 'issue_date',
      'issue_date': 'issue_date',
      '颁发日期': 'issue_date',
      '起始日期': 'issue_date',
      '到期日期': 'expire_date',
      'expire_date': 'expire_date',
      '有效期至': 'expire_date',
      '过期日期': 'expire_date',
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
    final order = ['name', 'employee_no', 'cert_name', 'cert_number', 'issue_date', 'expire_date'];
    final map = <String, int>{};
    for (int i = 0; i < columnCount && i < order.length; i++) {
      map[order[i]] = i;
    }
    return map;
  }

  /// 日期格式标准化
  String? _normalizeDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    // 标准格式
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateStr)) {
      return dateStr;
    }

    // 2024/01/15 格式
    final slash = dateStr.replaceAll('/', '-');
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(slash)) {
      return slash;
    }

    // 20240115 格式
    if (RegExp(r'^\d{8}$').hasMatch(dateStr) && dateStr.length == 8) {
      return '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
    }

    // Excel 日期序列号
    final numVal = int.tryParse(dateStr);
    if (numVal != null && numVal > 40000 && numVal < 60000) {
      final base = DateTime(1899, 12, 30);
      final date = base.add(Duration(days: numVal));
      return date.toIso8601String().substring(0, 10);
    }

    return dateStr;
  }
}
