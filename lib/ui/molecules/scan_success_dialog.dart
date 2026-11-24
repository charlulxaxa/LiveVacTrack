import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

/// Shown right after the camera reads a permit QR, before anything is
/// verified or logged. Continue opens the verify page; Scan again (or
/// dismissing the dialog) returns to the camera.
class ScanSuccessDialog {
  const ScanSuccessDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String permitId,
    required String checkpointName,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => _ScanSuccessContent(
        permitId: permitId,
        checkpointName: checkpointName,
      ),
    );
    return result ?? false;
  }
}

class _ScanSuccessContent extends StatelessWidget {
  const _ScanSuccessContent({
    required this.permitId,
    required this.checkpointName,
  });

  final String permitId;
  final String checkpointName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      content: Semantics(
        liveRegion: true,
        label: 'Permit scanned. Permit $permitId.',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.success,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText(
              'Permit scanned',
              variant: AppTextVariant.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Continue to check it against the permit record.',
              variant: AppTextVariant.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Detail(label: 'Permit', value: permitId),
                  const SizedBox(height: AppSpacing.xs),
                  _Detail(label: 'At', value: checkpointName),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Scan again',
                onPressed: () => Navigator.of(context).pop(false),
                variant: AppButtonVariant.secondary,
                compact: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Continue',
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icons.arrow_forward_rounded,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 56,
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
    );
  }
}
