import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (Indigo Sky scale)
  static const Color primary = Color(0xFF2F3E8F);
  static const Color primaryDark = Color(0xFF242F70);
  static const Color primaryLight = Color(0xFF5566B8);

  // Accent colors
  static const Color accent = Color(0xFF5C7CFA);
  static const Color accentDark = Color(0xFF4767E8);

  // Professional dark surface system
  static const Color background = Color(0xFF0E1724);
  static const Color surface = Color(0xFF132033);
  static const Color cardBackground = Color(0xFF1A2B42);

  // Dark text (Bright Snow scale)
  static const Color textPrimary = Color(0xFFF0F2F5); // bright-snow-50
  static const Color textSecondary = Color(0xFFA3B3C2); // bright-snow-300
  static const Color textHint = Color(0xFF8599AD); // bright-snow-400

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFF59F0A);
  static const Color info = Color(0xFF2E6BB3);

  // Semantic neutral palette for screen-level usage
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black12 = Color(0x1F000000);
  static const Color transparent = Color(0x00000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color green = Color(0xFF4CAF50);
  static const Color green700 = Color(0xFF388E3C);
  static const Color orange = Color(0xFFFF9800);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color deepOrange = Color(0xFFE65100);
  static const Color red = Color(0xFFF44336);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color blue = Color(0xFF2196F3);

  // Semantic gradient stops used in screens
  static const Color gradientIndigo = Color(0xFF2F3E8F);
  static const Color gradientViolet = Color(0xFF4455A8);
  static const Color gradientPink = Color(0xFF5C6EC2);
  static const Color gradientCoral = Color(0xFF273676);

  // Subtle gradients
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

  // Light theme tokens (Indigo Sky)
  static const Color lightBackground = Color(0xFFF3F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF121A3A);
  static const Color lightTextSecondary = Color(0xFF3C4A7A);
  static const Color lightTextHint = Color(0xFF6A75A3);

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF3F5FF), Color(0xFFE8EDFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
