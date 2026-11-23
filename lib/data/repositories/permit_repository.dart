import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/date_utils.dart';
import '../demo/demo_signing.dart';
import '../demo/demo_store.dart';
import '../enums/permit_status.dart';
import '../enums/scan_result.dart';
import '../models/animal.dart';
import '../models/app_user.dart';
import '../models/permit.dart';
import '../models/quarantine.dart';
import '../models/verification.dart';

abstract class PermitRepository {
  Stream<List<Permit>> watchPermits({int limit = AppConfig.pageSize});

  Stream<Permit?> watchPermit(String id);

  Stream<List<Verification>> watchVerifications(String inspectorUid);

  /// Checkpoint scans for one animal, newest first.
  Stream<List<Verification>> watchVerificationsForAnimal(String animalId);

  Future<Permit> issuePermit({
    required Animal animal,
    required String origin,
    required String destination,
    required DateTime travelDate,
    required AppUser clerk,
  });

  Future<VerificationOutcome> verifyPermit({
    required String permitId,
    required String signedCode,
    required String checkpointName,
    required AppUser inspector,
    required bool offline,
  });
}

class DemoPermitRepository implements PermitRepository {
  DemoPermitRepository(this._store);

  final DemoStore _store;
  final Uuid _uuid = const Uuid();

  @override
  Stream<List<Permit>> watchPermits({int limit = AppConfig.pageSize}) =>
      _store.watchPermits(limit: limit);

  @override
  Stream<Permit?> watchPermit(String id) => _store.watchPermit(id);

  @override
  Stream<List<Verification>> watchVerifications(String inspectorUid) =>
      _store.watchVerifications(inspectorUid);

  @override
  Stream<List<Verification>> watchVerificationsForAnimal(String animalId) =>
      _store.watchVerificationsForAnimal(animalId);

  @override
  Future<Permit> issuePermit({
    required Animal animal,
    required String origin,
    required String destination,
    required DateTime travelDate,
    required AppUser clerk,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final DateTime? until = animal.vaccinatedUntil;
    if (until == null) {
      throw const AppException('This animal has no vaccination record.');
    }
    if (!animal.isVaccinatedFor(travelDate)) {
      throw const AppException(
        'This animal is not vaccinated for the selected travel date.',
      );
    }

    final Quarantine? quarantine = _store.activeQuarantineFor(animal.areaId);
    if (quarantine != null) {
      throw AppException(
        '${animal.barangay} is under an active quarantine. New permits are blocked.',
      );
    }

    final String permitId =
        'PMT-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final Permit permit = Permit(
      id: permitId,
      animalId: animal.id,
      farmerId: animal.farmerId,
      origin: origin.trim(),
      destination: destination.trim(),
      travelDate: dateOnly(travelDate),
      requestedBy: clerk.id,
      areaId: animal.areaId,
      status: PermitStatus.issued,
      signedCode: signPermitId(permitId),
      validUntil: minDate(endOfDay(travelDate), endOfDay(until))!,
      issuedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _store.addPermit(permit);
    return permit;
  }

  @override
  Future<VerificationOutcome> verifyPermit({
    required String permitId,
    required String signedCode,
    required String checkpointName,
    required AppUser inspector,
    required bool offline,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final DateTime now = DateTime.now();

    if (offline) {
      final Permit? cached = _store.permitById(permitId);
      return VerificationOutcome(
        result: ScanResult.unverified,
        message:
            'You are offline. The signed code cannot be checked until you reconnect.',
        checkedAt: now,
        signatureValid: false,
        offline: true,
        permit: cached,
      );
    }

    final Permit? permit = _store.permitById(permitId);
    if (permit == null) {
      return VerificationOutcome(
        result: ScanResult.invalid,
        message: 'No permit with that ID exists in the registry.',
        checkedAt: now,
        signatureValid: false,
        offline: false,
      );
    }

    final bool signatureValid =
        verifyPermitSignature(permit.id, signedCode);

    ScanResult result;
    String message;
    if (!signatureValid) {
      result = ScanResult.invalid;
      message = 'The signed code does not match. This permit may be forged.';
    } else if (permit.effectiveStatus(now) == PermitStatus.revoked) {
      result = ScanResult.revoked;
      message = 'This permit was revoked by a quarantine or the permit office.';
    } else if (permit.effectiveStatus(now) == PermitStatus.expired) {
      result = ScanResult.expired;
      message = 'This permit is past its valid-until date.';
    } else {
      result = ScanResult.valid;
      message = 'Signed code verified. The permit is genuine and still valid.';
    }

    _store.addVerification(
      Verification(
        id: _uuid.v4(),
        permitId: permit.id,
        animalId: permit.animalId,
        result: result,
        inspectorUid: inspector.id,
        checkpointName: checkpointName.trim().isEmpty
            ? 'Unnamed checkpoint'
            : checkpointName.trim(),
        scannedAt: now,
        wasOffline: false,
        signatureValid: signatureValid,
      ),
    );

    return VerificationOutcome(
      result: result,
      message: message,
      checkedAt: now,
      signatureValid: signatureValid,
      offline: false,
      permit: permit,
    );
  }
}
