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
        },
      ),
    );
  }
}
