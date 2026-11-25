import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quarantine.dart';
import 'repository_providers.dart';
import '../core/utils/quarantine_scope.dart';

final StreamProvider<List<Quarantine>> quarantinesProvider =
    StreamProvider<List<Quarantine>>((Ref ref) {
  return ref.watch(quarantineRepositoryProvider).watchQuarantines();
});

/// Municipality keys ([QuarantineScope.municipalityOf]) under an active
/// quarantine. A quarantine covers its barangay's whole municipality, so
/// check an animal with `isAreaQuarantined(set, animal.areaId)`.
final Provider<Set<String>> activeQuarantineAreasProvider =
    Provider<Set<String>>((Ref ref) {
  final List<Quarantine> rows =
      ref.watch(quarantinesProvider).value ?? <Quarantine>[];
  return rows
      .where((Quarantine q) => q.isActive)
      .map((Quarantine q) => QuarantineScope.municipalityOf(q.areaId))
      .toSet();
});

/// Whether [areaId] (a barangay) is inside a quarantined municipality.
bool isAreaQuarantined(Set<String> quarantinedMunicipalities, String areaId) =>
    quarantinedMunicipalities.contains(QuarantineScope.municipalityOf(areaId));

final Provider<List<Quarantine>> activeQuarantinesProvider =
    Provider<List<Quarantine>>((Ref ref) {
  final List<Quarantine> rows =
      ref.watch(quarantinesProvider).value ?? <Quarantine>[];
  return rows.where((Quarantine q) => q.isActive).toList();
});
