import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_icon_tile.dart';
import '../atoms/app_text.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    super.key,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIconTile(icon: icon, size: 64),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              title,
              variant: AppTextVariant.title,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              AppText(
                message!,
                variant: AppTextVariant.body,
                color: AppColors.inkMuted,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
