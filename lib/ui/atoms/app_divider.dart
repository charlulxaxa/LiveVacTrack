import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = AppSpacing.xl});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height / 2),
      child: const Divider(height: 1),
    );
  }
}
