import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ThemeHelper {
  static Gradient getBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? AppColors.backgroundGradient
        : AppColors.lightBackgroundGradient;
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.surface : AppColors.lightSurface;
  }

  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  }
}
