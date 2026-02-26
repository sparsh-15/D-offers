import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'app_palette.dart';

class AppComponentThemes {
  static AppBarTheme appBarTheme(AppPalette palette) {
    return AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: AppColors.transparent,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
    );
  }

  /// Cards: no border, no shadow. Elevation via tonal background only.
  static CardThemeData cardTheme(AppPalette palette) {
    return CardThemeData(
      color: AppColors.cardBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shadowColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Full-width, 52px height, accent background, dark text on press.
  static ElevatedButtonThemeData elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.black,
        disabledBackgroundColor: AppColors.accentDim.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.textMuted,
        elevation: 0,
        shadowColor: AppColors.transparent,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Outlined: border-mid, text-secondary, no accent border.
  static OutlinedButtonThemeData outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderMid, width: 1.2),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  /// Inputs: bg-elevated fill, border-subtle default, accent-dim focus.
  static InputDecorationTheme inputDecorationTheme(AppPalette palette) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.elevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accentDim, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.never,
    );
  }

  static ListTileThemeData listTileTheme(AppPalette palette) {
    return ListTileThemeData(
      iconColor: AppColors.accentDim,
      textColor: AppColors.textPrimary,
      tileColor: AppColors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static SnackBarThemeData snackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: AppColors.elevated,
      contentTextStyle: GoogleFonts.dmSans(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static DialogThemeData dialogTheme(AppPalette palette) {
    return DialogThemeData(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  /// Chips: pill shape, bg-elevated fill, label text style (11/w600/0.8).
  static ChipThemeData chipTheme(AppPalette palette) {
    return ChipThemeData(
      backgroundColor: AppColors.elevated,
      selectedColor: AppColors.accentDim.withValues(alpha: 0.25),
      disabledColor: AppColors.elevated.withValues(alpha: 0.5),
      side: BorderSide.none,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
      secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        letterSpacing: 0.6,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const StadiumBorder(),
    );
  }

  static SwitchThemeData switchTheme(AppPalette palette) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentDim.withValues(alpha: 0.45);
        }
        return AppColors.elevated;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.borderMid),
    );
  }

  /// Bottom nav: bg-raised background, accent-dim for selected icons.
  static BottomNavigationBarThemeData bottomNavigationBarTheme(
    AppPalette palette,
  ) {
    return const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static NavigationBarThemeData navigationBarTheme(AppPalette palette) {
    return NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accentDim.withValues(alpha: 0.18),
      surfaceTintColor: AppColors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? AppColors.accent : AppColors.textMuted,
          letterSpacing: 0.3,
        );
      }),
    );
  }

  static DividerThemeData dividerTheme(AppPalette palette) {
    return const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
      space: 1,
    );
  }

  static TabBarThemeData tabBarTheme() {
    return TabBarThemeData(
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.accent,
      dividerColor: AppColors.borderSubtle,
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
