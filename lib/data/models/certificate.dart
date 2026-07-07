/// 证件模型
/// 管理人员的各类证书/证件信息
class Certificate {
  /// 证件ID
  final int? id;

  /// 人员ID
  final int workerId;

  /// 证件名称
  final String certName;

  /// 证件编号
  final String? certNo;

  /// 证件照片路径
  final String? certPhotoPath;

  /// 发证日期
  final String? issueDate;

  /// 过期日期
  final String? expireDate;

  /// 备注
  final String? remark;

  /// 创建时间
  final String? createdAt;

  /// 更新时间
  final String? updatedAt;

  Certificate({
    this.id,
    required this.workerId,
    required this.certName,
    this.certNo,
    this.certPhotoPath,
    this.issueDate,
    this.expireDate,
    this.remark,
    this.createdAt,
    this.updatedAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'cert_name': certName,
      'cert_no': certNo,
      'cert_photo_path': certPhotoPath,
      'issue_date': issueDate,
      'expire_date': expireDate,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      certName: map['cert_name'] as String,
      certNo: map['cert_no'] as String?,
      certPhotoPath: map['cert_photo_path'] as String?,
      issueDate: map['issue_date'] as String?,
      expireDate: map['expire_date'] as String?,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  Certificate copyWith({
    int? id,
    int? workerId,
    String? certName,
    String? certNo,
    String? certPhotoPath,
    String? issueDate,
    String? expireDate,
    String? remark,
    String? createdAt,
    String? updatedAt,
    // 别名参数，方便旧代码调用
    String? name,
    String? number,
    String? imagePath,
  }) {
    return Certificate(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      certName: certName ?? name ?? this.certName,
      certNo: certNo ?? number ?? this.certNo,
      certPhotoPath: certPhotoPath ?? imagePath ?? this.certPhotoPath,
      issueDate: issueDate ?? this.issueDate,
      expireDate: expireDate ?? this.expireDate,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ==================== 别名 getter（兼容屏幕文件引用） ====================

  /// 证件名称别名
  String get name => certName;

  /// 证件编号别名
  String? get number => certNo;

  /// 证件照片路径别名
  String? get imagePath => certPhotoPath;
}
