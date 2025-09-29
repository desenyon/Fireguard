import 'package:flutter/material.dart';

class AppTypography {
  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Gilroy',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF546076),
    height: 19.81 / 16, 
    letterSpacing: 0.03, // Letter spacing in em units
    textBaseline: TextBaseline.alphabetic, // Ensures proper text alignment
    decoration: TextDecoration.none,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Gilroy',
    fontSize: 16,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w800,
   
    color: Color(0xFF546076),
  );

  static const TextStyle Yearfilters = TextStyle(
    fontFamily: 'Gilroy',
    fontSize: 16,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w600,
   height:19.6/16,
    color: Color(0xFF546076),
  );
//downloads
  static const TextStyle body2 = TextStyle(
    fontSize: 20,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w600,
    height:24.5/20,
    color: Color(0xFF546076),
  );
  //toggle button
  static const TextStyle body1 = TextStyle(
    fontSize: 14,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w600,
    height: 17.15/14,
    color: Color(0xFF546076),
  );
//label medium
  static const TextStyle caption2 = TextStyle(
  fontSize: 16,
  fontFamily: 'Gilroy',
  fontWeight: FontWeight.w600,
  color: Color(0xFF546076),
  height: 19.6 / 16,  // Line height as ratio (line-height / font-size)
  letterSpacing: 0.03, // 0.03em for letter-spacing // Underline position
  decoration: TextDecoration.none,  // Ensure no underline is set by default
);

//for labelSmall
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w600,
    letterSpacing: 0.03,
    height: 14.7/12,
    color: Color(0xFF546076),
  );
}