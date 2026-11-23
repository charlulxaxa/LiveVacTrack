import 'package:flutter/material.dart';

import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/error_banner.dart';
import '../molecules/location_picker.dart';
import '../templates/form_template.dart';

class FarmerForm extends StatefulWidget {
  const FarmerForm({
    required this.onSubmit,
    super.key,
  });

  final Future<void> Function({
    required String fullName,
    required String barangay,
    required String areaId,
    String? contactNo,
  }) onSubmit;

  @override
  State<FarmerForm> createState() => _FarmerFormState();
}

class _FarmerFormState extends State<FarmerForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _barangay = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  String? _areaId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _barangay.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_areaId == null) {
      setState(() => _error = 'Select the farmer’s area.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        fullName: _name.text.trim(),
        barangay: _barangay.text.trim(),
        areaId: _areaId!,
        contactNo: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Register a farmer',
        subtitle: 'Only the details needed for permit records are stored.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            controller: _name,
            label: 'Full name',
            hint: 'e.g. Maria Santos',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Full name is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          LocationPicker(
            label: 'Area',
            onChanged: (AreaSelection? selection) {
              setState(() {
                _areaId = selection?.id;
                if (selection != null && _barangay.text.trim().isEmpty) {
                  _barangay.text = selection.name;
                }
              });
            },
            validator: (AreaSelection? value) =>
                value == null ? 'Select an area' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _barangay,
            label: 'Barangay',
            hint: 'e.g. Poblacion',
            prefixIcon: Icons.location_on_outlined,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Barangay is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _contact,
            label: 'Contact number (optional)',
            hint: 'e.g. 0917 000 0000',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'Farmer records contain synthetic data only in this build.',
            variant: AppTextVariant.caption,
          ),
        ],
        footer: AppButton(
          label: 'Register farmer',
          onPressed: _submit,
          loading: _submitting,
          icon: Icons.save_rounded,
        ),
      ),
    );
  }
}
