/// 签到记录模型
/// 记录某人员对某签到事项的签到状态
class SignInRecord {
  /// 记录ID
  final int? id;

  /// 签到事项ID
  final int eventId;

  /// 人员ID
  final int workerId;

  /// 是否已签到
  final bool signed;

  /// 签到时间
  final String? signedAt;

  SignInRecord({
    this.id,
    required this.eventId,
    required this.workerId,
    this.signed = false,
    this.signedAt,
  });

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'worker_id': workerId,
      'signed': signed ? 1 : 0,
      'signed_at': signedAt,
    };
  }

  /// 从数据库 Map 创建实例
  factory SignInRecord.fromMap(Map<String, dynamic> map) {
    return SignInRecord(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      workerId: map['worker_id'] as int,
      signed: (map['signed'] as int?) == 1,
      signedAt: map['signed_at'] as String?,
    );
  }

  /// 复制并替换部分字段
  SignInRecord copyWith({
    int? id,
    int? eventId,
    int? workerId,
    bool? signed,
    String? signedAt,
  }) {
    return SignInRecord(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      workerId: workerId ?? this.workerId,
      signed: signed ?? this.signed,
      signedAt: signedAt ?? this.signedAt,
    );
  }
}
