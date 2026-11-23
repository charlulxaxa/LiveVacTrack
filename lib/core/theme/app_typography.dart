import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(
      fontSize: 32,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.3,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.45,
      color: AppColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      color: AppColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.4,
      color: AppColors.inkMuted,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );
}
