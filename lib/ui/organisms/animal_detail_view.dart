import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/verification.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_spinner.dart';
import '../atoms/app_text.dart';
import '../molecules/empty_state.dart';
import '../molecules/info_row.dart';
import '../molecules/section_header.dart';
import '../molecules/verification_tile.dart';
import '../status_styles.dart';

class AnimalDetailView extends StatelessWidget {
  const AnimalDetailView({
    required this.animal,
    required this.vaccinations,
    super.key,
    this.loadingVaccinations = false,
    this.areaQuarantined = false,
    this.verifications = const <Verification>[],
    this.loadingVerifications = false,
  });

  final Animal animal;
  final List<Vaccination> vaccinations;
  final bool loadingVaccinations;
  final bool areaQuarantined;
  final List<Verification> verifications;
  final bool loadingVerifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppText(
                            animal.tagNo,
                            variant: AppTextVariant.headline,
                          ),
                          AppText(
                            '${animal.species} · ${animal.breed}',
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
                const SizedBox(height: AppSpacing.lg),
                InfoRow(label: 'Farmer', value: animal.farmerName),
                const Divider(height: 1),
                InfoRow(label: 'Barangay', value: animal.barangay),
                const Divider(height: 1),
                InfoRow(
                  label: 'Vaccinated until',
                  value: formatDate(animal.vaccinatedUntil),
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Registered',
                  value: formatDate(animal.registeredAt),
                ),
              ],
            ),
          ),
        ),
        if (areaQuarantined) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
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
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    '${animal.barangay} is under an active quarantine. No new permits can be issued for this animal.',
                    variant: AppTextVariant.caption,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Vaccination history',
          subtitle: '${vaccinations.length} record(s)',
        ),
        const SizedBox(height: AppSpacing.md),
        if (loadingVaccinations && vaccinations.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: AppSpinner()),
          )
        else if (vaccinations.isEmpty)
          const EmptyState(
            title: 'No vaccinations recorded',
            message: 'A vet can record the first vaccination from the Vaccinate tab.',
            icon: Icons.vaccines_outlined,
          )
        else
          Column(
            children: <Widget>[
              for (int i = 0; i < vaccinations.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _VaccinationCard(vaccination: vaccinations[i]),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(
          title: 'Checkpoint scans',
          subtitle: '${verifications.length} scan(s)',
        ),
        const SizedBox(height: AppSpacing.md),
        if (loadingVerifications && verifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: AppSpinner()),
          )
        else if (verifications.isEmpty)
          const EmptyState(
            title: 'No checkpoint scans',
            message: 'Scans of permits for this animal will appear here.',
            icon: Icons.qr_code_scanner_rounded,
          )
        else
          Column(
            children: <Widget>[
              for (int i = 0; i < verifications.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                VerificationTile(verification: verifications[i]),
              ],
            ],
          ),
      ],
    );
  }
}

class _VaccinationCard extends StatelessWidget {
  const _VaccinationCard({required this.vaccination});

  final Vaccination vaccination;

  @override
  Widget build(BuildContext context) {
    final bool current = vaccination.validUntil.isAfter(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: AppText(
                    vaccination.vaccineName,
                    variant: AppTextVariant.title,
                  ),
                ),
                AppBadge(
                  label: current ? 'Current' : 'Expired',
                  tone: current ? BadgeTone.success : BadgeTone.warning,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppText(
              'Batch ${vaccination.batchNo}',
              variant: AppTextVariant.caption,
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.event_available_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                AppText(
                  'Given ${formatDate(vaccination.dateGiven)}',
                  variant: AppTextVariant.caption,
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(
                  Icons.event_busy_rounded,
                  size: 14,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: 4),
                AppText(
                  'Until ${formatDate(vaccination.validUntil)}',
                  variant: AppTextVariant.caption,
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppText(
              'Recorded by ${vaccination.vetName}',
              variant: AppTextVariant.caption,
            ),
          ],
        ),
      ),
    );
  }
}
