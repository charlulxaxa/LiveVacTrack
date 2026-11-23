import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../data/models/app_user.dart';
import '../state/app_providers.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/app_shell.dart';
import '../ui/organisms/profile_view.dart';
import '../ui/organisms/staff_account_view.dart';
import 'staff_account_form_page.dart';

class AdminShellPage extends ConsumerWidget {
  const AdminShellPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      title: 'Super admin',
      offline: ref.watch(isOfflineProvider),
      tabs: <ShellTab>[
        ShellTab(
          label: 'Staff',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge_rounded,
          child: StaffAccountView(
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
