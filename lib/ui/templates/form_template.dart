import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../atoms/app_text.dart';

/// Template: scrollable form with a title, fields and a sticky-looking footer.
class FormTemplate extends StatelessWidget {
  const FormTemplate({
    required this.title,
    required this.fields,
    super.key,
    this.subtitle,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pagePadding,
      AppSpacing.lg,
      AppSpacing.pagePadding,
      AppSpacing.xxl,
    ),
  });

  final String title;
  final String? subtitle;
  final List<Widget> fields;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: <Widget>[
        AppText(title, variant: AppTextVariant.title),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 4),
          AppText(subtitle!, variant: AppTextVariant.caption),
        ],
        const SizedBox(height: AppSpacing.lg),
        ...fields,
        if (footer != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          footer!,
        ],
      ],
    );
  }
}
