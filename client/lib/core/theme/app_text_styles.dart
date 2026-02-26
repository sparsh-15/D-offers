import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Typography system using DM Sans.
/// Scale follows an 8-point rhythm with tighter tracking for larger sizes.
class AppTextStyles {
  static TextTheme build(AppPalette palette) {
    return GoogleFonts.dmSansTextTheme().copyWith(
      // display-xl: 36 / w700 / -1.2 → hero numbers (e.g. "30%")
      displayLarge: GoogleFonts.dmSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        letterSpacing: -1.2,
      ),
      // display-lg: 28 / w700 / -0.8 → section titles
      displayMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        letterSpacing: -0.8,
      ),
      // display-sm: 24 / w600
      displaySmall: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: -0.4,
      ),
      // title-lg: 20 / w600 / -0.4 → screen titles
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: -0.4,
      ),
      // title-md: 17 / w600 / 0 → card headings
      titleLarge: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: 0,
      ),
      // title-sm: 15 / w500 / 0 → sub-labels
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
        letterSpacing: 0,
      ),
      // body-lg: 15 / w400 / 0.1 / 1.5lh → body copy
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      // body-sm: 13 / w400 / 0.1 / 1.4lh → secondary info
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      // label: 11 / w600 / 0.8 → tags, chips, statuses
      bodySmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textHint,
        letterSpacing: 0.8,
        height: 1.3,
      ),
      // labelLarge used for buttons
      labelLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: palette.textHint,
        letterSpacing: 0.8,
      ),
    );
  }
}
