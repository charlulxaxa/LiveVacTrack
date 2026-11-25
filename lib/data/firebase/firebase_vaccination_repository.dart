import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../../core/utils/date_utils.dart';
import '../enums/vax_status.dart';
import '../models/vaccination.dart';
import '../repositories/vaccination_repository.dart';

class FirebaseVaccinationRepository implements VaccinationRepository {
  FirebaseVaccinationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Vaccination>> watchForAnimal(String animalId) {
    return _firestore
        .collection(FirestorePaths.vaccinations)
        .where('animalId', isEqualTo: animalId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<Vaccination> rows = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Vaccination.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((Vaccination a, Vaccination b) =>
            b.dateGiven.compareTo(a.dateGiven));
      return rows;
    });
  }

  /// Saves the vaccination and updates the animal's vaccination status in one
  /// batch, as demo mode does. This used to be left to the
  /// `onVaccinationCreated` Cloud Function, which cannot be deployed on the
  /// Spark plan, so the animal never became eligible for a permit.
  @override
  Future<void> record(Vaccination vaccination) async {
    try {
      final DocumentReference<Map<String, dynamic>> animalRef = _firestore
          .collection(FirestorePaths.animals)
          .doc(vaccination.animalId);

      // Keep a later valid-until date if the animal already has one (for
      // example when an older vaccination is entered after a newer one).
      DateTime? currentUntil;
      try {
        final DocumentSnapshot<Map<String, dynamic>> animal =
            await animalRef.get();
        currentUntil = dateFromValue(animal.data()?['vaccinatedUntil']);
      } on FirebaseException {
        currentUntil = null;
      }

      final WriteBatch batch = _firestore.batch()
        ..set(
          _firestore
              .collection(FirestorePaths.vaccinations)
              .doc(vaccination.id),
          vaccination.toMap(),
        );

      if (currentUntil == null || vaccination.validUntil.isAfter(currentUntil)) {
        batch.update(animalRef, <String, dynamic>{
          'vaxStatus': vaccination.validUntil.isAfter(DateTime.now())
              ? VaxStatus.valid.wire
              : VaxStatus.expired.wire,
          'vaccinatedUntil': Timestamp.fromDate(vaccination.validUntil),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }
}
