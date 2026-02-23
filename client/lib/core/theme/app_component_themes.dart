import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'app_palette.dart';

class AppComponentThemes {
  static AppBarTheme appBarTheme(AppPalette palette) {
    return AppBarTheme(
      backgroundColor: palette.surface,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary),
    );
  }

  static CardThemeData cardTheme(AppPalette palette) {
    return CardThemeData(
      color: palette.cardBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: palette.isDark ? 6 : 2,
      shadowColor: palette.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.borderColor),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static ElevatedButtonThemeData elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
        disabledForegroundColor: AppColors.white.withValues(alpha: 0.75),
        elevation: 0,
        shadowColor: AppColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme inputDecorationTheme(AppPalette palette) {
    return InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: TextStyle(color: palette.textHint),
      labelStyle: TextStyle(color: palette.textSecondary),
    );
  }

  static ListTileThemeData listTileTheme(AppPalette palette) {
    return ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: palette.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static SnackBarThemeData snackBarTheme() {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static DialogThemeData dialogTheme(AppPalette palette) {
    return DialogThemeData(
      backgroundColor: palette.cardBackground,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ChipThemeData chipTheme(AppPalette palette) {
    return ChipThemeData(
      backgroundColor: palette.isDark
          ? AppColors.surface.withValues(alpha: 0.75)
          : AppColors.white,
      side: BorderSide(color: palette.borderColor),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(color: palette.textPrimary),
      secondaryLabelStyle: TextStyle(color: palette.textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  static SwitchThemeData switchTheme(AppPalette palette) {
    return SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(AppColors.primary),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.45);
        }
        return palette.textHint.withValues(alpha: 0.45);
      }),
    );
  }

  static BottomNavigationBarThemeData bottomNavigationBarTheme(
    AppPalette palette,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: palette.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  static NavigationBarThemeData navigationBarTheme(AppPalette palette) {
    return NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.primary : palette.textHint,
        );
      }),
    );
  }

  static DividerThemeData dividerTheme(AppPalette palette) {
    return DividerThemeData(
      color: palette.dividerColor,
      thickness: 1,
      space: 1,
    );
  }
}
