import 'package:flutter/material.dart';

class AppPalette {
  // Primary Colors
  // Dark Gray / Near Black range (#121212 – #1C1C1E)
  static const Color backgroundDark = Color(0xFF121212);
  static const Color backgroundDarker = Color(0xFF1C1C1E);

  // Orange range (#FF6B00 – #FF7A1A)
  static const Color orange = Color(0xFFFF6B00);
  static const Color orangeBright = Color(0xFFFF7A1A);

  // Bright Green range (#4CD964 – #34C759)
  static const Color greenBright = Color(0xFF4CD964);
  static const Color green = Color(0xFF34C759);

  // Secondary / Accent Colors
  // Light Gray (#A0A0A0 – #C7C7CC)
  static const Color lightGray = Color(0xFFA0A0A0);
  static const Color lightGrayLight = Color(0xFFC7C7CC);

  // Medium Gray (#2C2C2E – #3A3A3C)
  static const Color mediumGray = Color(0xFF2C2C2E);
  static const Color mediumGrayLight = Color(0xFF3A3A3C);

  // White
  static const Color white = Color(0xFFFFFFFF);

  // Supporting Colors
  static const Color red = Color(0xFFFF3B30);
  static const Color yellow = Color(0xFFFFD60A);

  // Semantic aliases (optional convenience)
  static const Color screenBackground = backgroundDark;
  static const Color cardBackground = mediumGray;
  static const Color navBarBackground = mediumGray;
  static const Color placeholderText = lightGrayLight;
  static const Color primaryTextOnDark = white;
  static const Color ctaPrimary = orange;
  static const Color ctaPrimaryHover = orangeBright;
  static const Color safeIndicator = green;
  static const Color safeIndicatorBright = greenBright;
  static const Color border = mediumGrayLight;
}
