import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Template: full-height scanner area with room for a result panel below.
class ScanTemplate extends StatelessWidget {
  const ScanTemplate({
    required this.scanner,
    required this.controls,
    required this.result,
    super.key,
  });

  final Widget scanner;
  final Widget controls;
  final Widget result;

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
        const SizedBox(height: AppSpacing.lg),
        result,
      ],
    );
  }
}
