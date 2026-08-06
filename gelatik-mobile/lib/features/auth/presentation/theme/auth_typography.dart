import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scoped to authentication screens.
///
/// Montserrat is provided through the existing Google Fonts dependency. Its
/// geometric proportions complement the GELATIK wordmark; the logo asset
/// remains the authoritative rendering of the brand name.
class AuthTypography {
  AuthTypography._();

  static TextStyle brandTitle(BuildContext context, {double fontSize = 16}) {
    return GoogleFonts.montserrat(
      textStyle: Theme.of(context).textTheme.titleMedium,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );
  }

  static TextStyle screenHeading(BuildContext context, Color color) {
    return GoogleFonts.montserrat(
      textStyle: Theme.of(context).textTheme.headlineMedium,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.2,
    );
  }

  static TextStyle subtitle(BuildContext context, Color color) {
    return GoogleFonts.montserrat(
      textStyle: Theme.of(context).textTheme.bodyMedium,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle fieldLabel(BuildContext context, Color color) {
    return GoogleFonts.montserrat(
      textStyle: Theme.of(context).textTheme.labelMedium,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle buttonText(BuildContext context, Color color) {
    return GoogleFonts.montserrat(
      textStyle: Theme.of(context).textTheme.labelLarge,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle validationText(BuildContext context, Color color) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(color: color);
  }
}
