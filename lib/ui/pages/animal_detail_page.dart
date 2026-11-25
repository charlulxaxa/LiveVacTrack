import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/animal.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/verification.dart';
import '../../state/permit_providers.dart';
import '../../state/quarantine_providers.dart';
import '../../state/registry_providers.dart';
import '../../state/vaccination_providers.dart';
import '../atoms/app_spinner.dart';
import '../atoms/app_text.dart';
import '../organisms/animal_detail_view.dart';
import '../templates/detail_template.dart';

class AnimalDetailPage extends ConsumerWidget {
  const AnimalDetailPage({required this.animalId, super.key});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Animal?> animalAsync = ref.watch(animalProvider(animalId));
    final AsyncValue<List<Vaccination>> vaccinationsAsync =
        ref.watch(vaccinationsProvider(animalId));
    final AsyncValue<List<Verification>> verificationsAsync =
        ref.watch(animalVerificationsProvider(animalId));
    final Set<String> quarantinedAreas =
        ref.watch(activeQuarantineAreasProvider);

    final Animal? animal = animalAsync.value;
    if (animal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Animal')),
        body: animalAsync.hasError
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: AppText(ErrorMapper.firestore(animalAsync.error!).message),
                ),
              )
            : const Center(child: AppSpinner()),
      );
    }

    return DetailTemplate(
      title: animal.tagNo,
      subtitle: '${animal.species} · ${animal.breed}',
      child: AnimalDetailView(
        animal: animal,
        vaccinations: vaccinationsAsync.value ?? <Vaccination>[],
        loadingVaccinations: vaccinationsAsync.isLoading,
        areaQuarantined: isAreaQuarantined(quarantinedAreas, animal.areaId),
        verifications: verificationsAsync.value ?? <Verification>[],
        loadingVerifications: verificationsAsync.isLoading,
      ),
    );
  }
}
