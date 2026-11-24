import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/quarantine.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/confirm_dialog.dart';
import '../molecules/error_banner.dart';
import '../molecules/location_picker.dart';
import '../molecules/quarantine_tile.dart';
import '../templates/form_template.dart';

class DeclareQuarantineForm extends StatefulWidget {
  const DeclareQuarantineForm({
    required this.activeAreas,
    required this.onDeclare,
    this.quarantines = const <Quarantine>[],
    this.onActivate,
    this.onLift,
    super.key,
  });

  final Set<String> activeAreas;
  final Future<int> Function({
    required String areaId,
    required String areaName,
    required String reason,
  }) onDeclare;
  final List<Quarantine> quarantines;
  final Future<void> Function(Quarantine quarantine)? onActivate;
  final Future<void> Function(Quarantine quarantine)? onLift;

  @override
  State<DeclareQuarantineForm> createState() => _DeclareQuarantineFormState();
}

class _DeclareQuarantineFormState extends State<DeclareQuarantineForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();
  String? _areaId;
  String? _areaName;
  bool _submitting = false;
  String? _error;
  int? _revokedCount;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? areaId = _areaId;
    if (areaId == null) {
      setState(() => _error = 'Select the affected area.');
      return;
    }
    final String areaName = _areaName ?? AppConfig.areaName(areaId);
    if (widget.activeAreas.contains(areaId)) {
      setState(() => _error = 'That area already has an active quarantine.');
      return;
    }

    final bool confirmed = await ConfirmDialog.show(
      context,
      title: 'Declare quarantine?',
      message:
          'All issued permits in $areaName will be revoked and new permits blocked. This is broadcast to every staff screen.',
      confirmLabel: 'Declare',
      destructive: true,
    );
    if (!confirmed) return;

    setState(() {
      _submitting = true;
      _error = null;
      _revokedCount = null;
    });
    try {
      final int revoked = await widget.onDeclare(
        areaId: areaId,
        areaName: areaName,
        reason: _reason.text.trim(),
      );
      if (mounted) setState(() => _revokedCount = revoked);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_revokedCount != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: <Widget>[
                const Icon(Icons.gpp_maybe_rounded,
                    size: 42, color: AppColors.danger),
                const SizedBox(height: AppSpacing.sm),
                AppText(
                  'Quarantine active',
                  variant: AppTextVariant.headline,
                  color: AppColors.danger,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '$_revokedCount permit(s) revoked. New permits in this area are blocked.',
                  variant: AppTextVariant.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Declare another quarantine',
            onPressed: () => setState(() {
              _revokedCount = null;
              _areaId = null;
              _areaName = null;
              _reason.clear();
            }),
            variant: AppButtonVariant.secondary,
          ),
        ],
      );
    }

    final List<Quarantine> liftedQuarantines = widget.quarantines
        .where((Quarantine q) => !q.isActive)
        .toList();
    final List<Quarantine> activeQuarantines = widget.quarantines
        .where((Quarantine q) => q.isActive)
        .toList();

    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Declare a quarantine',
        subtitle:
            'Mimics the Disease Alert System. Revokes permits and blocks new ones.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          LocationPicker(
            label: 'Affected area',
            onChanged: (AreaSelection? selection) {
              setState(() {
                _areaId = selection?.id;
                _areaName = selection?.fullName;
              });
            },
            validator: (AreaSelection? value) =>
                value == null ? 'Select an area' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _reason,
            label: 'Reason',
            hint: 'e.g. Suspected African Swine Fever detected',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Reason is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    'This immediately revokes every issued permit in the area. '
                    'Checkpoint scans will show REVOKED.',
                    variant: AppTextVariant.caption,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (liftedQuarantines.isNotEmpty || activeQuarantines.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Existing quarantines',
              variant: AppTextVariant.title,
              color: AppColors.ink,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (liftedQuarantines.isNotEmpty) ...<Widget>[
              AppText(
                'Lifted (can be reactivated)',
                variant: AppTextVariant.caption,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.xs),
              Column(
                children: <Widget>[
                  for (int i = 0; i < liftedQuarantines.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    QuarantineTile(
                      quarantine: liftedQuarantines[i],
                      onActivate: widget.onActivate != null
                          ? () => widget.onActivate!(liftedQuarantines[i])
                          : null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (activeQuarantines.isNotEmpty) ...<Widget>[
              AppText(
                'Active (can be lifted)',
                variant: AppTextVariant.caption,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.xs),
              Column(
                children: <Widget>[
                  for (int i = 0; i < activeQuarantines.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    QuarantineTile(
                      quarantine: activeQuarantines[i],
                      onLift: widget.onLift != null
                          ? () => widget.onLift!(activeQuarantines[i])
                          : null,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
        footer: AppButton(
          label: 'Declare quarantine',
          onPressed: _submit,
          loading: _submitting,
          variant: AppButtonVariant.danger,
          icon: Icons.gpp_maybe_rounded,
        ),
      ),
    );
  }
}
