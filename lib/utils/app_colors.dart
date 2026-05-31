import 'package:flutter/material.dart';

class AppColors {
  // Modern Gradient Brand Colors
  static const Color primary = Color(0xFFE21C34); // Vibrant Red
  static const Color primaryDark = Color(0xFF500B28); // Deep Burgundy
  static const Color primaryLight = Color(0xFFFF4757); // Light Red

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE21C34), Color(0xFF500B28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientReverse = LinearGradient(
    colors: [Color(0xFF500B28), Color(0xFFE21C34)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textMedium = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFEEEEEE);

  // Functional Colors
  static const Color error = Color(0xFFE21C34);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color accent = Color(0xFFE21C34);

  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.05);
  static Color shadowMedium = Colors.black.withOpacity(0.1);
  static Color primaryShadow = const Color(0xFFE21C34).withOpacity(0.3);
}

/// Formats a number as money — always shows whole number, no decimals.
/// 450.00 → "450" | 450.75 → "450" | 2243.23 → "2243"
String formatMoney(num value) {
  return value.truncate().toString();
}
