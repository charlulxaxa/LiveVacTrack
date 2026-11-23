import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Template: scanner area, its controls, and an optional result section.
class ScanTemplate extends StatelessWidget {
  const ScanTemplate({
    required this.scanner,
    required this.controls,
    super.key,
    this.result,
  });

  final Widget scanner;
  final Widget controls;
  final Widget? result;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        scanner,
        const SizedBox(height: AppSpacing.lg),
        controls,
        if (result != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          result!,
        ],
      ],
    );
  }
}
