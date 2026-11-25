import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../data/models/animal.dart';
import '../../data/models/farmer.dart';
import '../atoms/app_text.dart';
import '../molecules/info_row.dart';
import '../molecules/section_header.dart';

String? errorTextFor(AsyncValue<dynamic> value) {
  if (!value.hasError) return null;
  return ErrorMapper.firestore(value.error!).message;
}

void showFarmerSheet(
  BuildContext context, {
  required Farmer farmer,
  required List<Animal> animals,
}) {
  final List<Animal> owned =
      animals.where((Animal animal) => animal.farmerId == farmer.id).toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionHeader(
                title: farmer.fullName,
                subtitle: '${farmer.barangay} · ${farmer.contactNo ?? 'No contact'}',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: <Widget>[
                      InfoRow(label: 'Area ID', value: farmer.areaId),
                      const Divider(height: 1),
                      InfoRow(
                        label: 'Animals',
                        value: '${owned.length} registered',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppText(
                owned.isEmpty
                    ? 'No animals registered under this farmer yet.'
                    : owned.map((Animal a) => a.tagNo).join(', '),
                variant: AppTextVariant.body,
              ),
            ],
          ),
        ),
      );
    },
  );
}
