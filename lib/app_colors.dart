import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════
//  Zteeel Vendor — "Fresh Coral" Light Palette (v2.1 — font colors fixed)
//
//  WHAT CHANGED FROM v2: only textSecondary, textMuted, and iconGrey
//  were darkened. Everything else (backgrounds, orange, gold, green,
//  red, borders, splash/warm surfaces) is untouched.
//
//  WHY: textMuted (#A8A39D) and iconGrey (#CCCCCC) were too pale
//  against white/light surfaces — under ~2.5:1 contrast, which reads
//  as "barely visible" rather than intentionally subtle. Darkened
//  both so they're clearly readable while still lower-emphasis than
//  textPrimary/textSecondary.
// ════════════════════════════════════════════════════════════════════

abstract final class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────
  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF7F5F3);
  static const Color surfaceElevated = Color(0xFFFCE9E6);

  // ── Brand / Accent — Coral Red ───────────────────────────────────────
  static const Color orange = Color(0xFFEF5A4C);
  static const Color orangeLight = Color(0xFFF57A6E);
  static const Color orangeDim = Color(0x1AEF5A4C);
  static const Color orangeBorder = Color(0x40EF5A4C);
  static const Color orangeTint = Color(0xFFFDECEA);

  /// Warm orange used in the splash/onboarding animation
  static const Color orangeWarm = Color(0xFFE87722);

  // ── Gold (premium / featured badges) ────────────────────────────────
  static const Color gold = Color(0xFFC4922E);

  // ── Semantic: Success / Open ────────────────────────────────────────
  static const Color green = Color(0xFF1D9E6B);
  static const Color greenDim = Color(0x1A1D9E6B);
  static const Color greenBorder = Color(0x401D9E6B);

  // ── Semantic: Danger / Error ────────────────────────────────────────
  static const Color red = Color(0xFFD32F3F);

  // ── Text — for use on light surfaces (bg/surface/surfaceRaised) ─────
  /// Headings, primary body text. Always the darkest text color —
  /// use this for headings, never textWhite/textInverse.
  static const Color textPrimary = Color(0xFF1C1B1A);

  /// Supporting text — labels, descriptions, secondary lines.
  /// Darkened from #6B6764 → better contrast against white/raised surfaces.
  static const Color textSecondary = Color(0xFF5C5751);

  /// Low-emphasis text — placeholders, timestamps, hints.
  /// Darkened from #A8A39D → old value was near-invisible on white.
  static const Color textMuted = Color(0xFF8C8680);

  // ── Text — for use on dark / saturated backgrounds ───────────────────
  /// Text on solid accent fills (orange/red buttons, filled badges)
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// Text on any dark surface (dark chips, image overlays, tooltips) —
  /// this replaces the old "textWhite" role so its purpose is explicit
  static const Color textInverse = Color(0xFFFFFFFF);

  /// @deprecated Kept only so old references still compile while you
  /// migrate call sites. Do NOT use for headings — that was the bug.
  /// Replace usages with textPrimary (headings/body) or textOnAccent
  /// (text on buttons), then delete this.
  static const Color textWhite = textInverse;

  // ── Borders / Dividers ─────────────────────────────────────────────
  static const Color border = Color(0xFFECEAE7);
  static const Color borderAccent = Color(0xFFEF5A4C);

  // ── Navigation Bar ─────────────────────────────────────────────────
  static const Color navBg = Color(0xFFFFFFFF);

  // ── Misc ───────────────────────────────────────────────────────────
  static const Color separator = Color(0x0F000000);
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;

  /// Deep dark background used in the splash screen animation
  static const Color bgSplash = Color(0xFF1A0E05);

  /// Surface raised for orderScreen warm-dark card
  static const Color surfaceWarm = Color(0xFF3D1F10);

  /// Neutral icon / placeholder grey.
  /// Darkened from #CCCCCC → old value was nearly invisible on white.
  static const Color iconGrey = Color(0xFF9C9791);
}
