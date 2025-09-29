import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static final font = GoogleFonts.getFont('SF Pro Text');
  static TextStyle heading2 = TextStyle(
    fontFamily: font.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF546076),
    height: 19.81 / 16, 
    letterSpacing: 0.03, // Letter spacing in em units
    textBaseline: TextBaseline.alphabetic, // Ensures proper text alignment
    decoration: TextDecoration.none,
  );

  static TextStyle heading1 = TextStyle(
    fontFamily: font.fontFamily,
    fontSize: 16,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w800,
   
    color: Color(0xFF546076),
  );

  static TextStyle Yearfilters = TextStyle(
    fontFamily: font.fontFamily,
    fontSize: 16,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w600,
   height:19.6/16,
    color: Color(0xFF546076),
  );
//downloads
  static TextStyle body2 = TextStyle(
    fontSize: 20,
    fontFamily: font.fontFamily,
    fontWeight: FontWeight.w600,
    height:24.5/20,
    color: Color(0xFF546076),
  );
  //toggle button
  static TextStyle body1 = TextStyle(
    fontSize: 14,
    fontFamily: font.fontFamily,
    fontWeight: FontWeight.w600,
    height: 17.15/14,
    color: Color(0xFF546076),
  );
//label medium
  static TextStyle caption2 = TextStyle(
  fontSize: 16,
  fontFamily: font.fontFamily,
  fontWeight: FontWeight.w600,
  color: Color(0xFF546076),
  height: 19.6 / 16,  // Line height as ratio (line-height / font-size)
  letterSpacing: 0.03, // 0.03em for letter-spacing // Underline position
  decoration: TextDecoration.none,  // Ensure no underline is set by default
);

//for labelSmall
  static TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontFamily: font.fontFamily,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.03,
    height: 14.7/12,
    color: Color(0xFF546076),
  );
}