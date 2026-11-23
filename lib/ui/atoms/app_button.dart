import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_spinner.dart';
import 'app_text.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Atom: every action in the app goes through this button.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? handler = loading ? null : onPressed;
    final Widget child = loading
        ? const AppSpinner(size: 20, color: Colors.white)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: AppText(
                  label,
                  variant: AppTextVariant.label,
                  color: _foregroundFor(variant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final ButtonStyle? style = compact
        ? ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              const Size(0, 42),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
          )
        : null;

    final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: handler,
          style: style,
          child: child,
        );
      case AppButtonVariant.danger:
        button = FilledButton(
          onPressed: handler,
          style: (style ?? const ButtonStyle()).copyWith(
            backgroundColor: WidgetStateProperty.all(AppColors.danger),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          child: loading
              ? const AppSpinner(size: 20, color: Colors.white)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      const Icon(Icons.warning_amber_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: AppText(
                        label,
                        variant: AppTextVariant.label,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: handler,
          style: style,
          child: child,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: handler,
          style: style,
          child: loading
              ? const AppSpinner(size: 20)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    AppText(
                      label,
                      variant: AppTextVariant.label,
                      color: AppColors.primary,
                    ),
                  ],
                ),
        );
    }

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _foregroundFor(AppButtonVariant variant) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }
}
