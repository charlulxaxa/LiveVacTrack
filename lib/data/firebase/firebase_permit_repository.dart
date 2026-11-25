import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/utils/date_utils.dart';
import '../enums/permit_status.dart';
import '../enums/scan_result.dart';
import '../models/animal.dart';
import '../models/app_user.dart';
import '../models/permit.dart';
import '../models/verification.dart';
import '../repositories/permit_repository.dart';
import '../../core/utils/quarantine_scope.dart';
import '../models/quarantine.dart';

class FirebasePermitRepository implements PermitRepository {
  FirebasePermitRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Permit>> watchPermits({int limit = AppConfig.pageSize}) {
    return _firestore
        .collection(FirestorePaths.permits)
        .orderBy('issuedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Permit.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<Permit?> watchPermit(String id) {
    return _firestore
        .collection(FirestorePaths.permits)
        .doc(id)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
            doc.exists ? Permit.fromMap(doc.id, doc.data()!) : null);
  }

  @override
  Stream<List<Verification>> watchVerifications(String inspectorUid) {
    return _firestore
        .collection(FirestorePaths.verifications)
        .where('inspectorUid', isEqualTo: inspectorUid)
        .orderBy('scannedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Verification.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Verification>> watchVerificationsForAnimal(String animalId) {
    return _firestore
        .collection(FirestorePaths.verifications)
        .where('animalId', isEqualTo: animalId)
        .orderBy('scannedAt', descending: true)
        .limit(AppConfig.pageSize)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Verification.fromMap(doc.id, doc.data()))
            .toList());
  }

  static const Duration _serverTimeout = Duration(seconds: 15);
  static const String _offlineIssueMessage =
      'No connection. Permits can only be issued while online, so the '
      'vaccination and quarantine checks use the latest records.';

  /// Issues the permit from the clerk's device. On the Spark plan the
  /// `issuePermit` Cloud Function cannot be deployed, so the same checks run
  /// here against fresh server data: the travel date is not in the past, the
  /// animal is vaccinated for it, and its area has no active quarantine.
  ///
  /// The signed code is a random 256-bit token stored on the permit. A scanned
  /// QR is genuine when its code matches the stored one.
  @override
  Future<Permit> issuePermit({
    required Animal animal,
    required String origin,
    required String destination,
    required DateTime travelDate,
    required AppUser clerk,
    String? originAreaId,
  }) async {
    if (origin.trim().isEmpty || destination.trim().isEmpty) {
      throw const AppException('Origin and destination are required.');
    }
    if (dateOnly(travelDate).isBefore(dateOnly(DateTime.now()))) {
      throw const AppException('The travel date cannot be in the past.');
    }

    // Re-read the animal from the server: the list on screen may be stale.
    final DocumentSnapshot<Map<String, dynamic>> animalSnapshot =
        await _serverGet(
      _firestore.collection(FirestorePaths.animals).doc(animal.id).get(
            const GetOptions(source: Source.server),
          ),
    );
    if (!animalSnapshot.exists) {
      throw const AppException('That animal is not registered.');
    }
    final Animal current =
        Animal.fromMap(animalSnapshot.id, animalSnapshot.data()!);
    final DateTime? vaccinatedUntil = current.vaccinatedUntil;
    if (vaccinatedUntil == null || !current.isVaccinatedFor(travelDate)) {
      throw const AppException(
        'The animal is not vaccinated for the selected travel date.',
      );
    }

    // A quarantine covers its barangay's whole municipality/city.
    final QuerySnapshot<Map<String, dynamic>> active = await _serverGet(
      _firestore
          .collection(FirestorePaths.quarantines)
          .where('status', isEqualTo: 'active')
          .get(const GetOptions(source: Source.server)),
    );
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in active.docs) {
      final Quarantine quarantine = Quarantine.fromMap(doc.id, doc.data());
      if (QuarantineScope.sameMunicipality(quarantine.areaId, current.areaId)) {
        throw AppException(
          '${current.barangay} is in a municipality under quarantine '
          '(${quarantine.areaName}). New permits are blocked.',
        );
      }
      if (originAreaId != null &&
          QuarantineScope.sameMunicipality(quarantine.areaId, originAreaId)) {
        throw AppException(
          'The origin ${origin.trim()} is in a municipality under quarantine '
          '(${quarantine.areaName}). New permits are blocked.',
        );
      }
    }

    final DateTime now = DateTime.now();
    final String permitId = 'PMT-${_randomHex(4).toUpperCase()}';
    final Permit permit = Permit(
      id: permitId,
      animalId: current.id,
      farmerId: current.farmerId,
      origin: origin.trim(),
      destination: destination.trim(),
      travelDate: dateOnly(travelDate),
      requestedBy: clerk.id,
      areaId: current.areaId,
      status: PermitStatus.issued,
      signedCode: _randomHex(32),
      validUntil: minDate(endOfDay(travelDate), endOfDay(vaccinatedUntil))!,
      issuedAt: now,
      createdAt: now,
      originAreaId: originAreaId,
    );

    try {
      await _firestore
          .collection(FirestorePaths.permits)
          .doc(permitId)
          .set(permit.toMap())
          .timeout(_serverTimeout);
    } on TimeoutException {
      throw const AppException(_offlineIssueMessage);
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
    return permit;
  }

  /// Runs a server read and turns "no connection" into a clear message.
  Future<T> _serverGet<T>(Future<T> read) async {
    try {
      return await read.timeout(_serverTimeout);
    } on TimeoutException {
      throw const AppException(_offlineIssueMessage);
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') {
        throw const AppException(_offlineIssueMessage);
      }
      throw ErrorMapper.firestore(error);
    }
  }

  static String _randomHex(int bytes) {
    final Random random = Random.secure();
    return List<String>.generate(
      bytes,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Verifies a scanned permit from the inspector's device, the same way demo
  /// mode does, instead of calling the `verifyPermit` Cloud Function (which
  /// cannot be deployed on the Spark plan).
  ///
  /// Online: reads the permit record from the server, checks the scanned code
  /// matches it, then revoked / expired, and logs the scan.
  ///
  /// Offline, or when the server cannot be reached (an emulator can report a
  /// connection it does not have): never VALID. The result is UNVERIFIED with
  /// the copy of the permit synced on this device, if any.
  @override
  Future<VerificationOutcome> verifyPermit({
    required String permitId,
    required String signedCode,
    required String checkpointName,
    required AppUser inspector,
    required bool offline,
  }) async {
    final String id = permitId.trim();
    final String code = signedCode.trim().toLowerCase();
    final String checkpoint = checkpointName.trim().isEmpty
        ? 'Unnamed checkpoint'
        : checkpointName.trim();

    if (id.isEmpty) {
      return VerificationOutcome(
        result: ScanResult.invalid,
        message: 'The code does not contain a permit ID.',
        checkedAt: DateTime.now(),
        signatureValid: false,
        offline: offline,
      );
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _firestore.collection(FirestorePaths.permits).doc(id);

    DocumentSnapshot<Map<String, dynamic>>? snapshot;
    if (!offline) {
      try {
        snapshot = await ref
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 8));
      } on TimeoutException {
        snapshot = null;
      } on FirebaseException catch (error) {
        if (error.code != 'unavailable') throw ErrorMapper.firestore(error);
        snapshot = null;
      }
    }

    if (snapshot == null) {
      return _offlineOutcome(ref, id, code, checkpoint, inspector);
    }

    final DateTime now = DateTime.now();
    final Permit? permit =
        snapshot.exists ? Permit.fromMap(snapshot.id, snapshot.data()!) : null;
    final bool signatureValid =
        permit != null && _codesMatch(permit.signedCode, code);

    final ScanResult result;
    final String message;
    if (permit == null) {
      result = ScanResult.invalid;
      message = 'No permit with that ID exists in the registry.';
    } else if (!signatureValid) {
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

    _logScan(
      permitId: id,
      animalId: permit?.animalId ?? '',
      result: result,
      inspector: inspector,
      checkpoint: checkpoint,
      scannedAt: now,
      wasOffline: false,
      signatureValid: signatureValid,
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

  Future<VerificationOutcome> _offlineOutcome(
    DocumentReference<Map<String, dynamic>> ref,
    String id,
    String code,
    String checkpoint,
    AppUser inspector,
  ) async {
    Permit? cached;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get(const GetOptions(source: Source.cache));
      if (snapshot.exists) {
        cached = Permit.fromMap(snapshot.id, snapshot.data()!);
      }
    } on FirebaseException {
      cached = null;
    }

    final String message;
    if (cached == null) {
      message = 'You are offline and this permit is not saved on this device. '
          'It cannot be checked until you reconnect.';
    } else if (_codesMatch(cached.signedCode, code)) {
      message = 'You are offline. The code matches the copy saved on this '
          'device, but the permit may have been revoked since. Check again '
          'when you reconnect.';
    } else {
      message = 'You are offline, and the code does NOT match the copy saved '
          'on this device. Treat this permit as suspect.';
    }

    final DateTime now = DateTime.now();
    _logScan(
      permitId: id,
      animalId: cached?.animalId ?? '',
      result: ScanResult.unverified,
      inspector: inspector,
      checkpoint: checkpoint,
      scannedAt: now,
      wasOffline: true,
      signatureValid: false,
    );

    return VerificationOutcome(
      result: ScanResult.unverified,
      message: message,
      checkedAt: now,
      signatureValid: false,
      offline: true,
      permit: cached,
    );
  }

  /// Records the scan in the inspector's history. Not awaited: offline the
  /// write waits in Firestore's queue until the device reconnects, and the
  /// result must not wait for it.
  void _logScan({
    required String permitId,
    required String animalId,
    required ScanResult result,
    required AppUser inspector,
    required String checkpoint,
    required DateTime scannedAt,
    required bool wasOffline,
    required bool signatureValid,
  }) {
    final Verification verification = Verification(
      id: '',
      permitId: permitId,
      animalId: animalId,
      result: result,
      inspectorUid: inspector.id,
      checkpointName: checkpoint,
      scannedAt: scannedAt,
      wasOffline: wasOffline,
      signatureValid: signatureValid,
    );
    unawaited(
      _firestore
          .collection(FirestorePaths.verifications)
          .add(verification.toMap())
          .then((_) {}, onError: (Object error) {
        debugPrint('Could not log the scan: $error');
      }),
    );
  }

  /// Constant-time comparison so response timing does not leak the code.
  static bool _codesMatch(String expected, String actual) {
    final String a = expected.trim().toLowerCase();
    if (a.isEmpty || a.length != actual.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ actual.codeUnitAt(i);
    }
    return diff == 0;
  }
}
