import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/app_user.dart';
import '../data/models/staff_member.dart';
import '../state/app_providers.dart';
import '../state/repository_providers.dart';
import '../state/staff_providers.dart';
import '../ui/molecules/confirm_dialog.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/profile_view.dart';
import '../ui/organisms/staff_account_view.dart';
import 'page_helpers.dart';
import 'staff_account_form_page.dart';

class AdminShellPage extends ConsumerStatefulWidget {
  const AdminShellPage({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  final Set<String> _busyIds = <String>{};

  Future<void> _handleAction(StaffMember member, StaffAction action) async {
    final String name = member.displayName;
    final bool confirmed;
    switch (action) {
      case StaffAction.resetPassword:
        confirmed = await ConfirmDialog.show(
          context,
          title: 'Reset password?',
          message: AppConfig.demoMode
              ? '$name\'s password will be set back to the demo password.'
              : 'A password reset email will be sent to '
                  '${member.email ?? 'this account'}. $name chooses a new '
                  'password from the link in that email.',
          confirmLabel: 'Send reset',
        );
      case StaffAction.deactivate:
        confirmed = await ConfirmDialog.show(
          context,
          title: 'Deactivate account?',
          message: '$name will not be able to sign in until you reactivate '
              'the account.',
          confirmLabel: 'Deactivate',
          destructive: true,
        );
      case StaffAction.reactivate:
        confirmed = true;
      case StaffAction.remove:
        confirmed = await ConfirmDialog.show(
          context,
          title: 'Remove account?',
          message: '$name will lose access permanently and the account will '
              'disappear from this list. This cannot be undone in the app.',
          confirmLabel: 'Remove',
          destructive: true,
        );
    }
    if (!confirmed || !mounted) return;

    setState(() => _busyIds.add(member.id));
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final service = ref.read(staffAccountServiceProvider);
      final String message;
      switch (action) {
        case StaffAction.resetPassword:
          message = await service.resetPassword(member);
        case StaffAction.deactivate:
          await service.setDisabled(member, disabled: true);
          message = '$name has been deactivated.';
        case StaffAction.reactivate:
          await service.setDisabled(member, disabled: false);
          message = '$name can sign in again.';
        case StaffAction.remove:
          await service.removeStaff(member);
          message = '$name has been removed.';
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busyIds.remove(member.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<StaffMember>> staffAsync =
        ref.watch(staffMembersProvider);

    return AppShell(
      title: 'Super admin',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Staff',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge_rounded,
          child: StaffAccountView(
            staff: staffAsync.value ?? <StaffMember>[],
            loading: staffAsync.isLoading,
            error: errorTextFor(staffAsync),
            onRetry: () => ref.invalidate(staffMembersProvider),
            busyIds: _busyIds,
            onAction: _handleAction,
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StaffAccountFormPage(),
              ),
            ),
          ),
        ),
        ShellTab(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          child: ProfileView(
            user: widget.user,
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
