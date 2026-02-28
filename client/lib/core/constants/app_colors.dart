import 'package:flutter/material.dart';

/// Premium dark-first color system for D'Offers.
/// All colors follow a tonal elevation model — no gradients, no shadows.
class AppColors {
  // ── Background layers ──────────────────────────────────────────────────────
  /// Deepest canvas — near‑black scaffold background
  static const Color background = Color(0xFF050508);
  /// Screen surface / section background
  static const Color surface = Color(0xFF090A0D);
  /// Cards, bottom sheets
  static const Color cardBackground = Color(0xFF111217);
  /// Modals, inputs, popovers
  static const Color elevated = Color(0xFF181A22);
  /// Active / pressed state
  static const Color highlight = Color(0xFF20232D);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F8);
  static const Color textSecondary = Color(0xFF9A9FB5);
  static const Color textMuted = Color(0xFF5D6273);

  // ── Accent ─────────────────────────────────────────────────────────────────
  /// Brand accent — #00FF84, used on key interactive elements and highlights
  static const Color accent = Color(0xFF00FF84);
  /// Dimmed accent for icon tints, inactive selected, and softer states
  static const Color accentDim = Color(0xFF00CC68);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = accent;
  static const Color warning = Color(0xFFE8A838);
  static const Color error = Color(0xFFFF5A5A);
  static const Color info = accentDim;

  // ── Borders / Dividers ─────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x0FFFFFFF);   // 6% white
  static const Color borderMid = Color(0x1AFFFFFF);      // 10% white

  // ── Utility ────────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Legacy aliases kept for compile compatibility ──────────────────────────
  // Remove usages gradually; these map to the nearest premium token.
  static const Color primary = accent;
  static const Color primaryDark = accentDim;
  static const Color primaryLight = accent;
  static const Color accentDark = accentDim;

  // kept for status chip colours that haven't been migrated yet
  static const Color green = success;
  static const Color orange = warning;
  static const Color red = error;
  static const Color blue = info; // neutral info, no saturated blue
  static const Color purple = accentDim;
  static const Color pink = accentDim;
  static const Color deepOrange = accentDim;

  // Grey aliases (for remaining legacy usages — prefer textMuted / borderSubtle)
  static const Color grey = Color(0xFF9A9FB5);
  static const Color grey100 = Color(0xFF15161C);
  static const Color grey200 = Color(0xFF1C1E25);
  static const Color grey300 = Color(0xFF252733);
  static const Color grey400 = Color(0xFF5D6273);
  static const Color grey600 = Color(0xFF8C909E);
  static const Color grey700 = Color(0xFFA4A8B6);
  static const Color grey800 = Color(0xFFCACDD8);
  static const Color black54 = Color(0x8A000000);
  static const Color black12 = Color(0x1F000000);

  // ── Light theme tokens — kept but unused (app is dark-only now) ─────────────
  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color lightCardBackground = cardBackground;
  static const Color lightTextPrimary = textPrimary;
  static const Color lightTextSecondary = textSecondary;
  static const Color lightTextHint = textMuted;

  // ── Gradient-style names kept as Color aliases for compile compat ────────────
  // (actual gradient objects removed — use flat colours)
  static const Color gradientIndigo = accentDim;
  static const Color gradientViolet = accentDim;
  static const Color gradientPink = accentDim;
  static const Color gradientCoral = highlight;

  // ── Background gradient kept for ThemeHelper.getBackgroundGradient ──────────
  // Returns a barely-visible tonal shift, not a saturated gradient.
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy gradient aliases (barely visible, tonal only)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cardBackground, highlight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [cardBackground, highlight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient lightBackgroundGradient = backgroundGradient;

  // ── Convenience getters ────────────────────────────────────────────────────
  static const Color textHint = textMuted;
}
