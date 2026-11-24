import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
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

  @override
  Future<void> record(Vaccination vaccination) async {
    try {
      await _firestore
          .collection(FirestorePaths.vaccinations)
          .doc(vaccination.id)
          .set(vaccination.toMap());
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }
}
