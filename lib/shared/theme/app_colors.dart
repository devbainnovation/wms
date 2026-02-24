import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryTeal = Color(0xFF1ABC9C); // Main teal
  static const Color darkTeal = Color(0xFF16A085);
  static const Color lightTeal = Color(0xFFB2E5DE);

  // Secondary Colors
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color lightGreen = Color(0xFFA9DFBF);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF0F4F8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBlue = Color(0xFFE3F2FD);

  // Text Colors
  static const Color darkText = Color(0xFF2C3E50);
  static const Color greyText = Color(0xFF95A5A6);
  static const Color lightGreyText = Color(0xFFBDC3C7);

  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Additional Colors
  static const Color orange = Color(0xFFE67E22);
  static const Color red = Color(0xFFE74C3C);
  static const Color blue = Color(0xFF3498DB);
  static const Color shadow = Color(0x1A000000);

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
