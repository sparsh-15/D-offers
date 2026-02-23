import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (Azure Blue scale)
  static const Color primary = Color(0xFF3C83F6); // azure-blue-400
  static const Color primaryDark = Color(0xFF0950C3); // azure-blue-600
  static const Color primaryLight = Color(0xFF6DA2F8); // azure-blue-300

  // Accent colors (Golden Orange scale)
  static const Color accent = Color(0xFFF7B23B); // golden-orange-400
  static const Color accentDark = Color(0xFFC47F08); // golden-orange-600

  // Single professional dark surface system (Jet Black scale)
  static const Color background = Color(0xFF0D1117); // jet-black-950
  static const Color surface = Color(0xFF121821); // jet-black-900
  static const Color cardBackground = Color(0xFF253141); // jet-black-800

  // Dark text (Bright Snow scale)
  static const Color textPrimary = Color(0xFFF0F2F5); // bright-snow-50
  static const Color textSecondary = Color(0xFFA3B3C2); // bright-snow-300
  static const Color textHint = Color(0xFF8599AD); // bright-snow-400

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFF59F0A); // golden-orange-500
  static const Color info = Color(0xFF0B64F4); // azure-blue-500

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
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color red = Color(0xFFF44336);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color blue = Color(0xFF2196F3);

  // Semantic gradient stops used in screens (kept low contrast)
  static const Color gradientIndigo = Color(0xFF073C92); // azure-blue-700
  static const Color gradientViolet = Color(0xFF374962); // jet-black-700
  static const Color gradientPink = Color(0xFF496183); // jet-black-600
  static const Color gradientCoral = Color(0xFF2F426A); // ink-black-700

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

  // Fallback light tokens (kept for compatibility with existing references)
  static const Color lightBackground = Color(0xFFF0F2F5); // bright-snow-50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF101623); // ink-black-900
  static const Color lightTextSecondary = Color(0xFF3D4C5C); // bright-snow-700
  static const Color lightTextHint = Color(0xFF667F99); // bright-snow-500

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: [Color(0xFFF0F2F5), Color(0xFFE0E6EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
