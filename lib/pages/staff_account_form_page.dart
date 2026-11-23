import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/repository_providers.dart';
import '../ui/organisms/staff_account_form.dart';

class StaffAccountFormPage extends ConsumerWidget {
  const StaffAccountFormPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create staff account')),
      body: StaffAccountForm(
        onSubmit: ({
          required String email,
          required String password,
          required String displayName,
          required String role,
          required String areaId,
          required String areaName,
        }) async {
          await ref.read(staffAccountServiceProvider).createStaffAccount(
                email: email,
                password: password,
                displayName: displayName,
                role: role,
                areaId: areaId,
                areaName: areaName,
              );
          if (!context.mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
              title: const Text('Account created'),
              content: Text('The account for $displayName was successfully created.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
