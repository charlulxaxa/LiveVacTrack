import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/vaccination.dart';
import 'repository_providers.dart';

final vaccinationsProvider =
    StreamProvider.family<List<Vaccination>, String>((Ref ref, String animalId) {
  return ref.watch(vaccinationRepositoryProvider).watchForAnimal(animalId);
});
