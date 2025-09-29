import 'package:flutter/material.dart';
import "../../constants/typography.dart";
class TAppBarTheme {
  TAppBarTheme._();

  static AppBarTheme lightAppBarTheme = AppBarTheme(
    backgroundColor: Colors.white, 
    shadowColor: Color(0x29999999), // 29% opacity to match box-shadow
    elevation: 0,
    scrolledUnderElevation: 0,
    
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
    
    foregroundColor: Colors.white,
   
    titleTextStyle:  AppTypography.heading1, 
  );
  static AppBarTheme darkAppBarTheme = AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  );
}