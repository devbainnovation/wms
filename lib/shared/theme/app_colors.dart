import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (emerald-led palette inspired by provided reference UI)
  static const Color primaryTeal = Color(0xFF0FA779);
  static const Color darkTeal = Color(0xFF0A7A58);
  static const Color lightTeal = Color(0xFFD8F3EA);

  // Secondary Colors
  static const Color accentGreen = Color(0xFF16A34A);
  static const Color lightGreen = Color(0xFFE8F7EF);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF5F7F6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBlue = Color(0xFFF1F5F3);

  // Text Colors
  static const Color darkText = Color(0xFF111827);
  static const Color greyText = Color(0xFF6B7280);
  static const Color lightGreyText = Color(0xFFD1D5DB);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Additional Colors
  static const Color orange = Color(0xFFEA580C);
  static const Color red = Color(0xFFDC2626);
  static const Color blue = Color(0xFF0284C7);
  static const Color shadow = Color(0x14000000);

  // Backwards-compatible aliases (older naming used across UI files)
  static const Color primaryColor = primaryTeal;
  static const Color backgroundColor = lightBackground;
  static const Color textDark = darkText;
  static const Color textLight = greyText;
  static const Color greenSecondary = accentGreen;
  static const Color redColor = red;
  static const Color infoColor = info;
  static const Color warningColor = warning;
  static const Color borderColor = lightGreyText;
}
