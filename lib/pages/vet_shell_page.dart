import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/animal.dart';
import '../data/models/app_user.dart';
import '../data/models/vaccination.dart';
import '../state/app_providers.dart';
import '../state/registry_providers.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/animal_registry_view.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/profile_view.dart';
import '../ui/organisms/vaccination_form.dart';
import 'animal_detail_page.dart';
import 'page_helpers.dart';
import 'change_password_page.dart';

class VetShellPage extends ConsumerWidget {
  const VetShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Animal>> animalsAsync = ref.watch(animalsProvider);
    final List<Animal> animals = animalsAsync.value ?? <Animal>[];
    final int limit = ref.watch(animalLimitProvider);

    return AppShell(
      title: 'Veterinary office',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Animals',
          icon: Icons.pets_outlined,
          selectedIcon: Icons.pets_rounded,
          child: AnimalRegistryView(
            animals: animals,
            loading: animalsAsync.isLoading,
            error: errorTextFor(animalsAsync),
            limit: limit,
            onLoadMore: () => ref.read(animalLimitProvider.notifier).loadMore(),
            onTap: (Animal animal) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AnimalDetailPage(animalId: animal.id),
              ),
            ),
            subtitle: 'Read-only registry. Record a shot from the Vaccinate tab.',
            onRefresh: () async {
              ref.invalidate(animalsProvider);
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
          ),
        ),
        ShellTab(
          label: 'Vaccinate',
          icon: Icons.vaccines_outlined,
          selectedIcon: Icons.vaccines_rounded,
          child: VaccinationForm(
            animals: animals,
            onSubmit: ({
              required Animal animal,
              required String vaccineName,
              required String batchNo,
              required DateTime dateGiven,
              required DateTime validUntil,
            }) async {
              final Vaccination vaccination = Vaccination(
                id: const Uuid().v4(),
                animalId: animal.id,
                vaccineName: vaccineName,
                batchNo: batchNo,
                dateGiven: dateGiven,
                validUntil: validUntil,
                vetUid: user.id,
                vetName: user.displayName,
                createdAt: DateTime.now(),
              );
              await ref
                  .read(vaccinationRepositoryProvider)
                  .record(vaccination);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Vaccination saved for ${animal.tagNo}.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
        ShellTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          child: ProfileView(
            user: user,
            demoMode: user.isDemo,
            offlineSimulated: ref.watch(offlineSimulatorProvider),
            onOfflineChanged: (bool value) =>
                ref.read(offlineSimulatorProvider.notifier).setValue(value),
            onSignOut: () => ref.read(authServiceProvider).signOut(),
            onChangePassword: () => ChangePasswordPage.open(context),
          ),
        ),
      ],
    );
  }
}
