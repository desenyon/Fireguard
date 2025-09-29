import 'package:fireguard/utils/constants/typography.dart';
import 'package:flutter/material.dart';
import '../../constants/palette.dart';

class TPopupMenuTheme {
  TPopupMenuTheme._();

  static final lightPopupMenuTheme = PopupMenuThemeData(
    color: AppPalette.screenBackground,
    elevation: 8,
    shadowColor: Color(0x24001A5A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(
        color: AppPalette.border,
        width: 1,
      ),
    ),
    textStyle: AppTypography.body1,
    
  );

  static final darkPopupMenuTheme = PopupMenuThemeData(
    // Add dark theme properties if needed
  );
}