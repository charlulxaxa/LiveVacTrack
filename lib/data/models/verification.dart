import '../../core/utils/date_utils.dart';
import '../enums/scan_result.dart';
import 'permit.dart';

class Verification {
  const Verification({
    required this.id,
    required this.permitId,
    required this.result,
    required this.inspectorUid,
    required this.checkpointName,
    required this.scannedAt,
    required this.wasOffline,
    required this.signatureValid,
    this.animalId = '',
  });

  final String id;
  final String permitId;

  /// Animal the scanned permit belongs to. Empty when the permit was unknown.
  final String animalId;
  final ScanResult result;
  final String inspectorUid;
  final String checkpointName;
  final DateTime scannedAt;
  final bool wasOffline;
  final bool signatureValid;

  factory Verification.fromMap(String id, Map<String, dynamic> map) {
    return Verification(
      id: id,
      permitId: (map['permitId'] as String?) ?? '',
      animalId: (map['animalId'] as String?) ?? '',
      result: ScanResult.fromWire(map['result'] as String?),
      inspectorUid: (map['inspectorUid'] as String?) ?? '',
      checkpointName: (map['checkpointName'] as String?) ?? '',
      scannedAt: dateFromValue(map['scannedAt']) ?? DateTime.now(),
      wasOffline: (map['wasOffline'] as bool?) ?? false,
      signatureValid: (map['signatureValid'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'permitId': permitId,
        if (animalId.isNotEmpty) 'animalId': animalId,
        'result': result.wire,
        'inspectorUid': inspectorUid,
        'checkpointName': checkpointName,
        'scannedAt': scannedAt,
        'wasOffline': wasOffline,
        'signatureValid': signatureValid,
      };
}

/// Result returned to the checkpoint screen after a scan or manual lookup.
class VerificationOutcome {
  const VerificationOutcome({
    required this.result,
    required this.message,
    required this.checkedAt,
    required this.signatureValid,
    required this.offline,
    this.permit,
  });

  final ScanResult result;
  final String message;
  final DateTime checkedAt;
  final bool signatureValid;
  final bool offline;
  final Permit? permit;

  bool get isAuthoritative => !offline && result != ScanResult.unverified;
}
