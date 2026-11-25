import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_mapper.dart';
import '../models/app_user.dart';
import '../models/quarantine.dart';
import '../repositories/quarantine_repository.dart';
import '../../core/utils/quarantine_scope.dart';
import '../models/permit.dart';

/// Quarantines for official accounts.
///
/// Declaring, activating and lifting run on the disease control officer's
/// device. The Cloud Functions that used to do this cannot be deployed on the
/// Spark plan. A quarantine covers its barangay's whole municipality/city:
/// declaring or re-activating it revokes, in the same write, the permits
/// issued there in the last [QuarantineScope.revokeWindowDays] days, and
/// lifting it lets new permits be issued again.
class FirebaseQuarantineRepository implements QuarantineRepository {
  FirebaseQuarantineRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const Duration _serverTimeout = Duration(seconds: 15);
  static const String _offlineMessage =
      'No connection. Quarantines can only be changed while online, so every '
      'affected permit is revoked at the same time.';

  /// Firestore allows at most 500 writes in one batch.
  static const int _batchLimit = 500;

  CollectionReference<Map<String, dynamic>> get _quarantines =>
      _firestore.collection(FirestorePaths.quarantines);

  @override
  Stream<List<Quarantine>> watchQuarantines() {
    return _quarantines
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Quarantine.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<int> declareQuarantine({
    required String areaId,
    required String areaName,
    required String reason,
    required AppUser officer,
  }) async {
    final String area = areaId.trim();
    final String why = reason.trim();
    if (area.isEmpty || why.isEmpty) {
      throw const AppException('Select an area and enter a reason.');
    }

    await _ensureMunicipalityFree(area);

    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref = _quarantines.doc();
    return _commitWithRevocations(
      area,
      now,
      (WriteBatch batch) => batch.set(ref, <String, dynamic>{
        'areaId': area,
        'areaName': areaName.trim().isEmpty ? area : areaName.trim(),
        'reason': why,
        'status': 'active',
        'startedAt': Timestamp.fromDate(now),
        'declaredBy': officer.id,
        'sourceMessageId': null,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<void> activateQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    final Quarantine quarantine = await _load(quarantineId);
    if (quarantine.isActive) {
      throw const AppException('This quarantine is already active.');
    }
    await _ensureMunicipalityFree(quarantine.areaId);

    final DateTime now = DateTime.now();
    await _commitWithRevocations(
      quarantine.areaId,
      now,
      (WriteBatch batch) => batch.update(
        _quarantines.doc(quarantine.id),
        <String, dynamic>{
          'status': 'active',
          'startedAt': Timestamp.fromDate(now),
          'liftedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ),
    );
  }

  @override
  Future<void> liftQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    final Quarantine quarantine = await _load(quarantineId);
    if (!quarantine.isActive) {
      throw const AppException('This quarantine is already lifted.');
    }
    await _write(
      _quarantines.doc(quarantine.id).update(<String, dynamic>{
        'status': 'lifted',
        'liftedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  /// One active quarantine per municipality/city: it already covers every
  /// barangay there.
  Future<void> _ensureMunicipalityFree(String areaId) async {
    final QuerySnapshot<Map<String, dynamic>> active = await _serverGet(
      _quarantines
          .where('status', isEqualTo: 'active')
          .get(const GetOptions(source: Source.server)),
    );
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in active.docs) {
      final Quarantine other = Quarantine.fromMap(doc.id, doc.data());
      if (QuarantineScope.sameMunicipality(other.areaId, areaId)) {
        throw AppException(
          'This municipality/city is already under an active quarantine '
          '(${other.areaName}).',
        );
      }
    }
  }

  Future<Quarantine> _load(String quarantineId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _serverGet(
      _quarantines
          .doc(quarantineId)
          .get(const GetOptions(source: Source.server)),
    );
    if (!snapshot.exists) {
      throw const AppException('That quarantine no longer exists.');
    }
    return Quarantine.fromMap(snapshot.id, snapshot.data()!);
  }

  /// Writes the quarantine change and, in the same write, revokes the permits
  /// it covers: issued in [areaId]'s municipality/city within the last
  /// [QuarantineScope.revokeWindowDays] days. Returns how many were revoked.
  Future<int> _commitWithRevocations(
    String areaId,
    DateTime now,
    void Function(WriteBatch batch) writeQuarantine,
  ) async {
    // Server side: issued permits from the window (index: status, issuedAt).
    // Client side: keep the ones in the same municipality/city.
    final QuerySnapshot<Map<String, dynamic>> recent = await _serverGet(
      _firestore
          .collection(FirestorePaths.permits)
          .where('status', isEqualTo: 'issued')
          .where(
            'issuedAt',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(QuarantineScope.revokeCutoff(now)),
          )
          .get(const GetOptions(source: Source.server)),
    );
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> affectedDocs =
        recent.docs
            .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                QuarantineScope.revokes(
                  Permit.fromMap(doc.id, doc.data()),
                  quarantineAreaId: areaId,
                  quarantineAt: now,
                ))
            .toList();

    final Map<String, dynamic> revoke = <String, dynamic>{
      'status': 'revoked',
      'revokedAt': Timestamp.fromDate(now),
      'revokedReason': 'quarantine',
    };

    // The quarantine goes in the first batch with as many revocations as fit,
    // so in the usual case (under 500 permits) everything is one atomic write.
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        affectedDocs;
    WriteBatch batch = _firestore.batch();
    writeQuarantine(batch);
    int inBatch = 1;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      if (inBatch == _batchLimit) {
        await _write(batch.commit());
        batch = _firestore.batch();
        inBatch = 0;
      }
      batch.update(doc.reference, revoke);
      inBatch++;
    }
    await _write(batch.commit());
    return docs.length;
  }

  /// Runs a server read and turns "no connection" into a clear message.
  Future<T> _serverGet<T>(Future<T> read) async {
    try {
      return await read.timeout(_serverTimeout);
    } on TimeoutException {
      throw const AppException(_offlineMessage);
    } on FirebaseException catch (error) {
      if (error.code == 'unavailable') {
        throw const AppException(_offlineMessage);
      }
      throw ErrorMapper.firestore(error);
    }
  }

  Future<void> _write(Future<void> write) async {
    try {
      await write.timeout(_serverTimeout);
    } on TimeoutException {
      throw const AppException(_offlineMessage);
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }
}
