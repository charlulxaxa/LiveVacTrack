import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/quarantine.dart';
import '../../state/app_providers.dart';
import '../../state/quarantine_providers.dart';
import '../../state/repository_providers.dart';
import '../organisms/app_shell.dart';
import '../organisms/declare_quarantine_form.dart';
import '../organisms/profile_view.dart';
import '../organisms/quarantine_list_view.dart';
import 'page_helpers.dart';
import 'change_password_page.dart';

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
    final quarantineRepository = ref.read(quarantineRepositoryProvider);

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
            onActivate: (Quarantine quarantine) async {
              final bool confirmed = await _showConfirmDialog(
                context,
                title: 'Activate quarantine?',
                message: 'This will revoke all issued permits in ${quarantine.areaName} and block new permits.',
                confirmLabel: 'Activate',
                destructive: true,
              );
              if (!confirmed) return;
              try {
                await quarantineRepository.activateQuarantine(
                  quarantineId: quarantine.id,
                  officer: user,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quarantine activated for ${quarantine.areaName}.'),
                    ),
                  );
                }
                ref.invalidate(quarantinesProvider);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }
            },
            onLift: (Quarantine quarantine) async {
              final bool confirmed = await _showConfirmDialog(
                context,
                title: 'Lift quarantine?',
                message: 'This will lift the quarantine for ${quarantine.areaName}. New permits will be allowed again.',
                confirmLabel: 'Lift',
                destructive: false,
              );
              if (!confirmed) return;
              try {
                await quarantineRepository.liftQuarantine(
                  quarantineId: quarantine.id,
                  officer: user,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quarantine lifted for ${quarantine.areaName}.'),
                    ),
                  );
                }
                ref.invalidate(quarantinesProvider);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }
            },
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
            quarantines: quarantines,
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
            onActivate: (Quarantine quarantine) async {
              final bool confirmed = await _showConfirmDialog(
                context,
                title: 'Activate quarantine?',
                message: 'This will revoke all issued permits in ${quarantine.areaName} and block new permits.',
                confirmLabel: 'Activate',
                destructive: true,
              );
              if (!confirmed) return;
              try {
                await quarantineRepository.activateQuarantine(
                  quarantineId: quarantine.id,
                  officer: user,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quarantine activated for ${quarantine.areaName}.'),
                    ),
                  );
                }
                ref.invalidate(quarantinesProvider);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              }
            },
            onLift: (Quarantine quarantine) async {
              final bool confirmed = await _showConfirmDialog(
                context,
                title: 'Lift quarantine?',
                message: 'This will lift the quarantine for ${quarantine.areaName}. New permits will be allowed again.',
                confirmLabel: 'Lift',
                destructive: false,
              );
              if (!confirmed) return;
              try {
                await quarantineRepository.liftQuarantine(
                  quarantineId: quarantine.id,
                  officer: user,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quarantine lifted for ${quarantine.areaName}.'),
                    ),
                  );
                }
                ref.invalidate(quarantinesProvider);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
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

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: destructive
                    ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
                    : null,
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}
