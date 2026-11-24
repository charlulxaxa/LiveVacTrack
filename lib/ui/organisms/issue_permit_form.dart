import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/psgc_location_service.dart';
import '../../core/utils/qr_payload.dart';
import '../../data/models/animal.dart';
import '../../data/models/permit.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_qr_view.dart';
import '../atoms/app_text.dart';
import '../molecules/date_field.dart';
import '../molecules/dropdown_field.dart';
import '../molecules/error_banner.dart';
import '../molecules/info_row.dart';
import '../molecules/nationwide_location_picker.dart';
import '../molecules/origin_barangay_picker.dart';
import '../templates/form_template.dart';

class IssuePermitForm extends StatefulWidget {
  const IssuePermitForm({
    required this.animals,
    required this.quarantinedAreas,
    required this.onIssue,
    required this.onViewPermit,
    required this.assignedAreaId,
    super.key,
  });

  /// The permit officer's own area; the origin is limited to the barangays
  /// of that city or municipality.
  final String? assignedAreaId;
  final List<Animal> animals;
  final Set<String> quarantinedAreas;
  final Future<Permit> Function({
    required Animal animal,
    required String origin,
    required String destination,
    required DateTime travelDate,
  }) onIssue;
  final void Function(Permit permit) onViewPermit;

  @override
  State<IssuePermitForm> createState() => _IssuePermitFormState();
}

class _IssuePermitFormState extends State<IssuePermitForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _originId;
  String? _originLabel;
  AreaSelection? _destination;
  String? _animalId;
  DateTime _travelDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;
  String? _error;
  Permit? _issued;

  List<Animal> get _eligible => widget.animals.where((Animal animal) {
        return animal.isVaccinatedFor(_travelDate) &&
            !widget.quarantinedAreas.contains(animal.areaId);
      }).toList();

  Animal? get _selected {
    for (final Animal animal in _eligible) {
      if (animal.id == _animalId) return animal;
    }
    return null;
  }

  Future<void> _issue() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final Animal? animal = _selected;
    if (animal == null) {
      setState(() => _error = 'Select an eligible animal.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final Permit permit = await widget.onIssue(
        animal: animal,
        origin: _originLabel ?? '',
        destination: _destination!.fullName,
        travelDate: _travelDate,
      );
      if (mounted) setState(() => _issued = permit);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _reset() {
    setState(() {
      _issued = null;
      _animalId = null;
      _originId = null;
      _originLabel = null;
      _destination = null;
      _travelDate = DateTime.now().add(const Duration(days: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_issued != null) {
      return _SuccessView(
        permit: _issued!,
        onViewPermit: () => widget.onViewPermit(_issued!),
        onAnother: _reset,
      );
    }

    final List<Animal> eligible = _eligible;
    final String? selectedId = eligible.any((Animal a) => a.id == _animalId)
        ? _animalId
        : null;

    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Issue a movement permit',
        subtitle:
            'Cloud Functions re-checks vaccination and quarantine before signing.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.quarantinedAreas.isNotEmpty) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      'Active quarantine: animals from '
                      '${widget.quarantinedAreas.length} area(s) are blocked '
                      'from new permits.',
                      variant: AppTextVariant.caption,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (eligible.isEmpty)
            const ErrorBanner(
              message:
                  'No animals are eligible for this travel date. Check vaccination validity and active quarantines.',
            )
          else ...<Widget>[
            AppText(
              '${eligible.length} eligible animal(s)',
              variant: AppTextVariant.caption,
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownField<String>(
              label: 'Animal',
              value: selectedId,
              hint: 'Select a vaccinated animal',
              items: eligible
                  .map((Animal animal) => DropdownOption<String>(
                        value: animal.id,
                        label: '${animal.tagNo} · ${animal.species}',
                        subtitle:
                            '${animal.farmerName} · valid until ${formatDate(animal.vaccinatedUntil)}',
                      ))
                  .toList(),
              onChanged: (String? value) => setState(() => _animalId = value),
              validator: (String? value) =>
                  value == null ? 'Select an animal' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            DateField(
              label: 'Travel date',
              value: _travelDate,
              firstDate: DateTime.now(),
              onChanged: (DateTime value) {
                setState(() {
                  _travelDate = value;
                  if (_selected == null) _animalId = null;
                });
              },
              helperText:
                  'Eligibility is checked against the vaccination valid-until date.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText('Origin', variant: AppTextVariant.title),
            const SizedBox(height: AppSpacing.sm),
            OriginBarangayPicker(
              assignedAreaId: widget.assignedAreaId,
              value: _originId,
              onChanged: (String? id, String? label) => setState(() {
                _originId = id;
                _originLabel = label;
              }),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppText('Destination', variant: AppTextVariant.title),
            const SizedBox(height: AppSpacing.sm),
            NationwideLocationPicker(
              label: 'Destination barangay',
              onChanged: (AreaSelection? value) =>
                  setState(() => _destination = value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppText(
              'The signed code is created on the server. It never leaves the '
              'Functions environment.',
              variant: AppTextVariant.caption,
            ),
          ],
        ],
        footer: AppButton(
          label: 'Issue permit',
          onPressed: eligible.isEmpty ? null : _issue,
          loading: _submitting,
          icon: Icons.verified_rounded,
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.permit,
    required this.onViewPermit,
    required this.onAnother,
  });

  final Permit permit;
  final VoidCallback onViewPermit;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.successSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: <Widget>[
              const Icon(Icons.verified_rounded,
                  size: 42, color: AppColors.success),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Permit issued',
                variant: AppTextVariant.headline,
                color: AppColors.success,
                textAlign: TextAlign.center,
              ),
              AppText(
                permit.id,
                variant: AppTextVariant.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AppQrView(
                  data: PermitQrPayload(
                    permitId: permit.id,
                    signedCode: permit.signedCode,
                  ).encode(),
                  size: 180,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppBadge(
                label: permit.effectiveStatus().label,
                tone: BadgeTone.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                InfoRow(
                  label: 'Route',
                  value: '${permit.origin} → ${permit.destination}',
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Travel date',
                  value: formatDate(permit.travelDate),
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Valid until',
                  value: formatDate(permit.validUntil),
                ),
                const Divider(height: 1),
                InfoRow(label: 'Signed code', value: permit.signedCode),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'View permit details',
          onPressed: onViewPermit,
          icon: Icons.open_in_new_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Issue another permit',
          onPressed: onAnother,
          variant: AppButtonVariant.secondary,
        ),
      ],
    );
  }
}
