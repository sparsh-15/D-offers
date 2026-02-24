import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_component_themes.dart';
import 'app_palette.dart';
import 'app_text_styles.dart';

class AppTheme {
  // Default app theme (Teal Mint light)
  static ThemeData get appTheme => lightTheme;
  static ThemeData get darkTheme => _buildTheme(AppPalette.dark());
  static ThemeData get lightTheme => _buildTheme(AppPalette.light());

  static ThemeData _buildTheme(AppPalette palette) {
    return ThemeData(
      useMaterial3: true,
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: palette.scaffoldBackground,
      colorScheme: palette.colorScheme,
      dividerColor: palette.dividerColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: AppTextStyles.build(palette),
      appBarTheme: AppComponentThemes.appBarTheme(palette),
      cardTheme: AppComponentThemes.cardTheme(palette),
      elevatedButtonTheme: AppComponentThemes.elevatedButtonTheme(),
      outlinedButtonTheme: AppComponentThemes.outlinedButtonTheme(),
      inputDecorationTheme: AppComponentThemes.inputDecorationTheme(palette),
      listTileTheme: AppComponentThemes.listTileTheme(palette),
      snackBarTheme: AppComponentThemes.snackBarTheme(),
      dialogTheme: AppComponentThemes.dialogTheme(palette),
      chipTheme: AppComponentThemes.chipTheme(palette),
      switchTheme: AppComponentThemes.switchTheme(palette),
      iconTheme: const IconThemeData(color: AppColors.primary, size: 24),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 2,
      ),
      bottomNavigationBarTheme: AppComponentThemes.bottomNavigationBarTheme(
        palette,
      ),
      navigationBarTheme: AppComponentThemes.navigationBarTheme(palette),
      dividerTheme: AppComponentThemes.dividerTheme(palette),
    );
  }
}
