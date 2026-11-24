import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_spacing.dart';
import '../molecules/section_header.dart';

/// Template: header + optional controls + scrollable list content.
class ListTemplate extends StatelessWidget {
  const ListTemplate({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.action,
    this.controls,
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
  final Widget? action;
  final Widget? controls;
  final Widget child;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: <Widget>[
        SectionHeader(
          title: title,
          subtitle: subtitle,
          trailing: action,
        ),
        if (controls != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          controls!,
        ],
        const SizedBox(height: AppSpacing.lg),
        child,
        if (footer != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          footer!,
        ],
      ],
    );
  }
}
