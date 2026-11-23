import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/verification.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

/// One checkpoint scan entry, used by the inspector history and by the animal
/// detail screen.
class VerificationTile extends StatelessWidget {
  const VerificationTile({required this.verification, super.key});

  final Verification verification;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scanSoftColor(verification.result),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                scanIcon(verification.result),
                size: 20,
                color: scanColor(verification.result),
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
                          verification.permitId,
                          variant: AppTextVariant.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppBadge(
                        label: verification.result.label,
                        tone: scanTone(verification.result),
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    verification.checkpointName,
                    variant: AppTextVariant.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    formatDateTime(verification.scannedAt),
                    variant: AppTextVariant.caption,
                  ),
                  if (verification.wasOffline) ...<Widget>[
                    const SizedBox(height: 4),
                    const AppBadge(
                      label: 'Offline scan',
                      tone: BadgeTone.warning,
                      dense: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
