import '../demo/demo_store.dart';
import '../models/vaccination.dart';

abstract class VaccinationRepository {
  Stream<List<Vaccination>> watchForAnimal(String animalId);

  Future<void> record(Vaccination vaccination);
}

class DemoVaccinationRepository implements VaccinationRepository {
  DemoVaccinationRepository(this._store);

  final DemoStore _store;

  @override
  Stream<List<Vaccination>> watchForAnimal(String animalId) =>
      _store.watchVaccinations(animalId);

  @override
  Future<void> record(Vaccination vaccination) async {
    _store.addVaccination(vaccination);
  }
}
