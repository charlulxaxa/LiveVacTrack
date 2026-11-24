import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../firebase/firebase_functions_service.dart';
import '../models/app_user.dart';
import '../models/quarantine.dart';
import '../repositories/quarantine_repository.dart';

class FirebaseQuarantineRepository implements QuarantineRepository {
  FirebaseQuarantineRepository(this._firestore, this._functions, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;
  final FirebaseFunctionsService _functions;

  @override
  Stream<List<Quarantine>> watchQuarantines() {
    return _firestore
        .collection(_paths.quarantines)
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
    try {
      return await _functions.declareQuarantine(
        areaId: areaId,
        areaName: areaName,
        reason: reason,
      );
    } catch (error) {
      throw ErrorMapper.functions(error);
    }
  }

  @override
  Future<void> activateQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    try {
      await _functions.activateQuarantine(quarantineId: quarantineId);
    } catch (error) {
      throw ErrorMapper.functions(error);
    }
  }

  @override
  Future<void> liftQuarantine({
    required String quarantineId,
    required AppUser officer,
  }) async {
    try {
      await _functions.liftQuarantine(quarantineId: quarantineId);
    } catch (error) {
      throw ErrorMapper.functions(error);
    }
  }
}
