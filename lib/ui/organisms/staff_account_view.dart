import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

/// Registry-only view for provisioning staff accounts.
class StaffAccountView extends StatelessWidget {
  const StaffAccountView({required this.onAdd, super.key});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.badge_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  AppText(
                    'Staff accounts',
                    variant: AppTextVariant.title,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Create registry, vet, clerk, inspector and disease control '
                'accounts. Each account signs in with its email and password.',
                variant: AppTextVariant.body,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Add staff account',
          onPressed: onAdd,
          icon: Icons.person_add_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        AppText(
          'Only the super admin can create accounts. Farmers are not app '
          'users and do not need an account.',
          variant: AppTextVariant.caption,
        ),
      ],
    );
  }
}
