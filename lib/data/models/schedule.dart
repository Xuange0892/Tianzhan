class Schedule {
  final int? id;
  final int workerId;
  final String date;
  final String shiftType;
  final String? position;
  final bool isDutyLeader;
  final String status;
  final int? exchangeWith;
  final String? remark;
  final String? createdAt;

  Schedule({
    this.id,
    required this.workerId,
    required this.date,
    required this.shiftType,
    this.position,
    this.isDutyLeader = false,
    this.status = 'scheduled',
    this.exchangeWith,
    this.remark,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'shift_type': shiftType,
      'position': position,
      'is_duty_leader': isDutyLeader ? 1 : 0,
      'status': status,
      'exchange_with': exchangeWith,
      'remark': remark,
      'created_at': createdAt,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      workerId: map['worker_id'] as int,
      date: map['date'] as String,
      shiftType: map['shift_type'] as String,
      position: map['position'] as String?,
      isDutyLeader: (map['is_duty_leader'] as int?) == 1,
      status: map['status'] as String? ?? 'scheduled',
      exchangeWith: map['exchange_with'] as int?,
      remark: map['remark'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Schedule copyWith({
    int? id,
    int? workerId,
    String? date,
    String? shiftType,
    String? position,
    bool? isDutyLeader,
    String? status,
    int? exchangeWith,
    String? remark,
    String? createdAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      position: position ?? this.position,
      isDutyLeader: isDutyLeader ?? this.isDutyLeader,
      status: status ?? this.status,
      exchangeWith: exchangeWith ?? this.exchangeWith,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
