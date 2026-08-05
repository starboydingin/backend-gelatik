import 'package:flutter/material.dart';

/// AppColors — Design Tokens Gelatik Mobile (Teal, Emerald, Navy, Gold)
/// Sumber Tunggal Warna Resmi Aplikasi.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Design Tokens Resmi (BAGIAN 0)
  // ---------------------------------------------------------------------------
  /// primaryTeal: dipakai untuk wordmark, teks aksen, border fokus
  static const Color primaryTealLight = Color(0xFF0F766E);
  static const Color primaryTealDark = Color(0xFF2DD4BF);

  /// actionEmerald: KHUSUS untuk tombol aksi utama (Masuk, Daftar Sekarang)
  static const Color actionEmeraldLight = Color(0xFF10B981);
  static const Color actionEmeraldDark = Color(0xFF34D399);

  /// accentNavy: aksen ikon/dekorasi (motif Siger)
  static const Color accentNavyLight = Color(0xFF1E3A8A);
  static const Color accentNavyDark = Color(0xFF3B82F6);

  /// accentGold: aksen ikon/dekorasi
  static const Color accentGoldLight = Color(0xFFF59E0B);
  static const Color accentGoldDark = Color(0xFFFBBF24);

  /// cardStroke: border 1.5px pengganti shadow (Neo-Brutalism Teal)
  static const Color cardStrokeLight = Color(0xFFE2E8F0);
  static const Color cardStrokeDark = Color(0xFF334155);

  // ---------------------------------------------------------------------------
  // Helper Getters Berdasarkan BuildContext / Brightness
  // ---------------------------------------------------------------------------
  static Color primaryTeal(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? primaryTealDark
          : primaryTealLight;

  static Color actionEmerald(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? actionEmeraldDark
          : actionEmeraldLight;

  static Color accentNavy(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentNavyDark
          : accentNavyLight;

  static Color accentGold(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? accentGoldDark
          : accentGoldLight;

  static Color cardStroke(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? cardStrokeDark
          : cardStrokeLight;

  static Color mutedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF64748B);

  // ---------------------------------------------------------------------------
  // Light Mode Colors (Theme Mapping)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = primaryTealLight; // Teal
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFCCFBF1); // Teal-100
  static const Color onPrimaryContainerLight = Color(0xFF0F766E);

  static const Color onAccentGoldLight = Color(0xFF1F2937);

  static const Color backgroundLight = Color(0xFFF8FAFC); // Off-White
  static const Color onBackgroundLight = Color(0xFF0F172A);

  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color onSurfaceLight = Color(0xFF1E293B);

  static const Color surfaceVariantLight = Color(0xFFEEF2F6);
  static const Color outlineLight = Color(0xFFCBD5E1);

  // Status Colors (Light)
  static const Color statusSuccessLight = Color(0xFF16A34A);
  static const Color statusWarningLight = Color(0xFFF59E0B);
  static const Color statusErrorLight = Color(0xFFDC2626);
  static const Color statusInfoLight = Color(0xFF0284C7);

  // ---------------------------------------------------------------------------
  // Dark Mode Colors (Theme Mapping)
  // ---------------------------------------------------------------------------
  static const Color primaryDark = primaryTealDark; // Teal-400
  static const Color onPrimaryDark = Color(0xFF0F766E);
  static const Color primaryContainerDark = Color(0xFF134E4A); // Teal-900
  static const Color onPrimaryContainerDark = Color(0xFFCCFBF1);

  static const Color onAccentGoldDark = Color(0xFF1F2937);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color onBackgroundDark = Color(0xFFF1F5F9);

  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color onSurfaceDark = Color(0xFFE2E8F0);

  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color outlineDark = Color(0xFF475569);

  // Status Colors (Dark)
  static const Color statusSuccessDark = Color(0xFF4ADE80);
  static const Color statusWarningDark = Color(0xFFFBBF24);
  static const Color statusErrorDark = Color(0xFFF87171);
  static const Color statusInfoDark = Color(0xFF38BDF8);
}
