import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginRevampColors {
  static const Color topStart = Color(0xFF0F172A);
  static const Color topEnd = Color(0xFF1E293B);
  static const Color panel = Color(0xFFF4F6F8);
  static const Color heading = Color(0xFF0B1A33);
  static const Color textPrimary = Color(0xFF1F2E4A);
  static const Color textMuted = Color(0xFF5D6E88);
  static const Color textSoft = Color(0xFF67758A);
  static const Color fieldBorder = Color(0xFFD7D9DE);
  static const Color accent = Color(0xFFF8991D);
  static const Color white = Colors.white;
}

class LoginRevampRadius {
  static const double panel = 30;
  static const double field = 18;
  static const double button = 22;
  static const double logo = 16;
}

class LoginRevampTypography {
  static TextStyle get brand => GoogleFonts.dmSans(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        color: LoginRevampColors.white,
        height: 1.15,
      );

  static TextStyle get brandAccent => brand.copyWith(
        color: LoginRevampColors.accent,
      );

  static TextStyle get subcopy => GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
        color: LoginRevampColors.textSoft,
        height: 1.35,
      );

  static TextStyle get sectionTitle => GoogleFonts.dmSans(
      fontSize: 40,
        fontWeight: FontWeight.w700,
        color: LoginRevampColors.heading,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.dmSans(
      fontSize: 16,
        fontWeight: FontWeight.w500,
        color: LoginRevampColors.textMuted,
      );

  static TextStyle get fieldLabel => GoogleFonts.dmSans(
      fontSize: 14,
        fontWeight: FontWeight.w700,
        color: LoginRevampColors.heading,
        letterSpacing: 0.5,
      );

  static TextStyle get body => GoogleFonts.dmSans(
      fontSize: 17,
        fontWeight: FontWeight.w500,
        color: LoginRevampColors.textMuted,
      );

  static TextStyle get button => GoogleFonts.dmSans(
      fontSize: 20,
        fontWeight: FontWeight.w700,
        color: LoginRevampColors.white,
      );

  static TextStyle get footerTitle => GoogleFonts.dmSans(
      fontSize: 17,
        fontWeight: FontWeight.w700,
        color: LoginRevampColors.heading,
      );

  static TextStyle get footerSubtitle => GoogleFonts.dmSans(
      fontSize: 14,
        fontWeight: FontWeight.w500,
        color: LoginRevampColors.textMuted,
      );
}
