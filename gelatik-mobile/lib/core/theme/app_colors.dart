import 'package:flutter/material.dart';

/// Shared visual tokens for Gelatik Mobile.
///
/// Navy carries structure and navigation, gold is reserved for emphasis, and
/// teal identifies helpful/service states.  Keeping those roles stable makes
/// every feature feel like one product rather than a collection of screens.
class AppColors {
  AppColors._();

  // Canonical DESIGN.md tokens. Compatibility aliases below intentionally
  // remain available while feature modules migrate to these names.
  static const Color colorPrimary = Color(0xFF1E3A8A);
  static const Color colorPrimaryDark = Color(0xFF152A63);
  static const Color colorAccent = Color(0xFFF59E0B);
  static const Color colorSecondary = Color(0xFF0F766E);
  static const Color colorSecondaryBright = Color(0xFF2DD4BF);
  static const Color colorBackground = Color(0xFFFFFFFF);
  static const Color colorSurface = Color(0xFFFFFFFF);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorTextPrimary = Color(0xFF111827);
  static const Color colorTextMuted = Color(0x99111827);
  static const Color colorSuccess = Color(0xFF16A34A);
  static const Color colorWarning = colorAccent;
  static const Color colorError = Color(0xFFDC2626);
  static const Color colorInfo = colorPrimary;

  // ---------------------------------------------------------------------------
  // Design Tokens Resmi (BAGIAN 0)
  // ---------------------------------------------------------------------------
  /// Legacy teal aliases are intentionally kept while feature screens migrate.
  static const Color primaryTealLight = colorSecondary;
  static const Color primaryTealDark = primaryTealLight;

  /// Primary actions are navy; emerald is retained for success-only actions.
  static const Color actionEmeraldLight = colorPrimary;
  static const Color actionEmeraldDark = actionEmeraldLight;

  /// accentNavy: aksen ikon/dekorasi (motif Siger)
  static const Color accentNavyLight = colorPrimary;
  static const Color accentNavyDark = accentNavyLight;

  /// accentGold: aksen ikon/dekorasi
  static const Color accentGoldLight = colorAccent;
  static const Color accentGoldDark = accentGoldLight;

  /// cardStroke: border 1.5px pengganti shadow (Neo-Brutalism Teal)
  static const Color cardStrokeLight = colorBorder;
  static const Color cardStrokeDark = cardStrokeLight;

  // ---------------------------------------------------------------------------
  // Helper Getters Berdasarkan BuildContext / Brightness
  // ---------------------------------------------------------------------------
  static Color primaryTeal(BuildContext context) => primaryLight;

  static Color actionEmerald(BuildContext context) => actionEmeraldLight;

  static Color accentNavy(BuildContext context) => accentNavyLight;

  static Color accentGold(BuildContext context) => accentGoldLight;

  static Color cardStroke(BuildContext context) => cardStrokeLight;

  static Color mutedText(BuildContext context) => colorTextMuted;

  // ---------------------------------------------------------------------------
  // Light Mode Colors (Theme Mapping)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = accentNavyLight;
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFEAF0FF);
  static const Color onPrimaryContainerLight = accentNavyLight;

  static const Color onAccentGoldLight = Color(0xFF1F2937);

  static const Color backgroundLight = colorBackground;
  static const Color onBackgroundLight = colorTextPrimary;

  static const Color surfaceLight = colorSurface;
  static const Color onSurfaceLight = colorTextPrimary;

  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color outlineLight = colorBorder;

  // Status Colors (Light)
  static const Color statusSuccessLight = colorSuccess;
  static const Color statusWarningLight = colorWarning;
  static const Color statusErrorLight = colorError;
  static const Color statusInfoLight = colorInfo;

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
