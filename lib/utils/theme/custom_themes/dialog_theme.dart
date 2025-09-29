import 'package:flutter/material.dart';

import '../../constants/palette.dart'; 

class TDialogTheme {
  TDialogTheme._();

  static DialogThemeData lightDialogTheme = DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    backgroundColor: Colors.white,
  );

  static DialogThemeData darkDialogTheme = DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    backgroundColor: Colors.grey[900],
  );

  static BoxDecoration boxDecoration = BoxDecoration(
    color: AppPalette.screenBackground,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        offset: Offset(0, 0),
        blurRadius: 5,
        spreadRadius: 0,
      ),
    ],
  );

  static EdgeInsetsGeometry contentPadding = EdgeInsets.all(16);
}