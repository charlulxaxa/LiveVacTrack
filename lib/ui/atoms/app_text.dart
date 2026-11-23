import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppTextVariant { display, headline, title, body, label, caption }

/// Atom: the single text primitive used across the app.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
    this.softWrap,
  });

  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;
    final TextStyle? base;
    switch (variant) {
      case AppTextVariant.display:
        base = theme.displaySmall;
      case AppTextVariant.headline:
        base = theme.headlineMedium;
      case AppTextVariant.title:
        base = theme.titleLarge;
      case AppTextVariant.body:
        base = theme.bodyMedium;
      case AppTextVariant.label:
        base = theme.labelLarge;
      case AppTextVariant.caption:
        base = theme.bodySmall;
    }

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: (base ?? const TextStyle()).copyWith(
        color: color ?? AppColors.ink,
        fontWeight: fontWeight,
      ),
    );
  }
}
