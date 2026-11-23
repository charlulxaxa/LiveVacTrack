import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/app_user.dart';
import '../data/models/quarantine.dart';
import '../state/app_providers.dart';
import '../state/quarantine_providers.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/declare_quarantine_form.dart';
import '../ui/organisms/profile_view.dart';
import '../ui/organisms/quarantine_list_view.dart';
import 'page_helpers.dart';

class DiseaseShellPage extends ConsumerWidget {
  const DiseaseShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Quarantine>> quarantinesAsync =
        ref.watch(quarantinesProvider);
    final List<Quarantine> quarantines =
        quarantinesAsync.value ?? <Quarantine>[];
    final Set<String> activeAreas = ref.watch(activeQuarantineAreasProvider);

    return AppShell(
      title: 'Disease control',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Quarantines',
          icon: Icons.health_and_safety_outlined,
          selectedIcon: Icons.health_and_safety_rounded,
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
          label: 'Declare',
          icon: Icons.add_alert_outlined,
          selectedIcon: Icons.add_alert_rounded,
          child: DeclareQuarantineForm(
            activeAreas: activeAreas,
            onDeclare: ({
              required String areaId,
              required String areaName,
              required String reason,
            }) async {
              final int revoked = await ref
                  .read(quarantineRepositoryProvider)
                  .declareQuarantine(
                    areaId: areaId,
                    areaName: areaName,
                    reason: reason,
                    officer: user,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Quarantine declared for $areaName. $revoked permit(s) revoked.',
                    ),
                  ),
                );
              }
              return revoked;
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
