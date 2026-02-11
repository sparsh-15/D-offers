import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFFFA726); // Vibrant Orange
  static const Color primaryDark = Color(0xFFF57C00);
  static const Color primaryLight = Color(0xFFFFB74D);

  // Accent Colors
  static const Color accent = Color(0xFF26C6DA); // Cyan
  static const Color accentDark = Color(0xFF00ACC1);

  // Background Colors
  static const Color background = Color(0xFF0A0E21); // Dark Blue
  static const Color surface = Color(0xFF1D1E33);
  static const Color cardBackground = Color(0xFF262A41);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C1);
  static const Color textHint = Color(0xFF6C6F7F);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
