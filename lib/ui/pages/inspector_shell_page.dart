import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user.dart';
import '../../data/models/permit.dart';
import '../../data/models/quarantine.dart';
import '../../data/models/verification.dart';
import '../../state/app_providers.dart';
import '../../state/permit_providers.dart';
import '../../state/quarantine_providers.dart';
import '../../state/repository_providers.dart';
import '../organisms/app_shell.dart';
import '../organisms/permit_verifier_view.dart';
import '../organisms/profile_view.dart';
import '../organisms/quarantine_list_view.dart';
import '../organisms/verification_history_view.dart';
import 'page_helpers.dart';
import 'permit_verify_page.dart';
import 'change_password_page.dart';

class InspectorShellPage extends ConsumerWidget {
  const InspectorShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Permit>> permitsAsync = ref.watch(permitsProvider);
    final AsyncValue<List<Verification>> historyAsync = ref.watch(
      verificationsProvider(user.id),
    );
    final AsyncValue<List<Quarantine>> quarantinesAsync = ref.watch(
      quarantinesProvider,
    );
    final List<Permit> permits = permitsAsync.value ?? <Permit>[];
    final List<Verification> history = historyAsync.value ?? <Verification>[];
    final List<Quarantine> quarantines =
        quarantinesAsync.value ?? <Quarantine>[];
    final bool offline = ref.watch(isOfflineProvider);
    final DateTime? lastSynced = ref.watch(lastSyncedProvider);

    return AppShell(
      title: 'Checkpoint',
      offline: offline,
      tabs: <ShellTab>[
        ShellTab(
          label: 'Verify',
          icon: Icons.qr_code_scanner_rounded,
          selectedIcon: Icons.qr_code_scanner_rounded,
          child: PermitVerifierView(
            offline: offline,
            lastSynced: lastSynced,
            demoPermits: permits,
            onOpenVerification:
                ({
                  required String permitId,
                  required String signedCode,
                  required String checkpointName,
                }) {
                  return Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PermitVerifyPage(
                        permitId: permitId,
                        signedCode: signedCode,
                        checkpointName: checkpointName,
                        onVerify:
                            ({
                              required String permitId,
                              required String signedCode,
                              required String checkpointName,
                            }) async {
                              final VerificationOutcome outcome = await ref
                                  .read(permitRepositoryProvider)
                                  .verifyPermit(
                                    permitId: permitId,
                                    signedCode: signedCode,
                                    checkpointName: checkpointName,
                                    inspector: user,
                                    // Read at verify time, not when the scan screen
                                    // was last built.
                                    offline: ref.read(isOfflineProvider),
                                  );
                              if (!outcome.offline) {
                                ref.read(lastSyncedProvider.notifier).markNow();
                              }
                              return outcome;
                            },
                      ),
                    ),
                  );
                },
          ),
        ),
        ShellTab(
          label: 'History',
          icon: Icons.history_rounded,
          selectedIcon: Icons.history_rounded,
          child: VerificationHistoryView(
            verifications: history,
            loading: historyAsync.isLoading,
            error: errorTextFor(historyAsync),
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
