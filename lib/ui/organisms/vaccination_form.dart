import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/date_field.dart';
import '../molecules/dropdown_field.dart';
import '../molecules/error_banner.dart';
import '../status_styles.dart';
import '../templates/form_template.dart';

class VaccinationForm extends StatefulWidget {
  const VaccinationForm({
    required this.animals,
    required this.onSubmit,
    super.key,
    this.initialAnimalId,
  });

  final List<Animal> animals;
  final Future<void> Function({
    required Animal animal,
    required String vaccineName,
    required String batchNo,
    required DateTime dateGiven,
    required DateTime validUntil,
  }) onSubmit;
  final String? initialAnimalId;

  @override
  State<VaccinationForm> createState() => _VaccinationFormState();
}

class _VaccinationFormState extends State<VaccinationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _vaccine = TextEditingController();
  final TextEditingController _batch = TextEditingController();
  String? _animalId;
  DateTime _dateGiven = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 180));
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _animalId = widget.initialAnimalId ??
        (widget.animals.isNotEmpty ? widget.animals.first.id : null);
  }

  @override
  void dispose() {
    _vaccine.dispose();
    _batch.dispose();
    super.dispose();
  }

  Animal? get _selected {
    for (final Animal animal in widget.animals) {
      if (animal.id == _animalId) return animal;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Animal? animal = _selected;
    if (animal == null) {
      setState(() => _error = 'Select the animal that was vaccinated.');
      return;
    }
    if (!_validUntil.isAfter(_dateGiven)) {
      setState(() => _error = 'Valid-until must be after the date given.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.onSubmit(
        animal: animal,
        vaccineName: _vaccine.text.trim(),
        batchNo: _batch.text.trim(),
        dateGiven: dateOnly(_dateGiven),
        validUntil: dateOnly(_validUntil),
      );
      if (mounted) {
        setState(() {
          _success =
              'Vaccination saved for ${animal.tagNo}. The animal’s valid-until date updates through the backend trigger.';
          _vaccine.clear();
          _batch.clear();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animals.isEmpty) {
      return const FormTemplate(
        title: 'Record a vaccination',
        fields: <Widget>[
          ErrorBanner(
            message:
                'No animals are registered yet. Ask registry staff to add an animal first.',
          ),
        ],
      );
    }

    final Animal? animal = _selected;
    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Record a vaccination',
        subtitle: 'Vet-only. Records cannot be edited or deleted afterwards.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_success != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      _success!,
                      variant: AppTextVariant.caption,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          DropdownField<String>(
            label: 'Animal',
            value: _animalId,
            hint: 'Select an animal',
            items: widget.animals
                .map((Animal animal) => DropdownOption<String>(
                      value: animal.id,
                      label: '${animal.tagNo} · ${animal.species}',
                      subtitle:
                          '${animal.farmerName} · ${animal.vaxStatus.label}',
                    ))
                .toList(),
            onChanged: (String? value) => setState(() => _animalId = value),
            validator: (String? value) =>
                value == null ? 'Select an animal' : null,
          ),
          if (animal != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AppText(
                          '${animal.tagNo} · ${animal.species}',
                          variant: AppTextVariant.title,
                        ),
                        AppText(
                          animal.vaccinatedUntil == null
                              ? 'No vaccination on record'
                              : 'Current validity: ${formatDate(animal.vaccinatedUntil)}',
                          variant: AppTextVariant.caption,
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: animal.vaxStatus.label,
                    tone: vaxTone(animal.vaxStatus),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _vaccine,
            label: 'Vaccine name',
            hint: 'e.g. FMD Vaccine',
            prefixIcon: Icons.vaccines_outlined,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Vaccine name is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _batch,
            label: 'Batch number',
            hint: 'e.g. FMD-2026-04',
            prefixIcon: Icons.qr_code_2_rounded,
            textInputAction: TextInputAction.done,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Batch number is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          DateField(
            label: 'Date given',
            value: _dateGiven,
            lastDate: DateTime.now(),
            onChanged: (DateTime value) => setState(() => _dateGiven = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          DateField(
            label: 'Valid until',
            value: _validUntil,
            firstDate: _dateGiven,
            onChanged: (DateTime value) => setState(() => _validUntil = value),
            helperText: 'The animal stays eligible for permits until this date.',
          ),
        ],
        footer: AppButton(
          label: 'Save vaccination',
          onPressed: _submit,
          loading: _submitting,
          icon: Icons.save_rounded,
        ),
      ),
    );
  }
}
