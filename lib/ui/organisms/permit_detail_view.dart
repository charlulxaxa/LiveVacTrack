import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/qr_payload.dart';
import '../../data/enums/permit_status.dart';
import '../../data/models/animal.dart';
import '../../data/models/permit.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_qr_view.dart';
import '../atoms/app_text.dart';
import '../molecules/info_row.dart';
import '../molecules/section_header.dart';
import '../status_styles.dart';

class PermitDetailView extends StatelessWidget {
  const PermitDetailView({required this.permit, super.key, this.animal});

  final Permit permit;
  final Animal? animal;

  @override
  Widget build(BuildContext context) {
    final PermitStatusView status = _statusView();
    final String payload = PermitQrPayload(
      permitId: permit.id,
      signedCode: permit.signedCode,
    ).encode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: status.softColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: status.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: <Widget>[
              Icon(status.icon, color: status.color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppText(
                  status.message,
                  variant: AppTextVariant.caption,
                  color: status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(child: AppQrView(data: payload, size: 220)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: AppText(
            'Show this QR at the checkpoint',
            variant: AppTextVariant.caption,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SectionHeader(
                        title: permit.id,
                        subtitle: 'Signed movement permit',
                      ),
                    ),
                    AppBadge(
                      label: permit.effectiveStatus().label,
                      tone: permitTone(permit.effectiveStatus()),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                InfoRow(
                  label: 'Route',
                  value: '${permit.origin} → ${permit.destination}',
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Travel date',
                  value: formatDate(permit.travelDate),
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Valid until',
                  value: formatDate(permit.validUntil),
                ),
                const Divider(height: 1),
                InfoRow(
                  label: 'Issued',
                  value: formatDateTime(permit.issuedAt),
                ),
                const Divider(height: 1),
                InfoRow(label: 'Area', value: permit.areaId),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Signed code',
                  subtitle: 'Produced by Cloud Functions, not the phone',
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SelectableText(
                          permit.signedCode,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy signed code',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: permit.signedCode),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Signed code copied'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (animal != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(title: 'Animal'),
                  const SizedBox(height: AppSpacing.md),
                  InfoRow(label: 'Tag', value: animal!.tagNo),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Species',
                    value: '${animal!.species} · ${animal!.breed}',
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Farmer', value: animal!.farmerName),
                  const Divider(height: 1),
                  InfoRow(label: 'Barangay', value: animal!.barangay),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  PermitStatusView _statusView() {
    switch (permit.effectiveStatus()) {
      case PermitStatus.issued:
        return const PermitStatusView(
          message: 'This permit is valid. The checkpoint will verify the signature online.',
          color: AppColors.success,
          softColor: AppColors.successSoft,
          icon: Icons.verified_rounded,
        );
      case PermitStatus.revoked:
        return const PermitStatusView(
          message: 'This permit was revoked. Do not allow movement; ask the checkpoint to scan it.',
          color: AppColors.danger,
          softColor: AppColors.dangerSoft,
          icon: Icons.block_rounded,
        );
      case PermitStatus.expired:
        return const PermitStatusView(
          message: 'This permit is past its valid-until date. A new permit is required.',
          color: AppColors.warning,
          softColor: AppColors.warningSoft,
          icon: Icons.schedule_rounded,
        );
    }
  }
}

class PermitStatusView {
  const PermitStatusView({
    required this.message,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final String message;
  final Color color;
  final Color softColor;
  final IconData icon;
}
