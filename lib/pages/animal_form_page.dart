import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/error_mapper.dart';
import '../core/theme/app_spacing.dart';
import '../data/enums/vax_status.dart';
import '../data/models/animal.dart';
import '../data/models/app_user.dart';
import '../data/models/farmer.dart';
import '../state/registry_providers.dart';
import '../state/repository_providers.dart';
import '../ui/atoms/app_spinner.dart';
import '../ui/organisms/animal_form.dart';

class AnimalFormPage extends ConsumerWidget {
  const AnimalFormPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Farmer>> farmersAsync = ref.watch(farmersProvider);
    final List<Farmer> farmers = farmersAsync.value ?? <Farmer>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Register animal')),
      body: farmersAsync.isLoading && farmers.isEmpty
          ? const Center(child: AppSpinner())
          : farmersAsync.hasError && farmers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Text(ErrorMapper.firestore(farmersAsync.error!).message),
                  ),
                )
              : AnimalForm(
                  farmers: farmers,
                  onSubmit: ({
                    required String tagNo,
                    required String species,
                    required String breed,
                    required Farmer farmer,
                  }) async {
                    final Animal animal = Animal(
                      id: const Uuid().v4(),
                      tagNo: tagNo,
                      species: species,
                      breed: breed,
                      farmerId: farmer.id,
                      farmerName: farmer.fullName,
                      barangay: farmer.barangay,
                      areaId: farmer.areaId,
                      vaxStatus: VaxStatus.none,
                      registeredBy: user.id,
                      registeredAt: DateTime.now(),
                    );
                    await ref.read(registryRepositoryProvider).addAnimal(animal);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
    );
  }
}
