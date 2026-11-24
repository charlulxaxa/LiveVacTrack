import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/animal.dart';
import '../data/models/app_user.dart';
import '../data/models/permit.dart';
import '../data/models/quarantine.dart';
import '../state/app_providers.dart';
import '../state/permit_providers.dart';
import '../state/quarantine_providers.dart';
import '../state/registry_providers.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/issue_permit_form.dart';
import '../ui/organisms/permit_list_view.dart';
import '../ui/organisms/profile_view.dart';
import '../ui/organisms/quarantine_list_view.dart';
import 'page_helpers.dart';
import 'permit_detail_page.dart';
import 'change_password_page.dart';

class ClerkShellPage extends ConsumerWidget {
  const ClerkShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Permit>> permitsAsync = ref.watch(permitsProvider);
    final AsyncValue<List<Animal>> animalsAsync = ref.watch(animalsProvider);
    final AsyncValue<List<Quarantine>> quarantinesAsync =
        ref.watch(quarantinesProvider);
    final List<Permit> permits = permitsAsync.value ?? <Permit>[];
    final List<Animal> animals = animalsAsync.value ?? <Animal>[];
    final List<Quarantine> quarantines =
        quarantinesAsync.value ?? <Quarantine>[];
    final int limit = ref.watch(permitLimitProvider);
    final Set<String> quarantinedAreas =
        ref.watch(activeQuarantineAreasProvider);

    return AppShell(
      title: 'Permit office',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Permits',
          icon: Icons.description_outlined,
          selectedIcon: Icons.description_rounded,
          child: PermitListView(
            permits: permits,
            animals: animals,
            loading: permitsAsync.isLoading,
            error: errorTextFor(permitsAsync),
            limit: limit,
            onLoadMore: () => ref.read(permitLimitProvider.notifier).loadMore(),
            onTap: (Permit permit) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PermitDetailPage(permitId: permit.id),
              ),
            ),
            onRefresh: () async {
              ref.invalidate(permitsProvider);
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
          ),
        ),
        ShellTab(
          label: 'Issue',
          icon: Icons.add_card_outlined,
          selectedIcon: Icons.add_card_rounded,
          child: IssuePermitForm(
            animals: animals,
            quarantinedAreas: quarantinedAreas,
            assignedAreaId: user.areaId,
            onIssue: ({
              required Animal animal,
              required String origin,
              required String destination,
              required DateTime travelDate,
            }) {
              return ref.read(permitRepositoryProvider).issuePermit(
                    animal: animal,
                    origin: origin,
                    destination: destination,
                    travelDate: travelDate,
                    clerk: user,
                  );
            },
            onViewPermit: (Permit permit) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PermitDetailPage(permitId: permit.id),
              ),
            ),
          ),
        ),
        ShellTab(
          label: 'Alerts',
          icon: Icons.notifications_none_rounded,
          selectedIcon: Icons.notifications_rounded,
          child: QuarantineListView(
            quarantines: quarantines,
            loading: quarantinesAsync.isLoading,
            error: errorTextFor(quarantinesAsync),
            onRefresh: () async {
              ref.invalidate(quarantinesProvider);
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
