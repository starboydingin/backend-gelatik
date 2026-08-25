import 'package:flutter/material.dart';

/// Shared visual tokens for Gelatik Mobile.
///
/// Navy carries structure and navigation, gold is reserved for emphasis, and
/// teal identifies helpful/service states.  Keeping those roles stable makes
/// every feature feel like one product rather than a collection of screens.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Design Tokens Resmi (BAGIAN 0)
  // ---------------------------------------------------------------------------
  /// Legacy teal aliases are intentionally kept while feature screens migrate.
  static const Color primaryTealLight = Color(0xFF0F766E);
  static const Color primaryTealDark = primaryTealLight;

  /// Primary actions are navy; emerald is retained for success-only actions.
  static const Color actionEmeraldLight = Color(0xFF1E3A8A);
  static const Color actionEmeraldDark = actionEmeraldLight;

  /// accentNavy: aksen ikon/dekorasi (motif Siger)
  static const Color accentNavyLight = Color(0xFF1E3A8A);
  static const Color accentNavyDark = accentNavyLight;

  /// accentGold: aksen ikon/dekorasi
  static const Color accentGoldLight = Color(0xFFF59E0B);
  static const Color accentGoldDark = accentGoldLight;

  /// cardStroke: border 1.5px pengganti shadow (Neo-Brutalism Teal)
  static const Color cardStrokeLight = Color(0xFFD9E2F0);
  static const Color cardStrokeDark = cardStrokeLight;

  // ---------------------------------------------------------------------------
  // Helper Getters Berdasarkan BuildContext / Brightness
  // ---------------------------------------------------------------------------
  static Color primaryTeal(BuildContext context) =>
      primaryLight;

  static Color actionEmerald(BuildContext context) =>
      actionEmeraldLight;

  static Color accentNavy(BuildContext context) =>
      accentNavyLight;

  static Color accentGold(BuildContext context) =>
      accentGoldLight;

  static Color cardStroke(BuildContext context) =>
      cardStrokeLight;

  static Color mutedText(BuildContext context) =>
      const Color(0xFF64748B);

  // ---------------------------------------------------------------------------
  // Light Mode Colors (Theme Mapping)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = accentNavyLight;
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFEAF0FF);
  static const Color onPrimaryContainerLight = accentNavyLight;

  static const Color onAccentGoldLight = Color(0xFF1F2937);

  static const Color backgroundLight = Color(0xFFF6F8FC);
  static const Color onBackgroundLight = Color(0xFF0F172A);

  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color onSurfaceLight = Color(0xFF1E293B);

  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color outlineLight = Color(0xFFD9E2F0);

  // Status Colors (Light)
  static const Color statusSuccessLight = Color(0xFF10B981);
  static const Color statusWarningLight = Color(0xFFF59E0B);
  static const Color statusErrorLight = Color(0xFFDC2626);
  static const Color statusInfoLight = Color(0xFF0284C7);

  // Compatibility mappings. The product currently uses one intentional light
  // visual system, so old dark-mode consumers resolve to accessible light data.
  static const Color primaryDark = primaryLight;
  static const Color onPrimaryDark = onPrimaryLight;
  static const Color primaryContainerDark = primaryContainerLight;
  static const Color onPrimaryContainerDark = onPrimaryContainerLight;

  static const Color onAccentGoldDark = Color(0xFF1F2937);

  static const Color backgroundDark = backgroundLight;
  static const Color onBackgroundDark = onBackgroundLight;

  static const Color surfaceDark = surfaceLight;
  static const Color onSurfaceDark = onSurfaceLight;

  static const Color surfaceVariantDark = surfaceVariantLight;
  static const Color outlineDark = outlineLight;

  // Status Colors (Dark)
  static const Color statusSuccessDark = statusSuccessLight;
  static const Color statusWarningDark = statusWarningLight;
  static const Color statusErrorDark = statusErrorLight;
  static const Color statusInfoDark = statusInfoLight;
}
