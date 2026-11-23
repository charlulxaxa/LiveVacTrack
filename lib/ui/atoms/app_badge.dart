import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_text.dart';

enum BadgeTone { success, warning, danger, info, neutral }

/// Atom: a compact status pill. All status colours come from one place.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    super.key,
    this.tone = BadgeTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final BadgeTone tone;
  final IconData? icon;
  final bool dense;

  Color get _background {
    switch (tone) {
      case BadgeTone.success:
        return AppColors.successSoft;
      case BadgeTone.warning:
        return AppColors.warningSoft;
      case BadgeTone.danger:
        return AppColors.dangerSoft;
      case BadgeTone.info:
        return AppColors.infoSoft;
      case BadgeTone.neutral:
        return AppColors.neutralSoft;
    }
  }

  Color get _foreground {
    switch (tone) {
      case BadgeTone.success:
        return AppColors.success;
      case BadgeTone.warning:
        return AppColors.warning;
      case BadgeTone.danger:
        return AppColors.danger;
      case BadgeTone.info:
        return AppColors.info;
      case BadgeTone.neutral:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: _foreground.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 11 : 13, color: _foreground),
            const SizedBox(width: 4),
          ] else ...<Widget>[
            Container(
              width: dense ? 6 : 7,
              height: dense ? 6 : 7,
              decoration: BoxDecoration(
                color: _foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          AppText(
            label,
            variant: AppTextVariant.caption,
            color: _foreground,
            fontWeight: FontWeight.w700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
