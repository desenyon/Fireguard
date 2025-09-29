import 'package:flutter/material.dart';
import 'custom_themes/text_theme.dart';
import 'custom_themes/elevated_button_theme.dart';
import 'custom_themes/appbar_theme.dart';
import 'custom_themes/textfield_theme.dart';
import 'custom_themes/popmenu_theme.dart';
import 'custom_themes/dialog_theme.dart';
import "custom_themes/dropdown_theme.dart";

class TTheme {
  TTheme._();

  static ThemeData lightTheme = ThemeData(
    dropdownMenuTheme: TDropdownTheme.lightdropdownTheme,
    fontFamily: 'Gilroy',
    brightness: Brightness.light,
    primaryColor: Color(0xFF4385F5),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TTextTheme.lightTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    inputDecorationTheme: TTextFieldTheme.lightTextFieldTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    useMaterial3: true,
    dialogTheme: TDialogTheme.lightDialogTheme,
    popupMenuTheme: TPopupMenuTheme.lightPopupMenuTheme,
  );

  static ThemeData darkTheme = ThemeData(
    dropdownMenuTheme: TDropdownTheme.lightdropdownTheme,
    fontFamily: 'Gilroy',
    brightness: Brightness.light,
    primaryColor: Color(0xFF4385F5),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TTextTheme.lightTheme,
    appBarTheme: TAppBarTheme.lightAppBarTheme,
    inputDecorationTheme: TTextFieldTheme.lightTextFieldTheme,
    elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
    useMaterial3: true,
    dialogTheme: TDialogTheme.lightDialogTheme,
    popupMenuTheme: TPopupMenuTheme.lightPopupMenuTheme,
  );
}