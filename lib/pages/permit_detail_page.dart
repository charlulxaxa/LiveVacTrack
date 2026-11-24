import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/error_mapper.dart';
import '../core/theme/app_spacing.dart';
import '../data/models/animal.dart';
import '../data/models/permit.dart';
import '../state/permit_providers.dart';
import '../state/registry_providers.dart';
import '../ui/atoms/app_spinner.dart';
import '../ui/atoms/app_text.dart';
import '../ui/organisms/permit_detail_view.dart';
import '../ui/templates/detail_template.dart';

class PermitDetailPage extends ConsumerWidget {
  const PermitDetailPage({required this.permitId, super.key});

  final String permitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Permit?> permitAsync = ref.watch(permitProvider(permitId));
    final List<Animal> animals = ref.watch(animalsProvider).value ?? <Animal>[];

    final Permit? permit = permitAsync.value;
    if (permit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permit')),
        body: permitAsync.hasError
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: AppText(ErrorMapper.firestore(permitAsync.error!).message),
                ),
              )
            : const Center(child: AppSpinner()),
      );
    }

    Animal? animal;
    for (final Animal row in animals) {
      if (row.id == permit.animalId) {
        animal = row;
        break;
      }
    }

    return DetailTemplate(
      title: permit.id,
      subtitle: 'Signed movement permit',
      child: PermitDetailView(permit: permit, animal: animal),
    );
  }
}
