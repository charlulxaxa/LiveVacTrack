import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/animal.dart';
import '../data/models/farmer.dart';
import 'repository_providers.dart';

class FarmerLimit extends Notifier<int> {
  @override
  int build() => AppConfig.pageSize;

  void loadMore() => state += AppConfig.pageSize;

  void reset() => state = AppConfig.pageSize;
}

final NotifierProvider<FarmerLimit, int> farmerLimitProvider =
    NotifierProvider<FarmerLimit, int>(FarmerLimit.new);

class AnimalLimit extends Notifier<int> {
  @override
  int build() => AppConfig.pageSize;

  void loadMore() => state += AppConfig.pageSize;

  void reset() => state = AppConfig.pageSize;
}

final NotifierProvider<AnimalLimit, int> animalLimitProvider =
    NotifierProvider<AnimalLimit, int>(AnimalLimit.new);

final StreamProvider<List<Farmer>> farmersProvider =
    StreamProvider<List<Farmer>>((Ref ref) {
  final int limit = ref.watch(farmerLimitProvider);
  return ref.watch(registryRepositoryProvider).watchFarmers(limit: limit);
});

final StreamProvider<List<Animal>> animalsProvider =
    StreamProvider<List<Animal>>((Ref ref) {
  final int limit = ref.watch(animalLimitProvider);
  return ref.watch(registryRepositoryProvider).watchAnimals(limit: limit);
});

final animalProvider =
    StreamProvider.family<Animal?, String>((Ref ref, String id) {
  return ref.watch(registryRepositoryProvider).watchAnimal(id);
});
