import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../atoms/app_text.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.lastSynced,
    this.message =
        'You are offline. Cached data is shown and cannot be treated as a live verification.',
  });

  final DateTime? lastSynced;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppText(
                  message,
                  variant: AppTextVariant.caption,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 2),
                AppText(
                  lastSyncedLabel(lastSynced),
                  variant: AppTextVariant.caption,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
