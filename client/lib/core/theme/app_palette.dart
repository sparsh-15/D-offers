import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Dark-only palette. MyOffers is a dark-first premium experience.
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
    return const AppPalette(
      isDark: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.black,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
        surfaceContainerHighest: AppColors.elevated,
        outline: AppColors.borderMid,
        outlineVariant: AppColors.borderSubtle,
      ),
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textHint: AppColors.textMuted,
      surface: AppColors.surface,
      cardBackground: AppColors.cardBackground,
      scaffoldBackground: AppColors.background,
      cardShadow: AppColors.transparent,
      dividerColor: AppColors.borderSubtle,
      borderColor: AppColors.borderMid,
    );
  }

  /// Light factory removed — app is dark-only.
  /// Alias kept so any stale call compiles; returns dark palette.
  factory AppPalette.light() => AppPalette.dark();
}
