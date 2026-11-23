import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/animal.dart';
import '../data/models/app_user.dart';
import '../data/models/farmer.dart';
import '../state/app_providers.dart';
import '../state/registry_providers.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/animal_registry_view.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/farmer_registry_view.dart';
import '../ui/organisms/profile_view.dart';
import 'animal_detail_page.dart';
import 'animal_form_page.dart';
import 'farmer_form_page.dart';
import 'page_helpers.dart';

class RegistryShellPage extends ConsumerWidget {
  const RegistryShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Farmer>> farmersAsync = ref.watch(farmersProvider);
    final AsyncValue<List<Animal>> animalsAsync = ref.watch(animalsProvider);
    final List<Farmer> farmers = farmersAsync.value ?? <Farmer>[];
    final List<Animal> animals = animalsAsync.value ?? <Animal>[];
    final int farmerLimit = ref.watch(farmerLimitProvider);
    final int animalLimit = ref.watch(animalLimitProvider);

    return AppShell(
      title: 'Registry office',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Farmers',
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          child: FarmerRegistryView(
            farmers: farmers,
            loading: farmersAsync.isLoading,
            error: errorTextFor(farmersAsync),
            limit: farmerLimit,
            onLoadMore: () => ref.read(farmerLimitProvider.notifier).loadMore(),
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FarmerFormPage(user: user),
              ),
            ),
            onTap: (Farmer farmer) => showFarmerSheet(
              context,
              farmer: farmer,
              animals: animals,
            ),
            onRefresh: () async {
              ref.invalidate(farmersProvider);
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
          ),
        ),
        ShellTab(
          label: 'Animals',
          icon: Icons.pets_outlined,
          selectedIcon: Icons.pets_rounded,
          child: AnimalRegistryView(
            animals: animals,
            loading: animalsAsync.isLoading,
            error: errorTextFor(animalsAsync),
            limit: animalLimit,
            onLoadMore: () => ref.read(animalLimitProvider.notifier).loadMore(),
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnimalFormPage(user: user),
              ),
            ),
            onTap: (Animal animal) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnimalDetailPage(animalId: animal.id),
              ),
            ),
            onRefresh: () async {
              ref.invalidate(animalsProvider);
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
          ),
        ),
        ShellTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          child: ProfileView(
            user: user,
            demoMode: AppConfig.demoMode,
            offlineSimulated: ref.watch(offlineSimulatorProvider),
            onOfflineChanged: (bool value) =>
                ref.read(offlineSimulatorProvider.notifier).setValue(value),
            onSignOut: () => ref.read(authServiceProvider).signOut(),
          ),
        ),
      ],
    );
  }
}
