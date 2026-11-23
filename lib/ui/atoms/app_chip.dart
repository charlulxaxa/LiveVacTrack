import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_text.dart';

/// Atom: filter chip used on list screens.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppText(
            label,
            variant: AppTextVariant.caption,
            color: selected ? AppColors.primary : AppColors.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.neutralSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: AppText(
                '$count',
                variant: AppTextVariant.caption,
                color: selected ? AppColors.primary : AppColors.inkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
