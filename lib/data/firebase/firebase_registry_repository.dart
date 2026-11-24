import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/errors/error_mapper.dart';
import '../models/animal.dart';
import '../models/farmer.dart';
import '../repositories/registry_repository.dart';

class FirebaseRegistryRepository implements RegistryRepository {
  FirebaseRegistryRepository(this._firestore, this._paths);

  final FirebaseFirestore _firestore;
  final FirestorePaths _paths;

  @override
  Stream<List<Farmer>> watchFarmers({int limit = AppConfig.pageSize}) {
    return _firestore
        .collection(_paths.farmers)
        .orderBy('fullName')
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Farmer.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<List<Animal>> watchAnimals({int limit = AppConfig.pageSize}) {
    return _firestore
        .collection(_paths.animals)
        .orderBy('tagNo')
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                Animal.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<Animal?> watchAnimal(String id) {
    return _firestore
        .collection(_paths.animals)
        .doc(id)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
            doc.exists ? Animal.fromMap(doc.id, doc.data()!) : null);
  }

  @override
  Future<void> addFarmer(Farmer farmer) async {
    try {
      await _firestore
          .collection(_paths.farmers)
          .doc(farmer.id)
          .set(farmer.toMap());
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }

  @override
  Future<void> addAnimal(Animal animal) async {
    try {
      await _firestore
          .collection(_paths.animals)
          .doc(animal.id)
          .set(animal.toMap());
    } catch (error) {
      throw ErrorMapper.firestore(error);
    }
  }
}
