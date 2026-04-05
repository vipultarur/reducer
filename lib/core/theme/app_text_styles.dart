import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography system using Google Fonts "Inter"
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double letterSpacing = 0,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  // ── Display ───────────────────────────────────────────────────────────────────
  static TextStyle displayLarge(BuildContext context) => _inter(57, weight: FontWeight.w700, letterSpacing: -1.5, height: 1.12);
  static TextStyle displayMedium(BuildContext context) => _inter(45, weight: FontWeight.w700, letterSpacing: -1, height: 1.15);
  static TextStyle displaySmall(BuildContext context) => _inter(36, weight: FontWeight.w700, letterSpacing: -0.5, height: 1.2);

  // ── Headline ──────────────────────────────────────────────────────────────────
  static TextStyle headlineLarge(BuildContext context) => _inter(32, weight: FontWeight.w700, letterSpacing: -0.3, height: 1.25);
  static TextStyle headlineMedium(BuildContext context) => _inter(28, weight: FontWeight.w700, letterSpacing: -0.2, height: 1.28);
  static TextStyle headlineSmall(BuildContext context) => _inter(24, weight: FontWeight.w600, height: 1.3);

  // ── Title ─────────────────────────────────────────────────────────────────────
  static TextStyle titleLarge(BuildContext context) => _inter(22, weight: FontWeight.w600, height: 1.3);
  static TextStyle titleMedium(BuildContext context) => _inter(16, weight: FontWeight.w600, letterSpacing: 0.1, height: 1.4);
  static TextStyle titleSmall(BuildContext context) => _inter(14, weight: FontWeight.w600, letterSpacing: 0.1, height: 1.4);

  // ── Body ──────────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge(BuildContext context) => _inter(16, weight: FontWeight.w400, height: 1.5);
  static TextStyle bodyMedium(BuildContext context) => _inter(14, weight: FontWeight.w400, height: 1.5);
  static TextStyle bodySmall(BuildContext context) => _inter(12, weight: FontWeight.w400, height: 1.5);

  // ── Label ─────────────────────────────────────────────────────────────────────
  static TextStyle labelLarge(BuildContext context) => _inter(14, weight: FontWeight.w500, letterSpacing: 0.1);
  static TextStyle labelMedium(BuildContext context) => _inter(12, weight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle labelSmall(BuildContext context) => _inter(11, weight: FontWeight.w500, letterSpacing: 0.5);

  // ── Specialized ───────────────────────────────────────────────────────────────
  static TextStyle statValue(BuildContext context) => _inter(24, weight: FontWeight.w800, height: 1.1);
  static TextStyle statLabel(BuildContext context) => _inter(11, weight: FontWeight.w500, letterSpacing: 0.5);
  static TextStyle buttonText(BuildContext context) => _inter(15, weight: FontWeight.w600, letterSpacing: 0.3);
  static TextStyle tabLabel(BuildContext context) => _inter(12, weight: FontWeight.w600, letterSpacing: 0.2);
  static TextStyle chipLabel(BuildContext context) => _inter(12, weight: FontWeight.w500);
  static TextStyle badgeLabel(BuildContext context) => _inter(10, weight: FontWeight.w700, letterSpacing: 0.5);
}
