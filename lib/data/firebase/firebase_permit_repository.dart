import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/utils/date_utils.dart';
import '../enums/scan_result.dart';
import '../firebase/firebase_functions_service.dart';
import '../models/animal.dart';
import '../models/app_user.dart';
import '../models/permit.dart';
import '../models/verification.dart';
import '../repositories/permit_repository.dart';

class FirebasePermitRepository implements PermitRepository {
  FirebasePermitRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctionsService _functions;

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

  @override
  Future<Permit> issuePermit({
    required Animal animal,
    required String origin,
    required String destination,
    required DateTime travelDate,
    required AppUser clerk,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = await _functions.issuePermit(
        animalId: animal.id,
        origin: origin,
        destination: destination,
        travelDate: travelDate,
      );
    } catch (error) {
      throw ErrorMapper.functions(error);
    }
    final String permitId = (data['permitId'] as String?) ?? '';
    final dynamic permitData = data['permit'];
    if (permitData is Map) {
      return Permit.fromMap(
        permitId,
        Map<String, dynamic>.from(permitData),
      );
    }
    final DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection(FirestorePaths.permits)
          .doc(permitId)
          .get();
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
    if (!snapshot.exists) {
      throw StateError('The permit service did not return a permit.');
    }
    return Permit.fromMap(snapshot.id, snapshot.data()!);
  }

  @override
  Future<VerificationOutcome> verifyPermit({
    required String permitId,
    required String signedCode,
    required String checkpointName,
    required AppUser inspector,
    required bool offline,
  }) async {
    if (offline) {
      Permit? cached;
      try {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore
                .collection(FirestorePaths.permits)
                .doc(permitId)
                .get(const GetOptions(source: Source.cache));
        if (snapshot.exists) {
          cached = Permit.fromMap(snapshot.id, snapshot.data()!);
        }
      } on FirebaseException {
        cached = null;
      }
      return VerificationOutcome(
        result: ScanResult.unverified,
        message:
            'You are offline. The signed code cannot be checked until you reconnect.',
        checkedAt: DateTime.now(),
        signatureValid: false,
        offline: true,
        permit: cached,
      );
    }

    final Map<String, dynamic> data;
    try {
      data = await _functions.verifyPermit(
        permitId: permitId,
        signedCode: signedCode,
        checkpointName: checkpointName,
      );
    } catch (error) {
      throw ErrorMapper.functions(error);
    }

    final dynamic permitData = data['permit'];
    final Permit? permit = permitData is Map
        ? Permit.fromMap(
            (data['permitId'] as String?) ?? permitId,
            Map<String, dynamic>.from(permitData),
          )
        : null;

    return VerificationOutcome(
      result: ScanResult.fromWire(data['result'] as String?),
      message: (data['message'] as String?) ?? 'Verification complete.',
      checkedAt: dateFromValue(data['checkedAt']) ?? DateTime.now(),
      signatureValid: (data['signatureValid'] as bool?) ?? false,
      offline: false,
      permit: permit,
    );
  }
}
