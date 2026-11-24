import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/farmer.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/dropdown_field.dart';
import '../molecules/error_banner.dart';
import '../templates/form_template.dart';

class AnimalForm extends StatefulWidget {
  const AnimalForm({
    required this.farmers,
    required this.onSubmit,
    super.key,
  });

  final List<Farmer> farmers;
  final Future<void> Function({
    required String tagNo,
    required String species,
    required String breed,
    required Farmer farmer,
  }) onSubmit;

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> {
  static const List<String> _speciesOptions = <String>[
    'Cattle',
    'Carabao',
    'Goat',
    'Swine',
    'Poultry',
    'Duck',
    'Other',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _tagNo = TextEditingController();
  final TextEditingController _breed = TextEditingController();
  String? _species;
  String? _farmerId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _tagNo.dispose();
    _breed.dispose();
    super.dispose();
  }

  Farmer? get _selectedFarmer {
    for (final Farmer farmer in widget.farmers) {
      if (farmer.id == _farmerId) return farmer;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Farmer? farmer = _selectedFarmer;
    if (farmer == null) {
      setState(() => _error = 'Select the animal’s owner.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        tagNo: _tagNo.text.trim().toUpperCase(),
        species: _species ?? '',
        breed: _breed.text.trim(),
        farmer: farmer,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Farmer? farmer = _selectedFarmer;
    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Register an animal',
        subtitle: 'The owner must be registered before an animal can be tagged.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.farmers.isEmpty)
            const ErrorBanner(
              message: 'Register a farmer first, then come back to add animals.',
            ),
          if (widget.farmers.isEmpty) const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _tagNo,
            label: 'Tag number',
            hint: 'e.g. LV-011',
            prefixIcon: Icons.tag_rounded,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Tag number is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownField<String>(
            label: 'Species',
            value: _species,
            hint: 'Select a species',
            items: _speciesOptions
                .map((String value) =>
                    DropdownOption<String>(value: value, label: value))
                .toList(),
            onChanged: (String? value) => setState(() => _species = value),
            validator: (String? value) =>
                value == null ? 'Select a species' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _breed,
            label: 'Breed',
            hint: 'e.g. Brahman',
            prefixIcon: Icons.category_outlined,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Breed is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownField<String>(
            label: 'Owner',
            value: _farmerId,
            hint: 'Select a registered farmer',
            enabled: widget.farmers.isNotEmpty,
            items: widget.farmers
                .map((Farmer farmer) => DropdownOption<String>(
                      value: farmer.id,
                      label: farmer.fullName,
                      subtitle: farmer.barangay.isEmpty
                          ? 'No barangay recorded'
                          : farmer.barangay,
                    ))
                .toList(),
            onChanged: (String? value) => setState(() => _farmerId = value),
            validator: (String? value) =>
                value == null ? 'Select the owner' : null,
          ),
          if (farmer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      'Area is inherited from the farmer’s barangay record.',
                      variant: AppTextVariant.caption,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        footer: AppButton(
          label: 'Register animal',
          onPressed: widget.farmers.isEmpty ? null : _submit,
          loading: _submitting,
          icon: Icons.save_rounded,
        ),
      ),
    );
  }
}
