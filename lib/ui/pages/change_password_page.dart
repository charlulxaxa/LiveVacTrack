import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/repository_providers.dart';
import '../organisms/change_password_form.dart';

class ChangePasswordPage extends ConsumerWidget {
  const ChangePasswordPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: ChangePasswordForm(
        onSubmit: ({
          required String currentPassword,
          required String newPassword,
        }) async {
          await ref.read(authServiceProvider).changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
              );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your password has been changed.')),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
