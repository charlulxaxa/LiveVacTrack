import '../../core/utils/date_utils.dart';
import '../enums/quarantine_status.dart';

class Quarantine {
  const Quarantine({
    required this.id,
    required this.areaId,
    required this.areaName,
    required this.reason,
    required this.status,
    required this.startedAt,
    this.liftedAt,
    this.declaredBy,
    this.sourceMessageId,
  });

  final String id;
  final String areaId;
  final String areaName;
  final String reason;
  final QuarantineStatus status;
  final DateTime startedAt;
  final DateTime? liftedAt;
  final String? declaredBy;
  final String? sourceMessageId;

  bool get isActive => status == QuarantineStatus.active;

  factory Quarantine.fromMap(String id, Map<String, dynamic> map) {
    return Quarantine(
      id: id,
      areaId: (map['areaId'] as String?) ?? '',
      areaName: (map['areaName'] as String?) ?? '',
      reason: (map['reason'] as String?) ?? '',
      status: QuarantineStatus.fromWire(map['status'] as String?),
      startedAt: dateFromValue(map['startedAt']) ?? DateTime.now(),
      liftedAt: dateFromValue(map['liftedAt']),
      declaredBy: map['declaredBy'] as String?,
      sourceMessageId: map['sourceMessageId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'areaId': areaId,
        'areaName': areaName,
        'reason': reason,
        'status': status.wire,
        'startedAt': startedAt,
        if (liftedAt != null) 'liftedAt': liftedAt,
        'declaredBy': declaredBy,
        'sourceMessageId': sourceMessageId,
      };
}
