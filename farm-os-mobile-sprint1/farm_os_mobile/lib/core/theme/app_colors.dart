import 'package:flutter/material.dart';

/// Semantic color tokens from the approved Stage 2 design system.
/// Screens should reference these, not raw Color(...) values, so a palette
/// change is a one-file edit.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2E7D32); // agricultural green
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFFA5D6A7);

  static const Color secondary = Color(0xFF8D6E42); // earth brown/tan
  static const Color secondaryLight = Color(0xFFD7B98E);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // Surfaces (light mode)
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0EC);

  // Surfaces (dark mode)
  static const Color backgroundDark = Color(0xFF121410);
  static const Color surfaceDark = Color(0xFF1D2019);
  static const Color surfaceVariantDark = Color(0xFF2A2E24);

  // Text
  static const Color textPrimary = Color(0xFF1B1C18);
  static const Color textSecondary = Color(0xFF5C5F55);
  static const Color textPrimaryDark = Color(0xFFECEEE6);
  static const Color textSecondaryDark = Color(0xFFB8BBB0);
}
