import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/error_mapper.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../data/enums/user_role.dart';
import '../data/models/app_user.dart';
import '../state/repository_providers.dart';
import '../state/session_providers.dart';
import '../ui/atoms/app_button.dart';
import '../ui/atoms/app_logo.dart';
import '../ui/atoms/app_spinner.dart';
import '../ui/atoms/app_text.dart';
import 'admin_shell_page.dart';
import 'clerk_shell_page.dart';
import 'disease_shell_page.dart';
import 'inspector_shell_page.dart';
import 'login_page.dart';
import 'registry_shell_page.dart';
import 'vet_shell_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser?> auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _Splash(),
      error: (Object error, StackTrace stack) => _AuthError(
        message: ErrorMapper.auth(error).message,
        onRetry: () => ref.invalidate(authStateProvider),
        onSignOut: () async {
          await ref.read(authServiceProvider).signOut();
          ref.invalidate(authStateProvider);
        },
      ),
      data: (AppUser? user) {
        if (user == null) return const LoginPage();
        return _RoleHome(user: user);
      },
    );
  }
}

class _RoleHome extends StatelessWidget {
  const _RoleHome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return AdminShellPage(user: user);
      case UserRole.registry:
        return RegistryShellPage(user: user);
      case UserRole.vet:
        return VetShellPage(user: user);
      case UserRole.clerk:
        return ClerkShellPage(user: user);
      case UserRole.inspector:
        return InspectorShellPage(user: user);
      case UserRole.diseaseControl:
        return DiseaseShellPage(user: user);
      case UserRole.unknown:
        return const _NoAccess();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppLogo(),
            SizedBox(height: AppSpacing.xl),
            AppSpinner(),
          ],
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded,
                  size: 42, color: AppColors.warning),
              const SizedBox(height: AppSpacing.lg),
              AppText(
                'Could not reach the sign-in service',
                variant: AppTextVariant.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                message,
                variant: AppTextVariant.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Try again',
                onPressed: onRetry,
                expand: false,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Sign out',
                onPressed: onSignOut,
                variant: AppButtonVariant.secondary,
                expand: false,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccess extends ConsumerWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppLogo(),
              const SizedBox(height: AppSpacing.xl),
              AppText(
                'No role assigned',
                variant: AppTextVariant.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Ask the vet office admin to set a role claim for this account.',
                variant: AppTextVariant.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sign out',
                onPressed: () => ref.read(authServiceProvider).signOut(),
                variant: AppButtonVariant.secondary,
                expand: false,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
