import '../../core/utils/date_utils.dart';
import '../enums/permit_status.dart';

class Permit {
  const Permit({
    required this.id,
    required this.animalId,
    required this.farmerId,
    required this.origin,
    required this.destination,
    required this.travelDate,
    required this.requestedBy,
    required this.areaId,
    required this.status,
    required this.signedCode,
    required this.validUntil,
    this.issuedAt,
    this.createdAt,
    this.originAreaId,
  });

  final String id;
  final String animalId;
  final String farmerId;
  final String origin;
  final String destination;
  final DateTime travelDate;
  final String requestedBy;
  final String areaId;
  final PermitStatus status;
  final String signedCode;
  final DateTime validUntil;
  final DateTime? issuedAt;
  final DateTime? createdAt;

  /// Barangay the animal is moving from (PSGC code or demo area id). Can
  /// differ from [areaId], the barangay the animal is registered in. Missing
  /// on permits issued before it was recorded.
  final String? originAreaId;

  /// Every barangay this permit is tied to. A quarantine covering either the
  /// animal's home or the origin applies to the permit.
  List<String> get quarantineAreaIds => <String>[
        areaId,
        if (originAreaId != null && originAreaId!.isNotEmpty) originAreaId!,
      ];

  /// Expiry is derived so a permit that passes its date never looks valid.
  PermitStatus effectiveStatus([DateTime? now]) {
    if (status == PermitStatus.revoked) return PermitStatus.revoked;
    if (validUntil.isBefore(now ?? DateTime.now())) return PermitStatus.expired;
    return status;
  }

  bool get isIssued => effectiveStatus() == PermitStatus.issued;

  Permit copyWith({
    PermitStatus? status,
    String? signedCode,
    DateTime? validUntil,
    DateTime? issuedAt,
  }) {
    return Permit(
      id: id,
      animalId: animalId,
      farmerId: farmerId,
      origin: origin,
      destination: destination,
      travelDate: travelDate,
      requestedBy: requestedBy,
      areaId: areaId,
      status: status ?? this.status,
      signedCode: signedCode ?? this.signedCode,
      validUntil: validUntil ?? this.validUntil,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt,
      originAreaId: originAreaId,
    );
  }

  factory Permit.fromMap(String id, Map<String, dynamic> map) {
    return Permit(
      id: id,
      animalId: (map['animalId'] as String?) ?? '',
      farmerId: (map['farmerId'] as String?) ?? '',
      origin: (map['origin'] as String?) ?? '',
      destination: (map['destination'] as String?) ?? '',
      travelDate: dateFromValue(map['travelDate']) ?? DateTime.now(),
      requestedBy: (map['requestedBy'] as String?) ?? '',
      areaId: (map['areaId'] as String?) ?? '',
      status: PermitStatus.fromWire(map['status'] as String?),
      signedCode: (map['signedCode'] as String?) ?? '',
      validUntil: dateFromValue(map['validUntil']) ?? DateTime.now(),
      issuedAt: dateFromValue(map['issuedAt']),
      createdAt: dateFromValue(map['createdAt']),
      originAreaId: map['originAreaId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'animalId': animalId,
        'farmerId': farmerId,
        'origin': origin,
        'destination': destination,
        'travelDate': travelDate,
        'requestedBy': requestedBy,
        'areaId': areaId,
        'status': status.wire,
        'signedCode': signedCode,
        'validUntil': validUntil,
        'issuedAt': issuedAt ?? DateTime.now(),
        'createdAt': createdAt ?? DateTime.now(),
        if (originAreaId != null) 'originAreaId': originAreaId,
      };
}
