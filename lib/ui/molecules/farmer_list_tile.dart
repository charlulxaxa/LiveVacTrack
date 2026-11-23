import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/farmer.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_text.dart';

class FarmerListTile extends StatelessWidget {
  const FarmerListTile({required this.farmer, super.key, this.onTap});

  final Farmer farmer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Read by screen readers as one item instead of separate fragments.
    return MergeSemantics(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                AppAvatar(initials: farmer.initials),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppText(
                        farmer.fullName,
                        variant: AppTextVariant.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        '${farmer.barangay}${farmer.contactNo == null ? '' : ' · ${farmer.contactNo}'}',
                        variant: AppTextVariant.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
