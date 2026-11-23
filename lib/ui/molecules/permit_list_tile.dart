import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/permit.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

class PermitListTile extends StatelessWidget {
  const PermitListTile({
    required this.permit,
    super.key,
    this.animalTag,
    this.onTap,
  });

  final Permit permit;
  final String? animalTag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = permit.effectiveStatus();
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppText(
                      permit.id,
                      variant: AppTextVariant.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppBadge(
                    label: status.label,
                    tone: permitTone(status),
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AppText(
                '${permit.origin} → ${permit.destination}',
                variant: AppTextVariant.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  if (animalTag != null) ...<Widget>[
                    AppText(
                      animalTag!,
                      variant: AppTextVariant.caption,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(' · ', variant: AppTextVariant.caption),
                  ],
                  Expanded(
                    child: AppText(
                      'Travel ${formatDate(permit.travelDate)}',
                      variant: AppTextVariant.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
