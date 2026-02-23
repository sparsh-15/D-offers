import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppPalette {
  final bool isDark;
  final ColorScheme colorScheme;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color surface;
  final Color cardBackground;
  final Color scaffoldBackground;
  final Color cardShadow;
  final Color dividerColor;
  final Color borderColor;

  const AppPalette({
    required this.isDark,
    required this.colorScheme,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.surface,
    required this.cardBackground,
    required this.scaffoldBackground,
    required this.cardShadow,
    required this.dividerColor,
    required this.borderColor,
  });

  factory AppPalette.dark() {
    return AppPalette(
      isDark: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
      ),
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textHint: AppColors.textHint,
      surface: AppColors.surface,
      cardBackground: AppColors.cardBackground,
      scaffoldBackground: AppColors.background,
      cardShadow: AppColors.black.withValues(alpha: 0.28),
      dividerColor: AppColors.white.withValues(alpha: 0.08),
      borderColor: AppColors.white.withValues(alpha: 0.12),
    );
  }

  factory AppPalette.light() {
    return AppPalette(
      isDark: false,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: AppColors.white,
      ),
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      textHint: AppColors.lightTextHint,
      surface: AppColors.lightSurface,
      cardBackground: AppColors.lightCardBackground,
      scaffoldBackground: AppColors.lightBackground,
      cardShadow: AppColors.black.withValues(alpha: 0.08),
      dividerColor: AppColors.black.withValues(alpha: 0.08),
      borderColor: AppColors.black.withValues(alpha: 0.12),
    );
  }
}
