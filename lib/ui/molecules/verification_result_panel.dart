import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../data/enums/scan_result.dart';
import '../../data/models/permit.dart';
import '../../data/models/verification.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';
import '../status_styles.dart';

class VerificationResultPanel extends StatelessWidget {
  const VerificationResultPanel({required this.outcome, super.key});

  final VerificationOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final Color color = scanColor(outcome.result);
    final Permit? permit = outcome.permit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scanSoftColor(outcome.result),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(scanIcon(outcome.result), color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppText(
                      outcome.result.label,
                      variant: AppTextVariant.headline,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                    AppText(
                      outcome.result == ScanResult.valid
                          ? 'Permit verified'
                          : 'Do not accept until resolved',
                      variant: AppTextVariant.caption,
                      color: color,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            outcome.message,
            variant: AppTextVariant.body,
            color: AppColors.ink,
          ),
          if (permit != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _line('Permit', permit.id),
            _line('Route', '${permit.origin} → ${permit.destination}'),
            _line('Travel date', formatDate(permit.travelDate)),
            _line('Valid until', formatDate(permit.validUntil)),
            _line('Status', permit.effectiveStatus().label),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              AppBadge(
                label: outcome.signatureValid
                    ? 'Signature verified'
                    : 'Signature not verified',
                tone: outcome.signatureValid
                    ? BadgeTone.success
                    : BadgeTone.danger,
                icon: outcome.signatureValid
                    ? Icons.verified_user_rounded
                    : Icons.gpp_bad_rounded,
              ),
              AppBadge(
                label: outcome.offline ? 'Offline result' : 'Server checked',
                tone: outcome.offline ? BadgeTone.warning : BadgeTone.info,
                icon: outcome.offline
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'Checked ${formatDateTime(outcome.checkedAt)}',
            variant: AppTextVariant.caption,
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: AppText(label, variant: AppTextVariant.caption),
          ),
          Expanded(
            child: AppText(
              value,
              variant: AppTextVariant.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
