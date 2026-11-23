import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quarantine.dart';
import 'repository_providers.dart';

final StreamProvider<List<Quarantine>> quarantinesProvider =
    StreamProvider<List<Quarantine>>((Ref ref) {
  return ref.watch(quarantineRepositoryProvider).watchQuarantines();
});

final Provider<Set<String>> activeQuarantineAreasProvider =
    Provider<Set<String>>((Ref ref) {
  final List<Quarantine> rows =
      ref.watch(quarantinesProvider).value ?? <Quarantine>[];
  return rows
      .where((Quarantine q) => q.isActive)
      .map((Quarantine q) => q.areaId)
      .toSet();
});

final Provider<List<Quarantine>> activeQuarantinesProvider =
    Provider<List<Quarantine>>((Ref ref) {
  final List<Quarantine> rows =
      ref.watch(quarantinesProvider).value ?? <Quarantine>[];
  return rows.where((Quarantine q) => q.isActive).toList();
});
