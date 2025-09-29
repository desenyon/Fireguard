import 'package:flutter/material.dart';
import '../../constants/typography.dart';
class TTextTheme {
  TTextTheme._();

  static TextTheme lightTheme = TextTheme(
     displayLarge: AppTypography.heading2,    // Heading 2
        displayMedium: AppTypography.heading1,   // Heading 1
        bodyLarge: AppTypography.body2,         // Body 2
        bodyMedium: AppTypography.body1,        // Body 1
        labelMedium: AppTypography.caption2,    // Caption 2
        labelSmall: AppTypography.caption1, 
        titleLarge: AppTypography.Yearfilters,   
  );
  static TextTheme darkTheme = TextTheme();
}