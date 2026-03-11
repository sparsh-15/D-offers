import 'package:flutter/material.dart';

/// Design tokens for MyOffers — 8-point base grid.
/// Use these constants instead of magic numbers throughout the codebase.
class AppTokens {
  // ── Spacing (8pt grid) ─────────────────────────────────────────────────────
  static const double spaceXS = 4;
  static const double spaceSM = 8;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;
  static const double space2XL = 48;
  static const double space3XL = 64;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 14;
  static const double radiusLG = 20;
  static const double radiusXL = 28;
  static const double radiusFull = 999;

  // ── Font sizes ─────────────────────────────────────────────────────────────
  static const double fontLabel = 11;
  static const double fontBodySM = 13;
  static const double fontBodyLG = 15;
  static const double fontTitleSM = 15;
  static const double fontTitleMD = 17;
  static const double fontTitleLG = 20;
  static const double fontDisplayLG = 28;
  static const double fontDisplayXL = 36;

  // ── Durations ──────────────────────────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 180);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ── Curves ─────────────────────────────────────────────────────────────────
  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;

  // ── Icon sizes ─────────────────────────────────────────────────────────────
  static const double iconSM = 16;
  static const double iconMD = 20;
  static const double iconLG = 24;
  static const double iconXL = 32;

  // ── Component heights ──────────────────────────────────────────────────────
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double bottomNavHeight = 64;
  static const double appBarHeight = 56;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(radiusLG);
  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(radiusMD);
  static BorderRadius get chipBorderRadius =>
      BorderRadius.circular(radiusFull);
  static BorderRadius get inputBorderRadius =>
      BorderRadius.circular(radiusMD);
  static BorderRadius get dialogBorderRadius =>
      BorderRadius.circular(radiusLG);
}
