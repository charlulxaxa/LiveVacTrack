import '../../core/config/app_config.dart';
import '../demo/demo_store.dart';
import '../models/animal.dart';
import '../models/farmer.dart';

abstract class RegistryRepository {
  Stream<List<Farmer>> watchFarmers({int limit = AppConfig.pageSize});

  Stream<List<Animal>> watchAnimals({int limit = AppConfig.pageSize});

  Stream<Animal?> watchAnimal(String id);

  Future<void> addFarmer(Farmer farmer);

  Future<void> addAnimal(Animal animal);
}

class DemoRegistryRepository implements RegistryRepository {
  DemoRegistryRepository(this._store);

  final DemoStore _store;

  @override
  Stream<List<Farmer>> watchFarmers({int limit = AppConfig.pageSize}) =>
      _store.watchFarmers(limit: limit);

  @override
  Stream<List<Animal>> watchAnimals({int limit = AppConfig.pageSize}) =>
      _store.watchAnimals(limit: limit);

  @override
  Stream<Animal?> watchAnimal(String id) => _store.watchAnimal(id);

  @override
  Future<void> addFarmer(Farmer farmer) async {
    _store.addFarmer(farmer);
  }

  @override
  Future<void> addAnimal(Animal animal) async {
    _store.addAnimal(animal);
  }
}
