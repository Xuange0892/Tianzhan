class Worker {
  final int? id;
  final String name;
  final String employeeNo;
  final String? idCard;
  final String? phone;
  final String? department;
  final String? jobType;
  final String? jobLevel;
  final String? certificateNo;
  final String? certificateExpireDate;
  final String? entryDate;
  final String status;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? photoPath;
  final String? remark;
  final String? createdAt;
  final String? updatedAt;

  Worker({
    this.id,
    required this.name,
    required this.employeeNo,
    this.idCard,
    this.phone,
    this.department,
    this.jobType,
    this.jobLevel,
    this.certificateNo,
    this.certificateExpireDate,
    this.entryDate,
    this.status = 'active',
    this.emergencyContact,
    this.emergencyPhone,
    this.photoPath,
    this.remark,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'employee_no': employeeNo,
      'id_card': idCard,
      'phone': phone,
      'department': department,
      'job_type': jobType,
      'job_level': jobLevel,
      'certificate_no': certificateNo,
      'certificate_expire_date': certificateExpireDate,
      'entry_date': entryDate,
      'status': status,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'photo_path': photoPath,
      'remark': remark,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as int?,
      name: map['name'] as String,
      employeeNo: map['employee_no'] as String,
      idCard: map['id_card'] as String?,
      phone: map['phone'] as String?,
      department: map['department'] as String?,
      jobType: map['job_type'] as String?,
      jobLevel: map['job_level'] as String?,
      certificateNo: map['certificate_no'] as String?,
      certificateExpireDate: map['certificate_expire_date'] as String?,
      entryDate: map['entry_date'] as String?,
      status: map['status'] as String? ?? 'active',
      emergencyContact: map['emergency_contact'] as String?,
      emergencyPhone: map['emergency_phone'] as String?,
      photoPath: map['photo_path'] as String?,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Worker copyWith({
    int? id,
    String? name,
    String? employeeNo,
    String? idCard,
    String? phone,
    String? department,
    String? jobType,
    String? jobLevel,
    String? certificateNo,
    String? certificateExpireDate,
    String? entryDate,
    String? status,
    String? emergencyContact,
    String? emergencyPhone,
    String? photoPath,
    String? remark,
    String? createdAt,
    String? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeNo: employeeNo ?? this.employeeNo,
      idCard: idCard ?? this.idCard,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      jobType: jobType ?? this.jobType,
      jobLevel: jobLevel ?? this.jobLevel,
      certificateNo: certificateNo ?? this.certificateNo,
      certificateExpireDate: certificateExpireDate ?? this.certificateExpireDate,
      entryDate: entryDate ?? this.entryDate,
      status: status ?? this.status,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      photoPath: photoPath ?? this.photoPath,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
