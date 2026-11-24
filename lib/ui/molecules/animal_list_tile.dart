import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

class AnimalListTile extends StatelessWidget {
  const AnimalListTile({required this.animal, super.key, this.onTap});

  final Animal animal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Read by screen readers as one item instead of separate fragments.
    return MergeSemantics(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.neutralSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppText(
                              animal.tagNo,
                              variant: AppTextVariant.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppBadge(
                            label: animal.vaxStatus.label,
                            tone: vaxTone(animal.vaxStatus),
                            dense: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        '${animal.species} · ${animal.breed}',
                        variant: AppTextVariant.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        '${animal.farmerName} · ${animal.barangay}',
                        variant: AppTextVariant.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (animal.vaccinatedUntil != null) ...<Widget>[
                        const SizedBox(height: 4),
                        AppText(
                          'Valid until ${formatDate(animal.vaccinatedUntil)}',
                          variant: AppTextVariant.caption,
                          color: animal.hasCurrentVaccination
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
