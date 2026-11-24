import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/errors/error_mapper.dart';
import '../data/services/auth_service.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/login_form.dart';
import '../ui/templates/auth_template.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthService auth = ref.watch(authServiceProvider);
    return AuthTemplate(
      child: LoginForm(
        demoPassword: AppConfig.demoPassword,
        // Shown in live mode too: scripts/seed-demo-accounts.js creates these
        // same accounts in Firebase. Accounts added by the super admin are
        // never listed here.
        demoCredentials: DemoAuthService.demoAccounts
            .map((DemoAccount account) => LoginDemoCredential(
                  email: account.email,
                  roleLabel: account.user.role.shortLabel,
                  name: account.user.displayName,
                ))
            .toList(),
        onSubmit: (String email, String password) async {
          try {
            await auth.signIn(email: email, password: password);
          } catch (error, stack) {
            debugPrint('Sign in failed: $error');
            debugPrintStack(stackTrace: stack, maxFrames: 8);
            throw ErrorMapper.auth(error);
          }
        },
      ),
    );
  }
}
