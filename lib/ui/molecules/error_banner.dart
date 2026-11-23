import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    required this.message,
    super.key,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppText(
              message,
              variant: AppTextVariant.caption,
              color: AppColors.danger,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: retryLabel,
              onPressed: onRetry,
              variant: AppButtonVariant.ghost,
              expand: false,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}
