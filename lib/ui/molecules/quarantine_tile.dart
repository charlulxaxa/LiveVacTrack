import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/quarantine.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

class QuarantineTile extends StatelessWidget {
  const QuarantineTile({required this.quarantine, super.key});

  final Quarantine quarantine;

  @override
  Widget build(BuildContext context) {
    final bool active = quarantine.isActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: active ? AppColors.dangerSoft : AppColors.neutralSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                active
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: active ? AppColors.danger : AppColors.neutral,
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
                          quarantine.areaName,
                          variant: AppTextVariant.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppBadge(
                        label: quarantine.status.label,
                        tone: quarantineTone(quarantine.status),
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  AppText(
                    quarantine.reason,
                    variant: AppTextVariant.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    active
                        ? 'Started ${formatDateTime(quarantine.startedAt)}'
                        : 'Lifted ${formatDate(quarantine.liftedAt)}',
                    variant: AppTextVariant.caption,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
