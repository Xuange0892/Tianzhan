class Attendance {
  final int? id;
  final int workerId;
  final String date;
  final String? shiftType;
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInLocation;
  final String status;
  final double? workHours;
  final double overtimeHours;
  final String? remark;
  final String? createdAt;

  Attendance({
    this.id,
    required this.workerId,
    required this.date,
    this.shiftType,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.status = 'normal',
    this.workHours,
    this.overtimeHours = 0,
    this.remark,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'shift_type': shiftType,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_location': checkInLocation,
      'status': status,
      'work_hours': workHours,
      'overtime_hours': overtimeHours,
      'remark': remark,
      'created_at': createdAt,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      date: map['date'] as String,
      shiftType: map['shift_type'] as String?,
      checkInTime: map['check_in_time'] as String?,
      checkOutTime: map['check_out_time'] as String?,
      checkInLocation: map['check_in_location'] as String?,
      status: map['status'] as String? ?? 'normal',
      workHours: map['work_hours'] as double?,
      overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Attendance copyWith({
    int? id,
    int? workerId,
    String? date,
    String? shiftType,
    String? checkInTime,
    String? checkOutTime,
    String? checkInLocation,
    String? status,
    double? workHours,
    double? overtimeHours,
    String? remark,
    String? createdAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      status: status ?? this.status,
      workHours: workHours ?? this.workHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
