import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class ConfirmDialog {
  const ConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: AppText(title, variant: AppTextVariant.title),
          content: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppText(message, variant: AppTextVariant.body),
          ),
          actionsPadding: const EdgeInsets.all(AppSpacing.lg),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: AppText(
                cancelLabel,
                variant: AppTextVariant.label,
                color: AppColors.inkMuted,
              ),
            ),
            SizedBox(
              width: 140,
              child: AppButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
                variant: destructive
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                compact: true,
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
