import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: color ?? AppColors.primary,
      ),
    );
  }
}
