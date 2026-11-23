import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_text.dart';

/// Atom: the LiveVacTrack wordmark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false, this.showTagline = true});

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 38 : 48,
          height: compact ? 38 : 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: compact ? 22 : 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppText(
                AppConfig.appName,
                variant: compact ? AppTextVariant.title : AppTextVariant.headline,
                color: AppColors.ink,
              ),
              if (showTagline)
                AppText(
                  AppConfig.appTagline,
                  variant: AppTextVariant.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
