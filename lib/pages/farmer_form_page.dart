import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/app_user.dart';
import '../data/models/farmer.dart';
import '../state/repository_providers.dart';
import '../ui/organisms/farmer_form.dart';

class FarmerFormPage extends ConsumerWidget {
  const FarmerFormPage({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register farmer')),
      body: FarmerForm(
        onSubmit: ({
          required String fullName,
          required String barangay,
          required String areaId,
          String? contactNo,
        }) async {
          final Farmer farmer = Farmer(
            id: const Uuid().v4(),
            fullName: fullName,
            barangay: barangay,
            areaId: areaId,
            contactNo: contactNo,
            registeredBy: user.id,
            createdAt: DateTime.now(),
          );
          await ref.read(registryRepositoryProvider).addFarmer(farmer);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}
