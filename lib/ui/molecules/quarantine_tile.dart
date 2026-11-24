import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/quarantine.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

class QuarantineTile extends StatelessWidget {
  const QuarantineTile({
    required this.quarantine,
    super.key,
    this.onTap,
    this.onActivate,
    this.onLift,
  });

  final Quarantine quarantine;
  final VoidCallback? onTap;
  final VoidCallback? onActivate;
  final VoidCallback? onLift;

  @override
  Widget build(BuildContext context) {
    final bool active = quarantine.isActive;
    final bool canActivate = !active && (onActivate != null);
    final bool canLift = active && (onLift != null);

    // Read by screen readers as one item instead of separate fragments.
    return MergeSemantics(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
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
                    if (canActivate || canLift)
                      Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.inkMuted,
                        size: 20,
                      ),
                  ],
                ),
                if (canActivate || canLift) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      if (canActivate)
                        AppButton(
                          label: 'Activate',
                          onPressed: onActivate,
                          variant: AppButtonVariant.danger,
                          icon: Icons.warning_amber_rounded,
                          compact: true,
                          expand: false,
                        ),
                      if (canActivate && canLift) const SizedBox(width: AppSpacing.sm),
                      if (canLift)
                        AppButton(
                          label: 'Lift',
                          onPressed: onLift,
                          variant: AppButtonVariant.primary,
                          icon: Icons.check_circle_outline_rounded,
                          compact: true,
                          expand: false,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
